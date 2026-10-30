import Foundation
import IOKit

@main
struct DisplayCommandChecks {
    @MainActor static func main() {
        var checks = 0
        func expect(_ condition: Bool, _ message: String) {
            guard condition else { fatalError(message) }
            checks += 1
        }
        var calls: [(String, [String])] = []
        var fallbacks = 0
        var result = CommandResult(status: 0, output: "")
        var idleResult = kIOReturnSuccess
        let runner = DisplayCommandRunner(process: { executable, arguments in
            calls.append((executable, arguments))
            if executable == "/usr/sbin/sysadminctl" {
                return CommandResult(status: 0, output: "example[123]: screenLock delay is immediate")
            }
            return result
        }, requestIdle: { fallbacks += 1; return idleResult })
        for arguments in [[], ["unknown"], ["wake", "dim"], ["--help"], ["--version"]] {
            let status = DisplayCommand.run(arguments: arguments, runner: runner)
            expect(status == (arguments == ["--help"] || arguments == ["--version"] ? 0 : 64), "Argument status")
            expect(calls.isEmpty && fallbacks == 0, "Invalid/help/version must never affect display")
        }
        expect(DisplayCommand.run(arguments: ["status"], runner: runner) == 0, "Read status")
        expect(calls.count == 1 && calls[0].0 == "/usr/sbin/sysadminctl", "status must only read lock state")
        calls.removeAll()
        expect(DisplayCommand.run(arguments: ["wake"], runner: runner) == 0, "Wake continues after password warning")
        expect(calls.count == 2 && calls[1].0 == "/usr/bin/caffeinate" && calls[1].1 == ["-u", "-t", "2"], "Bounded wake")
        result = CommandResult(status: 7, output: "failed")
        expect(DisplayCommand.run(arguments: ["wake"], runner: runner) == 7, "Wake failure must propagate")
        result = CommandResult(status: 0, output: "pmset: Failed to put the display to sleep, error 1004")
        expect(DisplayCommand.run(arguments: ["dim"], runner: runner) == 0 && fallbacks == 1, "1004 compatibility path")
        idleResult = kIOReturnNotPermitted
        expect(DisplayCommand.run(arguments: ["dim"], runner: runner) == 1 && fallbacks == 2, "Both failures must fail")
        result = CommandResult(status: 0, output: "pmset: Failed to put the display to sleep, error 1002")
        expect(DisplayCommand.run(arguments: ["dim"], runner: runner) == 1 && fallbacks == 2, "Zero pmset exit must not mask rejection")
        result = CommandResult(status: 9, output: "no session")
        expect(DisplayCommand.run(arguments: ["dim"], runner: runner) == 9 && fallbacks == 2, "Unrelated failures must not use fallback")
        result = CommandResult(status: 0, output: "")
        expect(DisplayCommand.run(arguments: ["dim"], runner: runner) == 0 && fallbacks == 2, "Normal request bypasses fallback")
        expect(calls.allSatisfy { call in
            (call.0 == "/usr/sbin/sysadminctl" && call.1 == ["-screenLock", "status"]) ||
            (call.0 == "/usr/bin/caffeinate" && call.1 == ["-u", "-t", "2"]) ||
            (call.0 == "/usr/bin/pmset" && call.1 == ["displaysleepnow"])
        }, "Only fixed commands; no settings writes")
        print("PASS: \(checks) checks; all process calls and IOKit requests were isolated fixtures.")
    }
}
