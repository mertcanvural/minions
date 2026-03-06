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
    private let auditFileService: any AuditFileServiceProtocol
    private let auditPath: String

    // MARK: - Init

    init(
        bridgeService: any BridgeServiceProtocol = MockBridgeService(),
        auditFileService: any AuditFileServiceProtocol = MockAuditFileService(),
        auditPath: String = "\(NSHomeDirectory())/.minion/audit"
    ) {
        self.bridgeService = bridgeService
        self.auditFileService = auditFileService
        self.auditPath = auditPath
    }

    // MARK: - Data Loading

    func loadEvents() async {
        isLoading = true
        error = nil

        do {
            if useLiveData {
                let files = try auditFileService.availableLogFiles(in: auditPath)
                var allEvents: [AuditEvent] = []
                for file in files {
                    let loaded = try auditFileService.loadEvents(from: file.path, limit: 500)
                    allEvents.append(contentsOf: loaded)
                }
                events = allEvents.sorted { $0.timestamp > $1.timestamp }
            } else {
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
}
