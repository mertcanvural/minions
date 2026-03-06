import Foundation

/// Reads actual ~/.minion/audit/audit-YYYY-MM-DD.jsonl files and supports
/// live file watching via DispatchSource for tail-like behaviour.
final class RealAuditFileService: AuditFileServiceProtocol, @unchecked Sendable {

    // MARK: - State (main-queue only)

    private var fileSource: DispatchSourceFileSystemObject?

    // MARK: - AuditFileServiceProtocol

    func loadEvents(from path: String, limit: Int) throws -> [AuditEvent] {
        guard FileManager.default.fileExists(atPath: path) else {
            return []
        }

        let content = try String(contentsOfFile: path, encoding: .utf8)
        let lines = content.components(separatedBy: .newlines).filter { !$0.isEmpty }

        let decoder = makeDateFlexibleDecoder()
        var events: [AuditEvent] = []

        for line in lines {
            guard let lineData = line.data(using: .utf8) else { continue }
            do {
                let event = try decoder.decode(AuditEvent.self, from: lineData)
                events.append(event)
            } catch {
                // Gracefully skip malformed lines
                print("[RealAuditFileService] Skipping malformed line: \(error.localizedDescription)")
                print("[RealAuditFileService]   Line preview: \(line.prefix(120))")
            }
        }

        // Return the most recent `limit` events, oldest first so callers can sort descending
        let sorted = events.sorted { $0.timestamp < $1.timestamp }
        return Array(sorted.suffix(limit))
    }

    func availableLogFiles(in directory: String) throws -> [URL] {
        let fm = FileManager.default
        guard fm.fileExists(atPath: directory) else {
            return []
        }

        let dirURL = URL(fileURLWithPath: directory)
        let contents = try fm.contentsOfDirectory(
            at: dirURL,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        return contents
            .filter { $0.pathExtension == "jsonl" && $0.lastPathComponent.hasPrefix("audit-") }
            .sorted { $0.lastPathComponent > $1.lastPathComponent } // newest file first
    }

    // MARK: - File Watching

    /// Watches `path` for write events and calls `onChange` on the main queue.
    /// - Parameters:
    ///   - path: Absolute path to the JSONL file to watch. Must exist.
    ///   - onChange: Closure called on the **main** queue each time the file is written.
    func startWatching(path: String, onChange: @escaping () -> Void) {
        stopWatching()

        guard FileManager.default.fileExists(atPath: path) else {
            print("[RealAuditFileService] File not found for watching: \(path)")
            return
        }

        let fd = open(path, O_EVTONLY)
        guard fd >= 0 else {
            print("[RealAuditFileService] Cannot open file descriptor for: \(path)")
            return
        }

        let source = DispatchSource.makeFileSystemObjectSource(
            fileDescriptor: fd,
            eventMask: .write,
            queue: .main
        )

        source.setEventHandler(handler: onChange)

        source.setCancelHandler {
            close(fd)
        }

        source.resume()
        fileSource = source
    }

    func stopWatching() {
        fileSource?.cancel()
        fileSource = nil
    }

    deinit {
        stopWatching()
    }

    // MARK: - Private

    /// A JSONDecoder that handles multiple date formats used by real Minions audit files:
    /// - Unix timestamp (Double)
    /// - ISO 8601 with fractional seconds
    /// - ISO 8601 without fractional seconds
    /// - Unix timestamp encoded as a String
    ///
    /// Also converts snake_case JSON keys to camelCase to match the Swift model.
    private func makeDateFlexibleDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()

            // Attempt 1: numeric Unix timestamp
            if let interval = try? container.decode(Double.self) {
                return Date(timeIntervalSince1970: interval)
            }

            // All remaining attempts work with a string value
            let dateString = try container.decode(String.self)

            // Attempt 2: ISO 8601 with fractional seconds (e.g. "2025-01-15T14:30:00.123Z")
            let isoFull = ISO8601DateFormatter()
            isoFull.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = isoFull.date(from: dateString) {
                return date
            }

            // Attempt 3: ISO 8601 without fractional seconds (e.g. "2025-01-15T14:30:00Z")
            let isoBasic = ISO8601DateFormatter()
            isoBasic.formatOptions = [.withInternetDateTime]
            if let date = isoBasic.date(from: dateString) {
                return date
            }

            // Attempt 4: Unix timestamp as string (e.g. "1736954000.5")
            if let interval = Double(dateString) {
                return Date(timeIntervalSince1970: interval)
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date from value: \(dateString)"
            )
        }

        return decoder
    }
}
