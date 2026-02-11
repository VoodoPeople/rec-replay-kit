import Foundation

/// A static BLE device definition containing immutable device characteristics.
///
/// Device definitions capture the static properties of a BLE device that
/// don't change during a scenario. They are stored separately from scenario
/// traces and referenced by `deviceRef` in scenarios.
///
/// ## Static vs Dynamic Separation
/// - **Static (in DeviceDefinition):** Advertisement snapshot, GATT profile,
///   security configuration, connection parameters
/// - **Dynamic (in Scenario events):** Connection state changes, notifications,
///   read/write operations, RSSI changes
///
/// ## Level-Scoped Design
/// At GATT level, `advertisement` contains parsed application-level properties
/// (localName, serviceUUIDs, etc.). At HCI level, `advertisement.raw` contains
/// the truthful protocol-level data (pduType, adElements).
///
/// ## Invariants
/// - Device definitions are immutable reference data
/// - `id` must be unique across all device definitions
/// - Referenced by `DeviceRef.deviceId` in scenarios
public struct DeviceDefinition: Codable, Sendable, Equatable {
    public let id: String

    /// Advertisement data observed for this device.
    ///
    /// At GATT level: contains parsed properties (localName, serviceUUIDs,
    /// manufacturerData, isConnectable, etc.).
    /// At HCI level: additionally contains `raw` with pduType and adElements,
    /// and optionally `rawScanResponse` for the scan response PDU.
    public let advertisement: AdvertisementData?

    public let gattProfile: GattProfile?
    public let security: SecurityConfiguration?
    public let connectionParameters: ConnectionParameters?

    public init(
        id: String,
        advertisement: AdvertisementData? = nil,
        gattProfile: GattProfile? = nil,
        security: SecurityConfiguration? = nil,
        connectionParameters: ConnectionParameters? = nil
    ) {
        self.id = id
        self.advertisement = advertisement
        self.gattProfile = gattProfile
        self.security = security
        self.connectionParameters = connectionParameters
    }
}

// MARK: - Identifiable

extension DeviceDefinition: Identifiable {}

// MARK: - Convenience Methods

public extension DeviceDefinition {
    var preferredMTU: Int? {
        connectionParameters?.preferredMTU ?? gattProfile?.mtu
    }

    var requiresAuthentication: Bool {
        security?.authenticationRequired ?? false
    }

    var requiresEncryption: Bool {
        guard let security = security else { return false }
        return security.securityLevel != nil && security.securityLevel != "none"
    }

    /// Device local name from advertisement data.
    var localName: String? {
        advertisement?.localName
    }

    /// Whether this device has raw HCI-level advertisement data.
    var hasRawAdvertisement: Bool {
        advertisement?.hasRawData ?? false
    }
}
