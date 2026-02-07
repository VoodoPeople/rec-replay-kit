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
/// ## Invariants
/// - Device definitions are immutable reference data
/// - `id` must be unique across all device definitions
/// - Referenced by `DeviceRef.deviceId` in scenarios
public struct DeviceDefinition: Codable, Sendable, Equatable {
    public let id: String
    public let advertisement: RawAdvertisementData

    /// Scan response data, if the device responds to active scans.
    /// In BLE, a device can send both advertisement PDUs (ADV_IND) and
    /// scan response PDUs (SCAN_RSP) with different AD elements.
    /// This field captures the scan response separately from the advertisement.
    /// Available when HCI-level recording captures both PDU types.
    public let scanResponse: RawAdvertisementData?

    public let gattProfile: GattProfile?
    public let security: SecurityConfiguration?
    public let connectionParameters: ConnectionParameters?

    public init(
        id: String,
        advertisement: RawAdvertisementData,
        scanResponse: RawAdvertisementData? = nil,
        gattProfile: GattProfile? = nil,
        security: SecurityConfiguration? = nil,
        connectionParameters: ConnectionParameters? = nil
    ) {
        self.id = id
        self.advertisement = advertisement
        self.scanResponse = scanResponse
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
}
