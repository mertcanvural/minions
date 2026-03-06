import Foundation

struct MockBridgeService: BridgeServiceProtocol {

    // MARK: - Protocol Methods

    func fetchDashboardMetrics() async throws -> DashboardMetrics {
        try await Task.sleep(nanoseconds: 400_000_000)
        return DashboardMetrics(
            activeTasks: 3,
            successRate: 0.87,
            avgDuration: 142.5,
            queueDepth: 5,
            trends: DashboardMetrics.MetricsTrends(
                activeTasksTrend: 2,
                successRateTrend: 0.03,
                avgDurationTrend: -12.0,
                queueDepthTrend: -1
            )
        )
    }

    func fetchRecentTasks() async throws -> [RecentTask] {
        try await Task.sleep(nanoseconds: 500_000_000)
        let now = Date()
        return [
            RecentTask(id: "task-001", description: "Add user authentication with JWT", agentName: "Backend Expert", status: "completed", duration: 187.3, startedAt: now.addingTimeInterval(-3600)),
            RecentTask(id: "task-002", description: "Create responsive dashboard component", agentName: "Frontend Expert", status: "completed", duration: 95.6, startedAt: now.addingTimeInterval(-2700)),
            RecentTask(id: "task-003", description: "Write unit tests for auth service", agentName: "Test Expert", status: "running", duration: 45.2, startedAt: now.addingTimeInterval(-1800)),
            RecentTask(id: "task-004", description: "Update deployment pipeline to Kubernetes", agentName: "Infra Expert", status: "failed", duration: 78.9, startedAt: now.addingTimeInterval(-900)),
            RecentTask(id: "task-005", description: "Update README with API documentation", agentName: "Docs Expert", status: "completed", duration: 32.1, startedAt: now.addingTimeInterval(-600)),
            RecentTask(id: "task-006", description: "Fix database migration for users table", agentName: "Backend Expert", status: "completed", duration: 56.4, startedAt: now.addingTimeInterval(-300)),
            RecentTask(id: "task-007", description: "Add sidebar navigation menu", agentName: "Frontend Expert", status: "running", duration: 28.7, startedAt: now.addingTimeInterval(-120)),
            RecentTask(id: "task-008", description: "Refactor and optimize the service layer", agentName: "Generalist", status: "pending", duration: 0, startedAt: now.addingTimeInterval(-30))
        ]
    }

