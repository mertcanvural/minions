import Foundation

struct MockAuditFileService: AuditFileServiceProtocol {

    func loadEvents(from path: String, limit: Int) throws -> [AuditEvent] {
        let now = Date()
        let events: [AuditEvent] = [
            AuditEvent(timestamp: now.addingTimeInterval(-7200), taskId: "task-010", eventType: .taskStarted, data: ["description": "Migrate database to PostgreSQL 15", "agent": "backend_expert", "project": "myapp"]),
            AuditEvent(timestamp: now.addingTimeInterval(-7198), taskId: "task-010", eventType: .agentSelected, data: ["agent": "backend_expert", "model": "gpt-4o", "complexity": "complex"], durationMs: 210),
            AuditEvent(timestamp: now.addingTimeInterval(-7196), taskId: "task-010", eventType: .toolSetSelected, data: ["tools": "file_editor,bash,search,database"], durationMs: 45),
            AuditEvent(timestamp: now.addingTimeInterval(-7140), taskId: "task-010", eventType: .blueprintStep, data: ["step": "implement_task", "node": "0", "status": "completed"], durationMs: 56000),
            AuditEvent(timestamp: now.addingTimeInterval(-7137), taskId: "task-010", eventType: .blueprintStep, data: ["step": "run_linters", "node": "1", "status": "completed", "result": "pass"], durationMs: 2800),
            AuditEvent(timestamp: now.addingTimeInterval(-7136), taskId: "task-010", eventType: .blueprintStep, data: ["step": "git_commit", "node": "3", "status": "completed", "sha": "def5678"], durationMs: 700),
            AuditEvent(timestamp: now.addingTimeInterval(-7133), taskId: "task-010", eventType: .blueprintStep, data: ["step": "push_branch", "node": "4", "status": "completed", "branch": "feat/pg15"], durationMs: 2100),
            AuditEvent(timestamp: now.addingTimeInterval(-7000), taskId: "task-010", eventType: .ciResult, data: ["attempt": "1", "status": "fail", "error": "Migration script failed on test db", "duration": "133s"], durationMs: 133000),
            AuditEvent(timestamp: now.addingTimeInterval(-6990), taskId: "task-010", eventType: .blueprintStep, data: ["step": "fix_ci_1", "node": "6", "status": "completed"], durationMs: 10000),
            AuditEvent(timestamp: now.addingTimeInterval(-6850), taskId: "task-010", eventType: .ciResult, data: ["attempt": "2", "status": "pass", "duration": "140s", "tests": "89 passed, 0 failed"], durationMs: 140000),
            AuditEvent(timestamp: now.addingTimeInterval(-6848), taskId: "task-010", eventType: .blueprintStep, data: ["step": "create_pr", "node": "10", "status": "completed", "pr_url": "https://github.com/org/repo/pull/38"], durationMs: 1100),
            AuditEvent(timestamp: now.addingTimeInterval(-6847), taskId: "task-010", eventType: .prCreated, data: ["pr_number": "38", "title": "feat: Migrate to PostgreSQL 15", "branch": "feat/pg15"]),
            AuditEvent(timestamp: now.addingTimeInterval(-6846), taskId: "task-010", eventType: .taskCompleted, data: ["duration": "354s", "pr": "38", "nodes_completed": "11"], durationMs: 354000),
            AuditEvent(timestamp: now.addingTimeInterval(-5400), taskId: "task-011", eventType: .taskStarted, data: ["description": "Add Playwright E2E tests for checkout flow", "agent": "test_expert", "project": "myapp"]),
            AuditEvent(timestamp: now.addingTimeInterval(-5398), taskId: "task-011", eventType: .agentSelected, data: ["agent": "test_expert", "model": "gpt-4o-mini", "complexity": "medium"], durationMs: 190),
            AuditEvent(timestamp: now.addingTimeInterval(-5396), taskId: "task-011", eventType: .toolSetSelected, data: ["tools": "file_editor,bash,search"], durationMs: 40),
            AuditEvent(timestamp: now.addingTimeInterval(-5300), taskId: "task-011", eventType: .blueprintStep, data: ["step": "implement_task", "node": "0", "status": "completed"], durationMs: 98000),
            AuditEvent(timestamp: now.addingTimeInterval(-5200), taskId: "task-011", eventType: .ciResult, data: ["attempt": "1", "status": "pass", "duration": "95s", "tests": "34 passed, 0 failed"], durationMs: 95000),
            AuditEvent(timestamp: now.addingTimeInterval(-5198), taskId: "task-011", eventType: .prCreated, data: ["pr_number": "39", "title": "test: Add E2E tests for checkout", "branch": "test/checkout-e2e"]),
            AuditEvent(timestamp: now.addingTimeInterval(-5197), taskId: "task-011", eventType: .taskCompleted, data: ["duration": "203s", "pr": "39", "nodes_completed": "10"], durationMs: 203000)
        ]
        return Array(events.prefix(limit))
    }

    func availableLogFiles(in directory: String) throws -> [URL] {
        let now = Date()
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return (0..<7).compactMap { dayOffset -> URL? in
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { return nil }
            let filename = "audit-\(formatter.string(from: date)).jsonl"
            return URL(fileURLWithPath: "\(directory)/\(filename)")
        }
    }
}
