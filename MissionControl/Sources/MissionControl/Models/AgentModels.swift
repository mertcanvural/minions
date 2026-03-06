import Foundation

// MARK: - Agent Profile

struct AgentProfile: Identifiable, Codable {
    let id: String
    let displayName: String
    let model: String
    let systemPrompt: String
    let taskTypes: [String]
    let maxFiles: Int
    let timeoutSeconds: Int
    let iconName: String
    let accentColor: String
}

// MARK: - Task Complexity

enum TaskComplexity: String, Codable, CaseIterable {
    case simple
    case medium
    case complex
}

// MARK: - Task Routing

struct TaskRouting: Codable {
    let detectedType: String
    let selectedAgent: AgentProfile
    let complexity: TaskComplexity
    let keywordMatches: [String]
}
