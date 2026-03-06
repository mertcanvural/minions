import Foundation

// MARK: - Audit Event Type

enum AuditEventType: String, Codable, CaseIterable {
    case taskStarted = "task_started"
    case agentSelected = "agent_selected"
    case toolSetSelected = "tool_set_selected"
    case blueprintStep = "blueprint_step"
    case ciResult = "ci_result"
    case prCreated = "pr_created"
    case taskCompleted = "task_completed"
    case taskFailed = "task_failed"
}

// MARK: - Audit Event

struct AuditEvent: Identifiable, Codable {
    let timestamp: Date
    let taskId: String
    let eventType: AuditEventType
    let data: [String: String]
    let durationMs: Int?

    var id: String {
        "\(timestamp.timeIntervalSince1970)-\(taskId)"
    }

    enum CodingKeys: String, CodingKey {
        case timestamp, taskId, eventType, data, durationMs
    }

    init(
        timestamp: Date,
        taskId: String,
        eventType: AuditEventType,
        data: [String: String],
        durationMs: Int? = nil
    ) {
        self.timestamp = timestamp
        self.taskId = taskId
        self.eventType = eventType
        self.data = data
        self.durationMs = durationMs
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        self.taskId = try container.decode(String.self, forKey: .taskId)
        self.eventType = try container.decode(AuditEventType.self, forKey: .eventType)
        self.data = try container.decode([String: String].self, forKey: .data)
        self.durationMs = try container.decodeIfPresent(Int.self, forKey: .durationMs)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(taskId, forKey: .taskId)
        try container.encode(eventType, forKey: .eventType)
        try container.encode(data, forKey: .data)
        try container.encodeIfPresent(durationMs, forKey: .durationMs)
    }
}
