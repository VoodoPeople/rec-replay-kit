import Foundation

/// A recorded BLE scenario containing device references and an event timeline.
///
/// Scenarios represent a complete recording of BLE interactions that can be replayed
/// for testing. They separate static device definitions from dynamic event traces.
///
/// ## Structure
/// - `deviceRefs`: References to static device definitions used in this scenario
/// - `events`: Single ordered timeline of all events across all devices
///
/// ## Invariants
/// - Static device data is never embedded in scenarios (referenced via `deviceRefs`)
/// - Exactly one global `events` timeline (not per-device)
/// - All events must reference a valid `instanceId` from `deviceRefs`
///
/// ## Example
/// ```json
/// {
///   "version": "1.0",
///   "deviceRefs": [
///     { "deviceId": "snow-v1", "instanceId": "device-0" }
///   ],
///   "events": [
///     { "t": 0, "type": "advertising_start", "instanceId": "device-0" },
///     { "t": 500, "type": "connect", "instanceId": "device-0" }
///   ]
/// }
/// ```
public struct Scenario: Codable, Sendable, Equatable {
    /// Schema version for forward compatibility
    public let version: String?

    /// Recording metadata describing how, when, and by what platform this
    /// scenario was captured. Optional — hand-authored scenarios may omit this.
    public let metadata: ScenarioMetadata?

    /// References to static device definitions used in this scenario.
    ///
    /// Each reference links a `deviceId` (pointing to a DeviceDefinition)
    /// to an `instanceId` (used by events to identify the device).
    public let deviceRefs: [DeviceRef]

    /// Single ordered timeline of all events.
    ///
    /// Events are ordered by timestamp (`t`) and reference devices via `instanceId`.
    /// This is a unified timeline - not separate per-device timelines.
    public let events: [Event]

    public init(
        version: String? = nil,
        metadata: ScenarioMetadata? = nil,
        deviceRefs: [DeviceRef],
        events: [Event]
    ) {
        self.version = version
        self.metadata = metadata
        self.deviceRefs = deviceRefs
        self.events = events
    }
}

// MARK: - Scenario Metadata

/// Metadata about a recorded scenario: recording platform, capabilities, and validity.
///
/// Populated by the recorder at finalization time. Omitted for hand-authored scenarios.
///
/// ## Example
/// ```json
/// {
///   "recordedAt": "2026-02-06T14:30:00Z",
///   "recorderVersion": "1.0.0",
///   "platform": "bluez_hybrid",
///   "platformCapability": "full",
///   "validity": "valid"
/// }
/// ```
public struct ScenarioMetadata: Codable, Sendable, Equatable {
    /// ISO 8601 timestamp of when the recording was captured
    public let recordedAt: String?

    /// Version of the recorder tool that produced this scenario
    public let recorderVersion: String?

    /// Recording platform identifier.
    /// Possible values: "bluez_dbus", "bluez_hybrid", "esp32", "stm32", "manual"
    public let platform: String?

    /// Platform capability level for this recording.
    /// - "full": All schema fields are directly observable on this platform
    /// - "degraded": Some fields were inferred, reconstructed, or unavailable
    public let platformCapability: String?

    /// Trace validity assessment from the recorder.
    /// - "valid": All invariants satisfied
    /// - "degraded": Platform limitations caused some fields to be inferred
    /// - "invalid": Structural errors detected (orphan responses, etc.)
    public let validity: String?

    /// List of validation/recording errors or warnings, if any
    public let errors: [String]?

    public init(
        recordedAt: String? = nil,
        recorderVersion: String? = nil,
        platform: String? = nil,
        platformCapability: String? = nil,
        validity: String? = nil,
        errors: [String]? = nil
    ) {
        self.recordedAt = recordedAt
        self.recorderVersion = recorderVersion
        self.platform = platform
        self.platformCapability = platformCapability
        self.validity = validity
        self.errors = errors
    }
}

// MARK: - Convenience Methods

public extension Scenario {
    /// Returns events sorted by timestamp
    var sortedEvents: [Event] {
        events.sorted { $0.t < $1.t }
    }

    /// Returns the duration of the scenario in milliseconds
    var durationMs: Int {
        events.map(\.t).max() ?? 0
    }

    /// Returns the duration of the scenario in seconds
    var durationSeconds: TimeInterval {
        TimeInterval(durationMs) / 1000.0
    }

    /// Returns all unique instance IDs referenced in events
    var eventInstanceIds: Set<String> {
        Set(events.map(\.instanceId))
    }

    /// Returns all instance IDs defined in device refs
    var definedInstanceIds: Set<String> {
        Set(deviceRefs.map(\.instanceId))
    }

    /// Returns events for a specific device instance
    func events(for instanceId: String) -> [Event] {
        events.filter { $0.instanceId == instanceId }
    }

    /// Returns the device ref for a given instance ID
    func deviceRef(for instanceId: String) -> DeviceRef? {
        deviceRefs.first { $0.instanceId == instanceId }
    }

    /// Checks if all event instanceIds have corresponding deviceRefs
    var hasValidInstanceReferences: Bool {
        eventInstanceIds.isSubset(of: definedInstanceIds)
    }
}

// MARK: - Validation

public extension Scenario {
    /// Validation errors for scenario structure
    enum ValidationError: Error, Equatable {
        case emptyDeviceRefs
        case duplicateInstanceId(String)
        case undefinedInstanceId(String)
    }

    /// Validates the scenario structure (not event content - use EventValidator for that)
    func validateStructure() throws {
        // Rule: At least one device ref
        guard !deviceRefs.isEmpty else {
            throw ValidationError.emptyDeviceRefs
        }

        // Rule: No duplicate instance IDs
        var seenInstanceIds = Set<String>()
        for ref in deviceRefs {
            guard !seenInstanceIds.contains(ref.instanceId) else {
                throw ValidationError.duplicateInstanceId(ref.instanceId)
            }
            seenInstanceIds.insert(ref.instanceId)
        }

        // Rule: All event instanceIds must reference a defined device
        for event in events {
            guard definedInstanceIds.contains(event.instanceId) else {
                throw ValidationError.undefinedInstanceId(event.instanceId)
            }
        }
    }
}
