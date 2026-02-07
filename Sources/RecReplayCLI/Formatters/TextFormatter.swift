import Foundation
import RecReplayKit

struct TextFormatter: OutputFormatter {
    let useColor: Bool

    init(useColor: Bool = true) {
        self.useColor = useColor
    }

    func formatValidationResult(_ result: EventValidator.ValidationResult, events: [Event]) -> String {
        var lines: [String] = []

        if result.isValid {
            let checkmark = "OK".colored(.green, enabled: useColor)
            lines.append("\(checkmark) Validation passed (\(events.count) events)")
        } else {
            let cross = "FAILED".colored(.red, enabled: useColor)
            lines.append("\(cross) Validation failed")
        }

        if !result.errors.isEmpty {
            lines.append("")
            lines.append("Errors:".colored(.red, enabled: useColor).bold(enabled: useColor))
            for error in result.errors {
                lines.append("  - \(formatValidationError(error))")
            }
        }

        if !result.warnings.isEmpty {
            lines.append("")
            lines.append("Warnings:".colored(.yellow, enabled: useColor).bold(enabled: useColor))
            for warning in result.warnings {
                lines.append("  - \(formatValidationError(warning))")
            }
        }

        return lines.joined(separator: "\n")
    }

    func formatScenarioInfo(_ scenario: Scenario) -> String {
        var lines: [String] = []

        let durationMs = scenario.durationMs
        let durationSeconds = Double(durationMs) / 1000.0

        lines.append("Scenario".bold(enabled: useColor))
        lines.append("  Version: \(scenario.version ?? "unspecified")")
        lines.append("  Duration: \(String(format: "%.2fs", durationSeconds)) (\(durationMs)ms)")
        lines.append("  Events: \(scenario.events.count)")

        if !scenario.deviceRefs.isEmpty {
            lines.append("")
            lines.append("Devices:".bold(enabled: useColor))
            for ref in scenario.deviceRefs {
                lines.append("  - \(ref.deviceId) (instance: \(ref.instanceId))")
            }
        }

        let instanceIds = Set(scenario.events.map(\.instanceId))
        if !instanceIds.isEmpty {
            lines.append("")
            lines.append("Instance IDs:".bold(enabled: useColor))
            for id in instanceIds.sorted() {
                let count = scenario.events.filter { $0.instanceId == id }.count
                lines.append("  - \(id): \(count) events")
            }
        }

        let eventsByType = Dictionary(grouping: scenario.events, by: \.type)
        lines.append("")
        lines.append("Event Types:".bold(enabled: useColor))
        for (type, events) in eventsByType.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            lines.append("  - \(type.rawValue): \(events.count)")
        }

        return lines.joined(separator: "\n")
    }

    func formatEvent(_ event: Event, elapsedMs: Int) -> String {
        let timestamp = String(format: "[%6dms]", elapsedMs)
        let instanceStr = event.instanceId

        var details: [String] = []

        if let mtu = event.mtu {
            details.append("mtu=\(mtu)")
        }
        if let value = event.value {
            let truncated = value.count > 20 ? String(value.prefix(20)) + "..." : value
            details.append("value=\(truncated)")
        }
        if let status = event.status {
            details.append("status=\(status)")
        }
        if let rssi = event.rssi {
            details.append("rssi=\(rssi)")
        }
        if let reason = event.reason {
            details.append("reason=\(reason)")
        }

        let coloredTimestamp = timestamp.colored(.gray, enabled: useColor)
        let coloredType = coloredEventType(event.type)
        let detailsStr = details.isEmpty ? "" : "  " + details.joined(separator: " ")

        return "\(coloredTimestamp) \(coloredType) \(instanceStr)\(detailsStr)"
    }

    func formatPlaybackHeader(file: String, eventCount: Int, durationMs: Int) -> String {
        let durationSeconds = Double(durationMs) / 1000.0
        let header = "Playing:".bold(enabled: useColor)
        return "\(header) \(file) (\(eventCount) events, \(String(format: "%.1fs", durationSeconds)))"
    }

    func formatPlaybackFooter(eventsPlayed: Int, durationMs: Int) -> String {
        let durationSeconds = Double(durationMs) / 1000.0
        let footer = "Completed:".colored(.green, enabled: useColor).bold(enabled: useColor)
        return "\(footer) \(eventsPlayed) events in \(String(format: "%.2fs", durationSeconds))"
    }

    func formatConversionResult(inputPath: String, outputPath: String, eventCount: Int) -> String {
        let checkmark = "OK".colored(.green, enabled: useColor)
        return "\(checkmark) Converted \(inputPath) -> \(outputPath) (\(eventCount) events)"
    }

    func formatError(_ error: Error) -> String {
        let prefix = "Error:".colored(.red, enabled: useColor).bold(enabled: useColor)
        return "\(prefix) \(error.localizedDescription)"
    }

    private func formatValidationError(_ error: EventValidator.ValidationError) -> String {
        error.description
    }

    private func coloredEventType(_ type: EventType) -> String {
        let str = type.rawValue.padding(toLength: 20, withPad: " ", startingAt: 0)

        switch type {
        case .advertisingStart, .advertisingStop, .advertisingUpdate:
            return str.colored(.cyan, enabled: useColor)
        case .connect:
            return str.colored(.green, enabled: useColor)
        case .disconnect:
            return str.colored(.red, enabled: useColor)
        case .rssi:
            return str.colored(.gray, enabled: useColor)
        case .mtuRequest, .readRequest, .writeRequest:
            return str.colored(.blue, enabled: useColor)
        case .mtuResponse, .readResponse, .writeResponse:
            return str.colored(.magenta, enabled: useColor)
        case .notify, .indicate:
            return str.colored(.yellow, enabled: useColor)
        }
    }
}
