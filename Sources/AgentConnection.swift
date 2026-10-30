import AppKit

nonisolated struct AgentRequest: Codable {
    var id: UUID
    var targetPID: Int32
    var operation: AgentOperation
}

nonisolated struct AgentResponse: Codable {
    var id: UUID
    var reply: AgentReply
}

@MainActor
final class AgentConnection {
    static let channel = "com.mickyyang.screen-awake.agent.v1"
    private var observer: NSObjectProtocol?
    private var pending: Set<UUID> = []
    private var replies: [UUID: AgentReply] = [:]
    private var replyOrder: [UUID] = []
    private let channel: String
    private let handle: (AgentOperation, @escaping (AgentReply) -> Void) -> Void

    init(channel: String = AgentConnection.channel,
         handle: @escaping (AgentOperation, @escaping (AgentReply) -> Void) -> Void) {
        self.channel = channel
        self.handle = handle
    }

    func start() {
        guard observer == nil else { return }
        observer = DistributedNotificationCenter.default().addObserver(forName: Notification.Name(channel + ".request"), object: nil, queue: .main) { [weak self] notification in
            guard let json = notification.userInfo?["payload"] as? String else { return }
            MainActor.assumeIsolated {
                guard let self, json.utf8.count <= 4096, let data = json.data(using: .utf8),
                      let request = try? JSONDecoder().decode(AgentRequest.self, from: data),
                      request.targetPID == getpid() else { return }
                if let reply = self.replies[request.id] { self.respond(id: request.id, reply: reply); return }
                guard self.pending.insert(request.id).inserted else { return }
                self.handle(request.operation) { [weak self] reply in
                    guard let self else { return }
                    self.pending.remove(request.id)
                    self.replies[request.id] = reply
                    self.replyOrder.append(request.id)
                    if self.replyOrder.count > 32 { self.replies.removeValue(forKey: self.replyOrder.removeFirst()) }
                    self.respond(id: request.id, reply: reply)
                }
            }
        }
    }

    func stop() {
        if let observer { DistributedNotificationCenter.default().removeObserver(observer) }
        observer = nil
    }

    private func respond(id: UUID, reply: AgentReply) {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let data = try? encoder.encode(AgentResponse(id: id, reply: reply)),
              let json = String(data: data, encoding: .utf8) else { return }
        DistributedNotificationCenter.default().postNotificationName(Notification.Name(channel + ".response"), object: nil,
            userInfo: ["payload": json], deliverImmediately: true)
    }

    // One CLI invocation waits for an acknowledgement. Retransmits share an ID,
    // so a lost notification cannot start the same countdown or Dim twice.
    static func send(_ operation: AgentOperation, targetPID: Int32, channel: String = channel,
                     id: UUID = UUID(), timeout: TimeInterval = 10) -> AgentReply {
        var reply: AgentReply?
        let center = DistributedNotificationCenter.default()
        let observer = center.addObserver(forName: Notification.Name(channel + ".response"), object: nil, queue: .main) { notification in
            guard let json = notification.userInfo?["payload"] as? String else { return }
            MainActor.assumeIsolated {
                guard json.utf8.count <= 16384, let data = json.data(using: .utf8) else { return }
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                guard let response = try? decoder.decode(AgentResponse.self, from: data), response.id == id else { return }
                reply = response.reply
            }
        }
        defer { center.removeObserver(observer) }
        guard let data = try? JSONEncoder().encode(AgentRequest(id: id, targetPID: targetPID, operation: operation)),
              let json = String(data: data, encoding: .utf8) else {
            return AgentReply(success: false, message: "Could not encode request.")
        }
        let deadline = Date().addingTimeInterval(timeout)
        var nextSend = Date.distantPast
        while reply == nil && Date() < deadline {
            if Date() >= nextSend {
                center.postNotificationName(Notification.Name(channel + ".request"), object: nil,
                    userInfo: ["payload": json], deliverImmediately: true)
                nextSend = Date().addingTimeInterval(0.3)
            }
            RunLoop.current.run(until: min(deadline, Date().addingTimeInterval(0.03)))
        }
        return reply ?? AgentReply(success: false,
            message: "The app did not acknowledge the request. It may have been applied; inspect schedule show before retrying. Quit and reopen an older app if needed.")
    }
}

@MainActor
final class AgentLaunchResult {
    var finished = false
    var app: NSRunningApplication?
    var error: String?
}

@MainActor
enum AgentClient {
    static func running(identifier: String = "com.mickyyang.screen-awake") -> NSRunningApplication? {
        NSRunningApplication.runningApplications(withBundleIdentifier: identifier).first
    }

    static func request(_ operation: AgentOperation, bundleURL: URL = Bundle.main.bundleURL,
                        identifier: String = "com.mickyyang.screen-awake",
                        channel: String = AgentConnection.channel,
                        launchArguments: [String] = ["--background"]) -> AgentReply {
        var app = running(identifier: identifier)
        if app == nil {
            guard bundleURL.pathExtension == "app" else {
                return AgentReply(success: false, message: "Use the executable inside the installed Screen Awake.app for this command.")
            }
            let result = AgentLaunchResult()
            let configuration = NSWorkspace.OpenConfiguration()
            configuration.activates = false
            configuration.hides = true
            configuration.arguments = launchArguments
            NSWorkspace.shared.openApplication(at: bundleURL, configuration: configuration) { opened, error in
                Task { @MainActor in
                    result.app = opened
                    result.error = error?.localizedDescription
                    result.finished = true
                }
            }
            let deadline = Date().addingTimeInterval(10)
            while !result.finished && Date() < deadline { RunLoop.current.run(until: Date().addingTimeInterval(0.03)) }
            guard result.finished, let opened = result.app else {
                return AgentReply(success: false, message: result.error ?? "App launch timed out. Open Screen Awake yourself and retry.")
            }
            app = opened
        }
        guard let app else { return AgentReply(success: false, message: "App is unavailable.") }
        return AgentConnection.send(operation, targetPID: app.processIdentifier, channel: channel)
    }
}
