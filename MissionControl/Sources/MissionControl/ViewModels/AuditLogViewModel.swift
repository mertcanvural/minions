import Foundation
import Observation

@MainActor
@Observable
final class AuditLogViewModel {

    // MARK: - Properties

    var events: [AuditEvent] = []
    var useLiveData: Bool = false
    var searchQuery: String = ""
    var selectedEventTypes: Set<AuditEventType> = []
    var isAutoScrolling: Bool = true
    var isLoading: Bool = false
    var error: Error?
    /// True when useLiveData is on but ~/.minion/audit/ does not exist on disk.
    var auditDirectoryMissing: Bool = false

    // MARK: - Computed

    var filteredEvents: [AuditEvent] {
        events.filter { event in
            let matchesType = selectedEventTypes.isEmpty || selectedEventTypes.contains(event.eventType)
            let matchesSearch = searchQuery.isEmpty
                || event.taskId.localizedCaseInsensitiveContains(searchQuery)
                || event.eventType.rawValue.localizedCaseInsensitiveContains(searchQuery)
                || event.data.values.contains { $0.localizedCaseInsensitiveContains(searchQuery) }
            return matchesType && matchesSearch
        }
    }

    // MARK: - Private

    private let bridgeService: any BridgeServiceProtocol
    private let realFileService = RealAuditFileService()
    private let auditPath: String

    // MARK: - Init

    init(
        bridgeService: any BridgeServiceProtocol = MockBridgeService(),
        auditPath: String = "\(NSHomeDirectory())/.minion/audit"
    ) {
        self.bridgeService = bridgeService
        self.auditPath = auditPath
    }

    // MARK: - Data Loading

    func loadEvents() async {
        isLoading = true
        error = nil
        auditDirectoryMissing = false

        do {
            if useLiveData {
                let dirExists = FileManager.default.fileExists(atPath: auditPath)
                guard dirExists else {
                    auditDirectoryMissing = true
                    events = []
                    isLoading = false
                    realFileService.stopWatching()
                    return
                }

                let files = try realFileService.availableLogFiles(in: auditPath)
                var allEvents: [AuditEvent] = []
                for file in files {
                    let loaded = try realFileService.loadEvents(from: file.path, limit: 500)
                    allEvents.append(contentsOf: loaded)
                }
                events = allEvents.sorted { $0.timestamp > $1.timestamp }

                // Start watching today's file for new appended events
                startFileWatching()
            } else {
                realFileService.stopWatching()
                events = try await bridgeService.fetchAuditEvents(limit: 100)
            }
        } catch {
            self.error = error
        }

        isLoading = false
    }

    func toggleDataSource() {
        useLiveData.toggle()
        Task { await loadEvents() }
    }

    // MARK: - Export

    func exportEvents(format: ExportFormat) -> URL {
        let tempDir = FileManager.default.temporaryDirectory
        let filename = "audit-export-\(Int(Date().timeIntervalSince1970)).\(format.fileExtension)"
        let url = tempDir.appendingPathComponent(filename)

        let eventsToExport = filteredEvents

        do {
            switch format {
            case .json:
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                encoder.dateEncodingStrategy = .iso8601
                let data = try encoder.encode(eventsToExport)
                try data.write(to: url)

            case .csv:
                var lines = ["timestamp,taskId,eventType,durationMs,data"]
                for event in eventsToExport {
                    let dataStr = event.data.map { "\($0.key)=\($0.value)" }.joined(separator: "; ")
                    let duration = event.durationMs.map { String($0) } ?? ""
                    let isoDate = ISO8601DateFormatter().string(from: event.timestamp)
                    lines.append("\(isoDate),\(event.taskId),\(event.eventType.rawValue),\(duration),\"\(dataStr)\"")
                }
                let csv = lines.joined(separator: "\n")
                try csv.write(to: url, atomically: true, encoding: .utf8)
            }
        } catch {
            // Return empty file on error — caller can check file size
        }

        return url
    }

    enum ExportFormat {
        case json
        case csv

        var fileExtension: String {
            switch self {
            case .json: return "json"
            case .csv: return "csv"
            }
        }
    }

    // MARK: - File Watching

    private func startFileWatching() {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let filePath = "\(auditPath)/audit-\(today).jsonl"

        realFileService.startWatching(path: filePath) { [weak self] in
            // Called on main queue by RealAuditFileService
            guard let self else { return }
            Task { @MainActor [weak self] in
                guard let self else { return }
                // Reload only the current file to pick up appended lines
                if let newEvents = try? self.realFileService.loadEvents(from: filePath, limit: 500) {
                    let merged = (self.events + newEvents)
                        .reduce(into: [String: AuditEvent]()) { acc, e in
                            let key = "\(e.timestamp.timeIntervalSince1970)-\(e.taskId)-\(e.eventType.rawValue)"
                            acc[key] = e
                        }
                        .values
                        .sorted { $0.timestamp > $1.timestamp }
                    self.events = merged
                }
            }
        }
    }
}