    func fetchBlueprintRun(id: String?) async throws -> BlueprintRun {
        try await Task.sleep(nanoseconds: 600_000_000)
        let startedAt = Date().addingTimeInterval(-300)
        let nodes: [BlueprintNode] = [
            BlueprintNode(
                id: "node-0", name: "Implement Task", nodeType: .agentic,
                status: .completed, duration: 45.2,
                output: "Successfully implemented JWT authentication. Modified auth.ts, middleware/auth.ts, and routes/users.ts. Added refresh token rotation logic.",
                nextOnSuccess: 1, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-1", name: "Run Linters", nodeType: .deterministic,
                status: .completed, duration: 3.1,
                output: "✓ ESLint passed with 0 errors, 0 warnings\n✓ Prettier check passed",
                nextOnSuccess: 3, nextOnFailure: 2, retryCount: 0
            ),
            BlueprintNode(
                id: "node-2", name: "Fix Lint Issues", nodeType: .agentic,
                status: .skipped, duration: 0,
                output: "",
                nextOnSuccess: 3, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-3", name: "Git Commit", nodeType: .deterministic,
                status: .completed, duration: 0.8,
                output: "[feat/auth abc1234] Add JWT authentication\n 3 files changed, 127 insertions(+), 12 deletions(-)",
                nextOnSuccess: 4, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-4", name: "Push Branch", nodeType: .deterministic,
                status: .completed, duration: 2.4,
                output: "Branch 'feat/auth' set up to track remote branch 'feat/auth' from 'origin'.\nTo github.com:org/repo.git\n * [new branch]      feat/auth -> feat/auth",
                nextOnSuccess: 5, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-5", name: "CI Attempt 1", nodeType: .deterministic,
                status: .running, duration: 0,
                output: "Running GitHub Actions workflow... (42s elapsed)",
                nextOnSuccess: 10, nextOnFailure: 6, retryCount: 0
            ),
            BlueprintNode(
                id: "node-6", name: "Fix CI (Attempt 1)", nodeType: .agentic,
                status: .pending, duration: 0,
                output: "",
                nextOnSuccess: 7, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-7", name: "CI Attempt 2", nodeType: .deterministic,
                status: .pending, duration: 0,
                output: "",
                nextOnSuccess: 10, nextOnFailure: 8, retryCount: 0
            ),
            BlueprintNode(
                id: "node-8", name: "Fix CI (Attempt 2)", nodeType: .agentic,
                status: .pending, duration: 0,
                output: "",
                nextOnSuccess: 9, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-9", name: "CI Final Attempt", nodeType: .deterministic,
                status: .pending, duration: 0,
                output: "",
                nextOnSuccess: 10, nextOnFailure: 11, retryCount: 0
            ),
            BlueprintNode(
                id: "node-10", name: "Create PR", nodeType: .deterministic,
                status: .pending, duration: 0,
                output: "",
                nextOnSuccess: nil, nextOnFailure: nil, retryCount: 0
            ),
            BlueprintNode(
                id: "node-11", name: "Human Review", nodeType: .deterministic,
                status: .pending, duration: 0,
                output: "All CI attempts failed. Manual intervention required.",
                nextOnSuccess: nil, nextOnFailure: nil, retryCount: 0
            )
        ]
        return BlueprintRun(
            id: id ?? "run-001",
            taskDescription: "Add user authentication with JWT tokens and refresh token rotation",
            nodes: nodes,
            startedAt: startedAt,
            completedAt: nil,
            status: .running
        )
    }

    func fetchSandboxes() async throws -> [Sandbox] {
        try await Task.sleep(nanoseconds: 450_000_000)
        let now = Date()
        return [
            Sandbox(id: "sb-001", taskId: "task-001", projectPath: "/home/runner/projects/myapp", workspacePath: "/home/runner/workspace/task-001", branchName: "feat/auth", createdAt: now.addingTimeInterval(-3600), status: .completed, pipelineStage: 11),
            Sandbox(id: "sb-002", taskId: "task-002", projectPath: "/home/runner/projects/myapp", workspacePath: "/home/runner/workspace/task-002", branchName: "feat/dashboard", createdAt: now.addingTimeInterval(-2700), status: .completed, pipelineStage: 10),
            Sandbox(id: "sb-003", taskId: "task-003", projectPath: "/home/runner/projects/myapp", workspacePath: "/home/runner/workspace/task-003", branchName: "test/auth-service", createdAt: now.addingTimeInterval(-1800), status: .running, pipelineStage: 5),
            Sandbox(id: "sb-004", taskId: "task-004", projectPath: "/home/runner/projects/infra", workspacePath: "/home/runner/workspace/task-004", branchName: "infra/k8s-pipeline", createdAt: now.addingTimeInterval(-900), status: .failed, pipelineStage: 4),
            Sandbox(id: "sb-005", taskId: "task-007", projectPath: "/home/runner/projects/myapp", workspacePath: "/home/runner/workspace/task-007", branchName: "feat/sidebar", createdAt: now.addingTimeInterval(-120), status: .claimed, pipelineStage: 1),
            Sandbox(id: "sb-006", taskId: "pool-warm-1", projectPath: "/home/runner/projects/myapp", workspacePath: "/home/runner/workspace/pool-warm-1", branchName: "", createdAt: now.addingTimeInterval(-7200), status: .warm, pipelineStage: 0)
        ]
    }

    func fetchPoolStats() async throws -> PoolStats {
        try await Task.sleep(nanoseconds: 300_000_000)
        // poolSize=6, available=1, inUse=2 -> warm = 6 - 1 - 2 = 3
        return PoolStats(poolSize: 6, available: 1, inUse: 2)
    }

