import ArgumentParser
import Foundation
import RecReplayKit

struct Convert: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Convert old format scenarios to new schema"
    )

    @OptionGroup var options: GlobalOptions
    @OptionGroup var file: ScenarioFileArgument

    @Option(name: .shortAndLong, help: "Output file path")
    var output: String

    func run() throws {
        let formatter = createFormatter(
            format: options.format,
            useColor: !options.noColor && Terminal.isInteractive()
        )

        do {
            let inputUrl = URL(fileURLWithPath: file.path)
            let inputData = try Data(contentsOf: inputUrl)

            let scenario = try migrateToNewFormat(from: inputData)

            let encoder = JSONEncoder()
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let outputData = try encoder.encode(scenario)

            let outputUrl = URL(fileURLWithPath: output)
            try outputData.write(to: outputUrl)

            let result = formatter.formatConversionResult(
                inputPath: file.path,
                outputPath: output,
                eventCount: scenario.events.count
            )
            Terminal.print(result)
        } catch {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        }
    }

    private func migrateToNewFormat(from data: Data) throws -> Scenario {
        if let scenario = try? JSONDecoder().decode(Scenario.self, from: data) {
            return scenario
        }

        if let events = try? JSONDecoder().decode([Event].self, from: data) {
            let instanceIds = Set(events.map(\.instanceId))
            let deviceRefs = instanceIds.map { id in
                DeviceRef(deviceId: "unknown", instanceId: id)
            }

            return Scenario(
                version: "1.0",
                deviceRefs: deviceRefs,
                events: events
            )
        }

        if let legacyData = try? JSONDecoder().decode(LegacyScenario.self, from: data) {
            return try migrateLegacyScenario(legacyData)
        }

        throw ConversionError.unsupportedFormat
    }

    private func migrateLegacyScenario(_ legacy: LegacyScenario) throws -> Scenario {
        var events: [Event] = []
        var conversionWarnings: [String] = []

        for (index, legacyEvent) in legacy.events.enumerated() {
            let (event, warnings) = try migrateEvent(legacyEvent, index: index)
            events.append(event)
            conversionWarnings.append(contentsOf: warnings)
        }

        // Report conversion warnings — these are honest about what was missing
        if !conversionWarnings.isEmpty && !options.quiet {
            Terminal.printError("Conversion warnings (\(conversionWarnings.count)):")
            for warning in conversionWarnings {
                Terminal.printError("  - \(warning)")
            }
            Terminal.printError("Run `recreplay validate` on the output to see full validation results.")
        }

        let instanceIds = Set(events.map(\.instanceId))
        let deviceRefs = instanceIds.map { id in
            DeviceRef(deviceId: legacy.deviceId ?? "unknown", instanceId: id)
        }

        return Scenario(
            version: "1.0",
            deviceRefs: deviceRefs,
            events: events
        )
    }

    private func migrateEvent(_ legacy: LegacyEvent, index: Int) throws -> (Event, [String]) {
        let type = try migrateEventType(legacy.type)
        var warnings: [String] = []

        // Pass through only what was observed — never synthesize missing fields.
        // Missing fields will cause the validator to flag the trace as invalid,
        // which is correct: broken traces are better than lying traces.

        let instanceId = legacy.instanceId ?? ""
        if legacy.instanceId == nil {
            warnings.append("Event \(index) (t=\(legacy.t), type=\(legacy.type)): missing instanceId — left empty, trace will be invalid")
        }

        // Only pass through requestId if the legacy format actually had one.
        // The legacy format does not track request-response pairing, so we
        // must not invent it. The validator will report missingRequestId.
        let requestId = legacy.requestId
        if type.requiresRequestId && requestId == nil {
            warnings.append("Event \(index) (t=\(legacy.t), type=\(type.rawValue)): missing requestId — not synthesized, trace will be invalid")
        }

        // Pass through serviceUUID only if it was actually observed.
        // Do not fabricate "unknown-service" — that is lying about what was recorded.
        let serviceUUID = legacy.serviceUUID
        if type.requiresGattAddress && serviceUUID == nil {
            warnings.append("Event \(index) (t=\(legacy.t), type=\(type.rawValue)): missing serviceUUID — not synthesized, trace will be invalid")
        }

        let event = Event(
            t: legacy.t,
            type: type,
            instanceId: instanceId,
            requestId: requestId,
            mtu: legacy.mtu,
            serviceUUID: serviceUUID,
            characteristicUUID: legacy.characteristicUUID,
            value: legacy.value,
            status: legacy.status,
            reason: legacy.reason,
            rssi: legacy.rssi
        )

        return (event, warnings)
    }

    private func migrateEventType(_ oldType: String) throws -> EventType {
        switch oldType {
        case "write":
            return .writeRequest
        case "read":
            return .readRequest
        case "mtu":
            return .mtuRequest
        default:
            if let type = EventType(rawValue: oldType) {
                return type
            }
            throw ConversionError.unknownEventType(oldType)
        }
    }
}

enum ConversionError: Error, CustomStringConvertible {
    case unsupportedFormat
    case unknownEventType(String)

    var description: String {
        switch self {
        case .unsupportedFormat:
            return "Unsupported input format"
        case .unknownEventType(let type):
            return "Unknown event type: \(type)"
        }
    }
}

struct LegacyScenario: Codable {
    let deviceId: String?
    let events: [LegacyEvent]
}

struct LegacyEvent: Codable {
    let t: Int
    let type: String
    let instanceId: String?
    let requestId: String?
    let mtu: Int?
    let serviceUUID: String?
    let characteristicUUID: String?
    let value: String?
    let status: String?
    let reason: String?
    let rssi: Int?
}
