import AppKit

@main
struct AgentChecks {
    @MainActor static func main() throws {
        let arguments = Array(CommandLine.arguments.dropFirst())
        if arguments.first == "--fixture-server", arguments.count == 3 {
            let suite = arguments[1], channel = arguments[2]
            if let ownID = Bundle.main.bundleIdentifier {
                // The bundled fixture must use standard preferences for its own domain.
                _ = AgentPreferences.open(identifier: ownID).object(forKey: "fixture-missing-key")
            }
            let defaults = UserDefaults(suiteName: suite)!
            let schedules = ScheduleController(defaults: defaults)
            schedules.onEvent = { _ in true } // Fixture callback only; no power-management code is linked.
            let service = AgentService(schedules: schedules)
            var awake = false
            var invocations = 0
            service.getAwake = { awake }
            service.setAwake = { awake = $0; return true }
            service.wake = { done in done(0); return true }
            service.dim = { done in
                awake = false
                Task {
                    try? await Task.sleep(for: .milliseconds(500))
                    done(7)
                }
                return true
            }
            let connection = AgentConnection(channel: channel) { operation, completion in
                invocations += 1
                let invocation = invocations
                service.handle(operation) { reply in
                    var reply = reply
                    reply.message += " fixture-call-\(invocation)"
                    completion(reply)
                }
            }
            connection.start()
            schedules.start()
            let app = NSApplication.shared
            app.setActivationPolicy(.prohibited)
            withExtendedLifetime(connection) { app.run() }
            return
        }

        var checks = 0
        func expect(_ condition: Bool, _ message: String) {
            guard condition else { fatalError(message) }
            checks += 1
        }
        for value in [
            ["awake", "on"], ["awake", "off"], ["schedule", "show"], ["schedule", "off"], ["schedule", "cancel"],
            ["schedule", "daily", "09:00", "18:00"], ["schedule", "daily", "20:00", "08:00", "--no-keep-awake"],
            ["schedule", "daily", "off", "23:00"], ["schedule", "daily", "07:30", "off"],
            ["schedule", "timer", "1", "dim"], ["schedule", "timer", "1440", "wake"]
        ] { expect(AgentOperation.parse(value) != nil, "Valid command: \(value)") }
        for value in [
            [], ["awake"], ["awake", "maybe"], ["schedule"], ["schedule", "show", "extra"],
            ["schedule", "daily", "09:00", "09:00"], ["schedule", "daily", "off", "off"],
            ["schedule", "daily", "24:00", "18:00"], ["schedule", "daily", "09:60", "18:00"],
            ["schedule", "daily", "-1:00", "18:00"], ["schedule", "daily", "09:00:00", "18:00"],
            ["schedule", "daily", "09:00", "18:00", "--unknown"], ["schedule", "timer", "0", "dim"],
            ["schedule", "timer", "1441", "wake"], ["schedule", "timer", "1.5", "dim"], ["schedule", "timer", "30", "sleep"]
        ] { expect(AgentOperation.parse(value) == nil, "Reject invalid command without effects: \(value)") }
        let source = "/tmp/A person's 螢幕.app/Contents/MacOS/ScreenAwake"
        let command = AgentGuide.quote(source)
        let shell = Process()
        shell.executableURL = URL(fileURLWithPath: "/bin/sh")
        shell.arguments = ["-c", "printf '%s' " + command]
        let pipe = Pipe(); shell.standardOutput = pipe
        try shell.run()
        let quoted = pipe.fileHandleForReading.readDataToEndOfFile()
        shell.waitUntilExit()
        expect(String(data: quoted, encoding: .utf8) == source, "Copied command safely handles spaces, quotes and Unicode")
        for language in [AppLanguage.english, .traditionalChinese] {
            let prompt = AgentGuide.invitation(language: language, executable: source)
            expect(prompt.contains(command + " agent-help"), "Copy-to-AI includes the exact read-only local guide")
        }

        let suite = "ScreenAwake.AgentChecks.\(UUID().uuidString)"
        let channel = "ScreenAwake.AgentChecks.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        var offline = ScheduleSettings()
        offline.daily.enabled = true
        offline.countdown = CountdownSchedule(deadline: Date().addingTimeInterval(1800), action: .dim)
        expect(AgentOffline.apply(.dailyOff, settings: &offline) && !offline.daily.enabled && offline.countdown != nil, "Stopped-app daily cancellation preserves countdown")
        expect(AgentOffline.apply(.cancelTimer, settings: &offline) && offline.countdown == nil, "Stopped-app countdown cancellation")
        expect(!AgentOffline.apply(.awake(true), settings: &offline), "New keep-awake needs an app owner")
        expect(!AgentOffline.apply(.timer(30, .dim), settings: &offline), "New countdown needs a running timer")
        expect(AgentOffline.store(offline, defaults: defaults) && ScheduleController.loadSettings(defaults: defaults) == offline, "Offline cancellation is persisted through private preferences")
        for language in [AppLanguage.english, .traditionalChinese] {
            let panel = AwakePanelView()
            panel.update(enabled: false, language: language, error: nil)
            var copied = 0
            panel.onCopyAI = { copied += 1 }
            panel.copyAIButton.performClick(nil)
            expect(copied == 1, "Native Copy-to-AI button dispatches once")
            panel.confirmAICopied()
            expect(panel.copyAIButton.title == AppText(language: language).aiCopied, "Copy confirmation is localized")
        }
        let schedules = ScheduleController(defaults: defaults)
        let service = AgentService(schedules: schedules)
        var reply: AgentReply?
        service.handle(.daily(DailySchedule(enabled: true, wakeEnabled: false, dimEnabled: false))) { reply = $0 }
        expect(reply?.success == false && !schedules.settings.daily.enabled, "Wire requests are validated by the controller too")
        service.setAwake = { _ in false }
        service.handle(.awake(true)) { reply = $0 }
        expect(reply?.success == false, "Assertion failure is reported")
        var held = false
        service.getAwake = { held }
        service.setAwake = { held = $0; return true }
        service.wake = { done in done(8); return true }
        service.handle(.awake(true)) { reply = $0 }
        expect(reply?.success == false && reply?.state?.keepAwake == true, "Wake failure reports the remaining hold accurately")
        service.wake = { done in done(0); return true }
        service.handle(.awake(true)) { reply = $0 }
        expect(reply?.success == true && reply?.message.contains("wake requested") == true, "Keep-awake also requests an explicit wake")
        service.dim = { _ in false }
        service.handle(.dim) { reply = $0 }
        expect(reply?.success == false, "Busy controls are not reported as success")
        schedules.stop()

        // A different process exercises the actual DistributedNotification request/ack channel.
        let server = Process()
        server.executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
        server.arguments = ["--fixture-server", suite, channel]
        try server.run()
        defer { if server.isRunning { server.terminate(); server.waitUntilExit() } }
        let state = AgentConnection.send(.show, targetPID: server.processIdentifier, channel: channel, timeout: 5)
        expect(state.success && state.state?.appRunning == true, "A separate process acknowledges state")
        expect(state.state?.settings.daily.enabled == false, "The fixture starts with schedules off")
        let on = AgentConnection.send(.awake(true), targetPID: server.processIdentifier, channel: channel)
        expect(on.success && on.state?.keepAwake == true, "Keep-awake acknowledgement matches owner state")
        let daily = AgentOperation.parse(["schedule", "daily", "20:00", "08:00"])!
        let dailyReply = AgentConnection.send(daily, targetPID: server.processIdentifier, channel: channel)
        expect(dailyReply.success && dailyReply.state?.settings.daily.wake.hour == 20 && dailyReply.state?.settings.daily.dim.hour == 8, "Overnight daily schedule is saved and returned")
        expect(dailyReply.state?.nextDate != nil, "Next action is returned")
        let id = UUID()
        let timer = AgentConnection.send(.timer(30, .dim), targetPID: server.processIdentifier, channel: channel, id: id)
        let duplicate = AgentConnection.send(.timer(30, .dim), targetPID: server.processIdentifier, channel: channel, id: id)
        expect(timer.success && duplicate.message == timer.message && duplicate.state?.settings.countdown == timer.state?.settings.countdown, "Retransmitted IDs execute exactly once")
        let off = AgentConnection.send(.dailyOff, targetPID: server.processIdentifier, channel: channel)
        expect(off.success && off.state?.settings.daily.enabled == false && off.state?.settings.countdown != nil, "Daily off preserves countdown")
        let canceled = AgentConnection.send(.cancelTimer, targetPID: server.processIdentifier, channel: channel)
        expect(canceled.success && canceled.state?.settings.countdown == nil, "Countdown cancel is confirmed")
        let dimmed = AgentConnection.send(.dim, targetPID: server.processIdentifier, channel: channel)
        expect(!dimmed.success && dimmed.message.contains("(7)") && dimmed.state?.keepAwake == false, "Delayed display failure propagates instead of a false acknowledgement")
        let missed = AgentConnection.send(.show, targetPID: -1, channel: channel, timeout: 0.2)
        expect(!missed.success && missed.message.contains("may have been applied"), "Unknown timeout is explicit; no invented success")
        server.terminate();server.waitUntilExit()

        // Verify the same hidden application-launch API used by the installed CLI, with a fixture bundle.
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent("ScreenAwake-Agent-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: folder) }
        let bundle = folder.appendingPathComponent("Fixture.app")
        let contents = bundle.appendingPathComponent("Contents")
        try FileManager.default.createDirectory(at: contents.appendingPathComponent("MacOS"), withIntermediateDirectories: true)
        let executable = contents.appendingPathComponent("MacOS/Fixture")
        try FileManager.default.copyItem(atPath: CommandLine.arguments[0], toPath: executable.path)
        let identifier = "com.mickyyang.screen-awake.checks.\(UUID().uuidString)"
        let info: [String: Any] = ["CFBundleIdentifier": identifier, "CFBundleExecutable": "Fixture", "CFBundleName": "Fixture", "CFBundlePackageType": "APPL"]
        try PropertyListSerialization.data(fromPropertyList: info, format: .xml, options: 0).write(to: contents.appendingPathComponent("Info.plist"))
        let launched = AgentClient.request(.show, bundleURL: bundle, identifier: identifier, channel: channel,
            launchArguments: ["--fixture-server", suite, channel])
        expect(launched.success && launched.state?.appRunning == true, "Closed fixture app starts hidden and acknowledges the command")
        if let application = AgentClient.running(identifier: identifier) {
            expect(application.terminate(), "Only the fixture application is terminated")
            let deadline = Date().addingTimeInterval(3)
            while !application.isTerminated && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.05)) }
            expect(application.isTerminated, "No fixture application remains running")
        }
        print("PASS: \(checks) AI-control checks; private preferences, cross-process acknowledgements and hidden fixture launch; no real power calls.")
    }
}
