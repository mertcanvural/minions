import Foundation
import Observation

@MainActor
@Observable
final class AgentProfilesViewModel {

    // MARK: - Properties

    var profiles: [AgentProfile] = []
    var routingResult: TaskRouting?
    var taskInput: String = ""
    var isRouting: Bool = false
    var isLoading: Bool = false
    var error: Error?

    // MARK: - Private

    private let service: any BridgeServiceProtocol

    // MARK: - Init

    init(service: any BridgeServiceProtocol = MockBridgeService()) {
        self.service = service
    }

    // MARK: - Data Loading

    func loadProfiles() async {
        isLoading = true
        error = nil

        do {
            profiles = try await service.fetchAgentProfiles()
        } catch {
            self.error = error
        }

        isLoading = false
    }

    // MARK: - Task Routing

    func routeTask() async {
        guard !taskInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isRouting = true
        error = nil

        do {
            routingResult = try await service.routeTask(description: taskInput)
        } catch {
            self.error = error
        }

        isRouting = false
    }

    // MARK: - Complexity Estimation
    // Ported from docs/agent-routing.md complexity heuristic

    func estimateComplexity(task: String) -> TaskComplexity {
        let lower = task.lowercased()
        var score = 0

        // Word count scoring
        let wordCount = task.split(separator: " ").count
        if wordCount > 50 {
            score += 2
        } else if wordCount > 25 {
            score += 1
        }

        // Complexity keywords
        let complexityKeywords = [
            "refactor", "multiple", "rewrite", "migrate",
            "redesign", "overhaul", "architect", "integrate"
        ]
        for keyword in complexityKeywords {
            if lower.contains(keyword) {
                score += 1
            }
        }

        // Multi-file indicators
        let multiFileKeywords = ["across", "everywhere", "all files", "many", "several"]
        for keyword in multiFileKeywords {
            if lower.contains(keyword) {
                score += 1
            }
        }

        // Conjunction patterns
        let conjunctionPatterns = ["and also", "and then", "and additionally"]
        for pattern in conjunctionPatterns {
            if lower.contains(pattern) {
                score += 1
            }
        }

        if score >= 4 {
            return .complex
        } else if score >= 2 {
            return .medium
        } else {
            return .simple
        }
    }
}