    func fetchAgentProfiles() async throws -> [AgentProfile] {
        try await Task.sleep(nanoseconds: 350_000_000)
        return Self.agentProfiles
    }

    func routeTask(description: String) async throws -> TaskRouting {
        try await Task.sleep(nanoseconds: 500_000_000)
        let lower = description.lowercased()
        let words = lower.components(separatedBy: .whitespaces).map {
            $0.trimmingCharacters(in: .punctuationCharacters)
        }

        let keywordSets: [String: [String]] = [
            "frontend": ["component", "button", "page", "ui", "css", "style", "layout", "modal", "form", "dashboard", "spinner", "loading", "card", "menu", "sidebar", "navbar", "responsive", "animation", "icon"],
            "backend": ["api", "endpoint", "route", "controller", "service", "auth", "jwt", "webhook", "socket", "cors", "graphql", "rest", "middleware", "server"],
            "database": ["migration", "schema", "database", "prisma", "sql", "table", "column", "seed", "query", "index", "postgres", "mysql"],
            "infra": ["docker", "terraform", "deploy", "pipeline", "kubernetes", "aws", "ec2", "ci", "cd", "k8s", "nginx", "ssl", "cloud"],
            "docs": ["readme", "documentation", "docs", "changelog", "contributing", "guide", "tutorial", "comment", "docstring"],
            "testing": ["test", "spec", "coverage", "mock", "jest", "vitest", "playwright", "unit", "integration", "e2e", "fixture"]
        ]

        // Special case: explicit test writing request
        let isTestRequest = lower.contains("write tests") || lower.contains("add tests") ||
                            lower.contains("create tests") || lower.contains("fix tests")

        var scores: [String: Int] = [:]
        var matchedKeywords: Set<String> = []

        if isTestRequest {
            scores["testing"] = 100
            matchedKeywords.insert("tests")
        } else {
            for (category, keywords) in keywordSets {
                for word in words {
                    if keywords.contains(word) {
                        scores[category, default: 0] += 1
                        matchedKeywords.insert(word)
                    }
                }
            }
        }

        let topCategory = scores.max(by: { $0.value < $1.value })
        let detectedType = (topCategory?.value ?? 0) > 0 ? (topCategory?.key ?? "general") : "general"

        let complexity = estimateComplexity(description)
        let agent = Self.agentForType(detectedType, complexity: complexity)

        return TaskRouting(
            detectedType: detectedType,
            selectedAgent: agent,
            complexity: complexity,
            keywordMatches: matchedKeywords.sorted()
        )
    }

    func launchTask(description: String, project: String) async throws -> String {
        try await Task.sleep(nanoseconds: 800_000_000)
        let shortId = String(UUID().uuidString.prefix(8).lowercased())
        return "task-\(shortId)"
    }

    func fetchAuditEvents(limit: Int) async throws -> [AuditEvent] {
        try await Task.sleep(nanoseconds: 400_000_000)
        return Array(Self.mockAuditEvents().prefix(limit))
    }

    // MARK: - Private Helpers

    private func estimateComplexity(_ task: String) -> TaskComplexity {
        let lower = task.lowercased()
        let words = lower.components(separatedBy: .whitespaces)
        var score = 0

        if words.count > 50 { score += 2 } else if words.count > 25 { score += 1 }

        let complexityKeywords = ["refactor", "multiple", "rewrite", "migrate", "redesign", "overhaul", "architect", "integrate"]
        for keyword in complexityKeywords where lower.contains(keyword) { score += 1 }

        let multiFileKeywords = ["across", "everywhere", "all files", "many", "several"]
        for keyword in multiFileKeywords where lower.contains(keyword) { score += 1 }

        if lower.contains("and also") || lower.contains("and then") || lower.contains("additionally") { score += 1 }

        if score >= 4 { return .complex }
        if score >= 2 { return .medium }
        return .simple
    }

