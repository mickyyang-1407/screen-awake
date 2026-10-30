import Foundation
import IOKit

nonisolated struct CommandResult {
    let status: Int32
    let output: String
}

// Injectable only from Swift tests; production always uses fixed system executables.
nonisolated struct DisplayCommandRunner {
    var process: (String, [String]) throws -> CommandResult
    var requestIdle: () -> IOReturn
    static var live: Self { Self(process: DisplayCommand.runProcess, requestIdle: DisplayCommand.requestIdle) }
}

nonisolated enum DisplayCommand {
    static let version = "1.3.0"
    static let usage = "Usage: ScreenAwake wake | dim | status | --help | --version"

    @concurrent static func perform(command: String) async -> Int32 {
        run(arguments: [command])
    }

    static func run(arguments: [String], runner: DisplayCommandRunner = .live) -> Int32 {
        guard arguments.count == 1 else { writeError(usage); return 64 }
        switch arguments[0] {
        case "--help", "-h":
            print("""
                \(usage)
                  wake    Wake the display with a two-second user-activity assertion.
                  dim     Request display sleep. Does not change system timeouts.
                  status  Read the display-sleep password requirement; changes nothing.
                Unlock your Mac yourself before recording. To wake without a password,
                use System Settings > Lock Screen > Require password ... > Never.
                If greyed out, use iPhone Mirroring > Settings > Ask every time first.
                The GUI keep-awake switch starts off on every launch.
                """)
            return 0
        case "--version": print("Screen Awake \(version)"); return 0
        case "status": return status(runner)
        case "wake": return wake(runner)
        case "dim": return dim(runner)
        default: writeError("Unknown command: \(arguments[0]). \(usage)"); return 64
        }
    }

    private static func status(_ runner: DisplayCommandRunner) -> Int32 {
        do {
            let result = try runner.process("/usr/sbin/sysadminctl", ["-screenLock", "status"])
            print("Lock Screen: \(lockDescription(result))")
            print("No settings were changed. Use --help for setup instructions.")
            return result.status == 0 ? 0 : 1
        } catch { writeError("Could not read Lock Screen status: \(error.localizedDescription)"); return 1 }
    }

    private static func lockDescription(_ result: CommandResult) -> String {
        guard result.status == 0 else { return "password requirement unavailable" }
        if result.output.split(separator: "\n").contains(where: { $0.hasSuffix("screenLock is off") }) {
            return "password requirement is Never"
        }
        if let range = result.output.range(of: "screenLock delay is ") {
            return "password delay is " + result.output[range.upperBound...]
        }
        return "password requirement unavailable"
    }

    private static func wake(_ runner: DisplayCommandRunner) -> Int32 {
        do {
            let preflight = try? runner.process("/usr/sbin/sysadminctl", ["-screenLock", "status"])
            let description = preflight.map(lockDescription) ?? "password requirement unavailable"
            print("Lock Screen: \(description)")
            if description != "password requirement is Never" {
                writeError("WARNING: A password may be required after display sleep. See --help or the app’s Setup guide. wake cannot unlock a locked Mac. No security settings were changed.")
            }
            let result = try runner.process("/usr/bin/caffeinate", ["-u", "-t", "2"])
            guard result.status == 0 else { writeError("wake failed (exit \(result.status)): \(result.output)"); return result.status }
            print("Display wake requested. The two-second assertion has ended.")
            return 0
        } catch { writeError("wake failed: \(error.localizedDescription)"); return 1 }
    }

    private static func dim(_ runner: DisplayCommandRunner) -> Int32 {
        do {
            let result = try runner.process("/usr/bin/pmset", ["displaysleepnow"])
            let failed = result.status != 0 || result.output.contains("Failed to put the display to sleep")
            if !failed { print("Display sleep requested (pmset)."); return 0 }
            // New macOS versions can reject pmset's display-manager request with
            // CGError 1004. Use the display-idle registry request in that case.
            // Neither method changes the user's idle timeout or lock policy.
            if result.output.hasSuffix("error 1004") {
                let code = runner.requestIdle()
                if code == kIOReturnSuccess {
                    print("Display sleep requested (IORequestIdle compatibility path).")
                    return 0
                }
                writeError("dim failed: macOS rejected both display-sleep requests (pmset 1004, IOKit \(code)).")
            } else {
                let reason = result.status == 0 ? "pmset rejected the request" : "pmset exit \(result.status)"
                writeError("dim failed (\(reason)): \(result.output)")
            }
            writeError("No system settings were changed. Check for an active local desktop session and try again from Terminal.")
            return result.status == 0 ? 1 : result.status
        } catch { writeError("dim failed: \(error.localizedDescription)"); return 1 }
    }

    static func runProcess(_ executable: String, arguments: [String]) throws -> CommandResult {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: executable)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = pipe
        try process.run()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        return CommandResult(status: process.terminationStatus,
                             output: String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines))
    }

    static func requestIdle() -> IOReturn {
        let service = IORegistryEntryFromPath(kIOMainPortDefault, "IOService:/IOResources/IODisplayWrangler")
        guard service != IO_OBJECT_NULL else { return kIOReturnNotFound }
        defer { IOObjectRelease(service) }
        return IORegistryEntrySetCFProperty(service, "IORequestIdle" as CFString, kCFBooleanTrue)
    }

    private static func writeError(_ message: String) {
        FileHandle.standardError.write(Data((message + "\n").utf8))
    }
}
