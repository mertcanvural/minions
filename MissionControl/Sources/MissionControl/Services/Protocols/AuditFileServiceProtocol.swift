import Foundation

protocol AuditFileServiceProtocol: Sendable {
    func loadEvents(from path: String, limit: Int) throws -> [AuditEvent]
    func availableLogFiles(in directory: String) throws -> [URL]
}