    private static func agentForType(_ type: String, complexity: TaskComplexity) -> AgentProfile {
        switch type {
        case "frontend": return agentProfiles[0]
        case "backend", "database": return agentProfiles[1]
        case "infra": return agentProfiles[2]
        case "docs": return agentProfiles[3]
        case "testing": return agentProfiles[4]
        default: return agentProfiles[5]
        }
    }

    // MARK: - Static Mock Data

    static let agentProfiles: [AgentProfile] = [
        AgentProfile(
            id: "frontend_expert",
            displayName: "Frontend Expert",
            model: "gpt-4o-mini",
            systemPrompt: "You are a frontend engineering expert specializing in React, CSS, responsive design, and component architecture. Focus on creating maintainable, accessible, and performant UI components that follow modern best practices.",
            taskTypes: ["frontend"],
            maxFiles: 20,
            timeoutSeconds: 180,
            iconName: "paintbrush.pointed",
            accentColor: "purple"
        ),
        AgentProfile(
            id: "backend_expert",
            displayName: "Backend Expert",
            model: "gpt-4o",
            systemPrompt: "You are a backend engineering expert specializing in API design, database architecture, authentication systems, and service architecture. Focus on reliability, security, and scalability.",
            taskTypes: ["backend", "database"],
            maxFiles: 30,
            timeoutSeconds: 300,
            iconName: "server.rack",
            accentColor: "blue"
        ),
        AgentProfile(
            id: "infra_expert",
            displayName: "Infra Expert",
            model: "gpt-4o-mini",
            systemPrompt: "You are an infrastructure expert specializing in Docker, CI/CD pipelines, Terraform, Kubernetes, and cloud deployment. Focus on automation, reliability, and cost efficiency.",
            taskTypes: ["infra"],
            maxFiles: 15,
            timeoutSeconds: 120,
            iconName: "cloud",
            accentColor: "orange"
        ),
        AgentProfile(
            id: "docs_expert",
            displayName: "Docs Expert",
            model: "gpt-4o-mini",
            systemPrompt: "You are a technical documentation expert specializing in READMEs, API documentation, changelogs, and contribution guides. Focus on clarity, completeness, and developer experience.",
            taskTypes: ["docs"],
            maxFiles: 10,
            timeoutSeconds: 120,
            iconName: "doc.text",
            accentColor: "green"
        ),
        AgentProfile(
            id: "test_expert",
            displayName: "Test Expert",
            model: "gpt-4o-mini",
            systemPrompt: "You are a testing expert specializing in Jest, Vitest, Playwright, coverage analysis, and mocking strategies. Focus on comprehensive test coverage and reliable, maintainable test suites.",
            taskTypes: ["testing"],
            maxFiles: 25,
            timeoutSeconds: 180,
            iconName: "checkmark.shield",
            accentColor: "teal"
        ),
        AgentProfile(
            id: "generalist",
            displayName: "Generalist",
            model: "gpt-4o",
            systemPrompt: "You are a full-stack engineering generalist capable of handling any type of task. Adapt your approach based on the requirements and make sound architectural decisions across the entire stack.",
            taskTypes: ["general"],
            maxFiles: 50,
            timeoutSeconds: 300,
            iconName: "star",
            accentColor: "indigo"
        )
    ]

