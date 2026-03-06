import Foundation

// MARK: - Blueprint Enums

enum NodeType: String, Codable, CaseIterable {
    case agentic
    case deterministic
}

enum NodeStatus: String, Codable, CaseIterable {
    case pending
    case running
    case completed
    case failed
    case skipped
}

// MARK: - Blueprint Node

struct BlueprintNode: Identifiable, Codable {
    let id: String
    let name: String
    let nodeType: NodeType
    var status: NodeStatus
    var duration: TimeInterval
    var output: String
    let nextOnSuccess: Int?
    let nextOnFailure: Int?
    var retryCount: Int

    init(
        id: String,
        name: String,
        nodeType: NodeType,
        status: NodeStatus = .pending,
        duration: TimeInterval = 0,
        output: String = "",
        nextOnSuccess: Int?,
        nextOnFailure: Int?,
        retryCount: Int = 0
    ) {
        self.id = id
        self.name = name
        self.nodeType = nodeType
        self.status = status
        self.duration = duration
        self.output = output
        self.nextOnSuccess = nextOnSuccess
        self.nextOnFailure = nextOnFailure
        self.retryCount = retryCount
    }
}

// MARK: - Blueprint Run

struct BlueprintRun: Identifiable, Codable {
    let id: String
    let taskDescription: String
    var nodes: [BlueprintNode]
    let startedAt: Date
    var completedAt: Date?
    var status: NodeStatus

    var duration: TimeInterval {
        (completedAt ?? Date()).timeIntervalSince(startedAt)
    }
}
