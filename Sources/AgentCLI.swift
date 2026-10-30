import AppKit

@MainActor
enum AgentCLI {
    static func handles(_ arguments: [String]) -> Bool {
        ["agent-help", "awake", "schedule", "dim"].contains(arguments.first ?? "")
    }

    static func run(_ arguments: [String]) -> Int32 {
        if arguments == ["agent-help"] {
            print(AgentGuide.help(executable: Bundle.main.executablePath ?? CommandLine.arguments[0]))
            return 0
        }
        if arguments == ["dim"] {
            guard AgentClient.running() != nil else { return DisplayCommand.run(arguments: arguments) }
            return output(AgentClient.request(.dim))
        }
        guard let operation = AgentOperation.parse(arguments) else {
            return output(AgentReply(success: false, message: "Invalid command. Run agent-help for syntax."), failureCode: 64)
        }
        if AgentClient.running() == nil {
            let defaults = UserDefaults(suiteName: "com.mickyyang.screen-awake")!
            var settings = ScheduleController.loadSettings(defaults: defaults)
            guard AgentOffline.apply(operation, settings: &settings) else { return output(AgentClient.request(operation)) }
            if operation == .dailyOff || operation == .cancelTimer {
                guard AgentOffline.store(settings, defaults: defaults) else {
                    return output(AgentReply(success: false, message: "Could not save settings."))
                }
            }
            let next = SchedulePlanner.next(in: settings, after: Date())
            return output(AgentReply(success: true, message: "App is stopped. Saved settings shown; timers are not running.",
                state: AgentState(version: DisplayCommand.version, appRunning: false, keepAwake: false,
                                  settings: settings, nextAction: next?.action, nextDate: next?.date)))
        }
        return output(AgentClient.request(operation))
    }

    private static func output(_ reply: AgentReply, failureCode: Int32 = 1) -> Int32 {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(reply), let json = String(data: data, encoding: .utf8) else { return 1 }
        print(json)
        return reply.success ? 0 : failureCode
    }
}