    static func mockAuditEvents() -> [AuditEvent] {
        let now = Date()
        return [
            AuditEvent(timestamp: now.addingTimeInterval(-3600), taskId: "task-001", eventType: .taskStarted, data: ["description": "Add user authentication with JWT", "agent": "backend_expert", "project": "myapp"]),
            AuditEvent(timestamp: now.addingTimeInterval(-3598), taskId: "task-001", eventType: .agentSelected, data: ["agent": "backend_expert", "model": "gpt-4o", "complexity": "medium"], durationMs: 200),
            AuditEvent(timestamp: now.addingTimeInterval(-3595), taskId: "task-001", eventType: .toolSetSelected, data: ["tools": "file_editor,bash,search", "agent": "backend_expert"], durationMs: 50),
            AuditEvent(timestamp: now.addingTimeInterval(-3550), taskId: "task-001", eventType: .blueprintStep, data: ["step": "implement_task", "node": "0", "status": "completed"], durationMs: 45200),
            AuditEvent(timestamp: now.addingTimeInterval(-3547), taskId: "task-001", eventType: .blueprintStep, data: ["step": "run_linters", "node": "1", "status": "completed", "result": "pass"], durationMs: 3100),
            AuditEvent(timestamp: now.addingTimeInterval(-3546), taskId: "task-001", eventType: .blueprintStep, data: ["step": "git_commit", "node": "3", "status": "completed", "sha": "abc1234"], durationMs: 800),
            AuditEvent(timestamp: now.addingTimeInterval(-3543), taskId: "task-001", eventType: .blueprintStep, data: ["step": "push_branch", "node": "4", "status": "completed", "branch": "feat/auth"], durationMs: 2400),
            AuditEvent(timestamp: now.addingTimeInterval(-3416), taskId: "task-001", eventType: .ciResult, data: ["attempt": "1", "status": "pass", "duration": "127s", "tests": "142 passed, 0 failed"], durationMs: 127000),
            AuditEvent(timestamp: now.addingTimeInterval(-3415), taskId: "task-001", eventType: .blueprintStep, data: ["step": "create_pr", "node": "10", "status": "completed", "pr_url": "https://github.com/org/repo/pull/42"], durationMs: 1200),
            AuditEvent(timestamp: now.addingTimeInterval(-3414), taskId: "task-001", eventType: .prCreated, data: ["pr_number": "42", "title": "feat: Add JWT authentication", "branch": "feat/auth"]),
            AuditEvent(timestamp: now.addingTimeInterval(-3413), taskId: "task-001", eventType: .taskCompleted, data: ["duration": "187s", "pr": "42", "nodes_completed": "10"], durationMs: 187000),
            AuditEvent(timestamp: now.addingTimeInterval(-2700), taskId: "task-002", eventType: .taskStarted, data: ["description": "Create responsive dashboard component", "agent": "frontend_expert", "project": "myapp"]),
            AuditEvent(timestamp: now.addingTimeInterval(-2698), taskId: "task-002", eventType: .agentSelected, data: ["agent": "frontend_expert", "model": "gpt-4o-mini", "complexity": "simple"], durationMs: 180),
            AuditEvent(timestamp: now.addingTimeInterval(-2604), taskId: "task-002", eventType: .blueprintStep, data: ["step": "implement_task", "node": "0", "status": "completed"], durationMs: 94200),
            AuditEvent(timestamp: now.addingTimeInterval(-2514), taskId: "task-002", eventType: .ciResult, data: ["attempt": "1", "status": "pass", "duration": "89s", "tests": "67 passed, 0 failed"], durationMs: 89000),
            AuditEvent(timestamp: now.addingTimeInterval(-2513), taskId: "task-002", eventType: .taskCompleted, data: ["duration": "187s", "pr": "43", "nodes_completed": "10"], durationMs: 187000),
            AuditEvent(timestamp: now.addingTimeInterval(-900), taskId: "task-004", eventType: .taskStarted, data: ["description": "Update deployment pipeline to Kubernetes", "agent": "infra_expert", "project": "infra"]),
            AuditEvent(timestamp: now.addingTimeInterval(-898), taskId: "task-004", eventType: .agentSelected, data: ["agent": "infra_expert", "model": "gpt-4o-mini", "complexity": "complex"], durationMs: 220),
            AuditEvent(timestamp: now.addingTimeInterval(-820), taskId: "task-004", eventType: .ciResult, data: ["attempt": "1", "status": "fail", "error": "Kubernetes cluster unreachable", "duration": "78s"], durationMs: 78000),
            AuditEvent(timestamp: now.addingTimeInterval(-815), taskId: "task-004", eventType: .taskFailed, data: ["reason": "All CI attempts failed - cluster unreachable", "attempts": "3"], durationMs: 85000)
        ]
    }
}
