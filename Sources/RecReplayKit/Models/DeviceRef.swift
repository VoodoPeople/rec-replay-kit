import Foundation

/// A reference to a device definition within a scenario.
///
/// Device references link static device definitions to scenario instances.
/// This enables reuse of device definitions across multiple scenarios
/// while maintaining unique instance identities within each scenario.
///
/// ## Example
/// ```json
/// {
///   "deviceId": "snow-v1",
///   "instanceId": "device-0"
/// }
/// ```
///
/// ## Invariants
/// - `deviceId` must match a `DeviceDefinition.id`
/// - `instanceId` must be unique within a scenario
/// - All events in the scenario reference instances via `instanceId`
public struct DeviceRef: Codable, Sendable, Equatable, Hashable {
    /// Reference to a DeviceDefinition.id
    ///
    /// This links to a static device definition that contains:
    /// - Advertisement data
    /// - GATT profile
    /// - Security configuration
    /// - Connection parameters
    public let deviceId: String

    /// Unique instance identifier within the scenario.
    ///
    /// Events reference this value to associate with a specific device instance.
    /// Multiple instances can reference the same deviceId if the scenario
    /// involves multiple identical devices.
    public let instanceId: String

    public init(deviceId: String, instanceId: String) {
        self.deviceId = deviceId
        self.instanceId = instanceId
    }
}

// MARK: - Identifiable

extension DeviceRef: Identifiable {
    public var id: String { instanceId }
}
