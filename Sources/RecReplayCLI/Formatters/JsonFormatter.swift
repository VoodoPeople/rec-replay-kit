import Foundation
import RecReplayKit

struct JsonFormatter: OutputFormatter {
    let useColor: Bool = false

    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()

    func formatValidationResult(_ result: EventValidator.ValidationResult, events: [Event]) -> String {
        let output: [String: Any] = [
            "valid": result.isValid,
            "eventCount": events.count,
            "errorCount": result.errors.count,
            "warningCount": result.warnings.count,
            "errors": result.errors.map(\.description),
            "warnings": result.warnings.map(\.description)
        ]
        return toJson(output)
    }

    func formatScenarioInfo(_ scenario: Scenario) -> String {
        let eventsByType = Dictionary(grouping: scenario.events, by: \.type.rawValue)
            .mapValues(\.count)

        let instanceCounts = Dictionary(grouping: scenario.events, by: \.instanceId)
            .mapValues(\.count)

        let output: [String: Any] = [
            "version": scenario.version ?? "unspecified",
            "durationMs": scenario.durationMs,
            "eventCount": scenario.events.count,
            "deviceRefs": scenario.deviceRefs.map { ["deviceId": $0.deviceId, "instanceId": $0.instanceId] },
            "instanceIds": instanceCounts,
            "eventTypes": eventsByType
        ]
        return toJson(output)
    }

    func formatEvent(_ event: Event, elapsedMs: Int) -> String {
        var output: [String: Any] = [
            "t": elapsedMs,
            "type": event.type.rawValue,
            "instanceId": event.instanceId
        ]

        if let requestId = event.requestId { output["requestId"] = requestId }
        if let mtu = event.mtu { output["mtu"] = mtu }
        if let serviceUUID = event.serviceUUID { output["serviceUUID"] = serviceUUID }
        if let characteristicUUID = event.characteristicUUID { output["characteristicUUID"] = characteristicUUID }
        if let value = event.value { output["value"] = value }
        if let status = event.status { output["status"] = status }
        if let reason = event.reason { output["reason"] = reason }
        if let rssi = event.rssi { output["rssi"] = rssi }

        return toJsonCompact(output)
    }

    func formatPlaybackHeader(file: String, eventCount: Int, durationMs: Int) -> String {
        let output: [String: Any] = [
            "status": "started",
            "file": file,
            "eventCount": eventCount,
            "durationMs": durationMs
        ]
        return toJsonCompact(output)
    }

    func formatPlaybackFooter(eventsPlayed: Int, durationMs: Int) -> String {
        let output: [String: Any] = [
            "status": "completed",
            "eventsPlayed": eventsPlayed,
            "durationMs": durationMs
        ]
        return toJsonCompact(output)
    }

    func formatConversionResult(inputPath: String, outputPath: String, eventCount: Int) -> String {
        let output: [String: Any] = [
            "status": "success",
            "inputPath": inputPath,
            "outputPath": outputPath,
            "eventCount": eventCount
        ]
        return toJson(output)
    }

    func formatError(_ error: Error) -> String {
        let output: [String: Any] = [
            "error": true,
            "message": error.localizedDescription
        ]
        return toJson(output)
    }

    private func toJson(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }

    private func toJsonCompact(_ dict: [String: Any]) -> String {
        guard let data = try? JSONSerialization.data(withJSONObject: dict, options: [.sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return "{}"
        }
        return string
    }
}
