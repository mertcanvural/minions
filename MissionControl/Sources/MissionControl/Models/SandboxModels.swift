import Foundation

// MARK: - Sandbox Status

enum SandboxStatus: String, Codable, CaseIterable {
    case warm
    case claimed
    case running
    case completed
    case failed
    case cleaned
}

// MARK: - Sandbox

struct Sandbox: Identifiable, Codable {
    let id: String
    let taskId: String
    let projectPath: String
    let workspacePath: String
    let branchName: String
    let createdAt: Date
    var status: SandboxStatus
    let pipelineStage: Int

    var duration: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    enum CodingKeys: String, CodingKey {
        case id, taskId, projectPath, workspacePath, branchName, createdAt, status, pipelineStage
    }
}

// MARK: - Pool Stats

struct PoolStats: Codable {
    let poolSize: Int
    let available: Int
    let inUse: Int

    var warm: Int {
        poolSize - available - inUse
    }
}
