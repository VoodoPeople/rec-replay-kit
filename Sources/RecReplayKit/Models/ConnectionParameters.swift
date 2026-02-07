import Foundation

// MARK: - Connection Parameters

/// Connection parameters for a BLE device.
///
/// ## Capture Availability
/// - `connectionInterval`, `peripheralLatency`, `supervisionTimeout`: Only available
///   via HCI monitor (LE Connection Complete / LE Connection Update Complete events).
///   Not exposed by BlueZ D-Bus API.
/// - `preferredMTU`: Observable via BlueZ D-Bus (`GattCharacteristic1.MTU` property).
/// - `phyMode`: Only available via HCI monitor (LE PHY Update Complete event).
///   Reserved for future ATT/L2CAP-level recording.
public struct ConnectionParameters: Codable, Sendable, Equatable {
    /// Connection interval range as string (e.g., "15.0...30.0")
    public let connectionInterval: String?

    /// Peripheral latency (number of connection events to skip)
    public let peripheralLatency: Int?

    /// Supervision timeout in seconds
    public let supervisionTimeout: Double?

    /// Preferred MTU size
    public let preferredMTU: Int?

    /// PHY mode in use for the connection.
    /// Populated only when HCI-level recording is available.
    /// Possible values: "1M", "2M", "Coded"
    public let phyMode: String?

    public init(
        connectionInterval: String? = nil,
        peripheralLatency: Int? = nil,
        supervisionTimeout: Double? = nil,
        preferredMTU: Int? = nil,
        phyMode: String? = nil
    ) {
        self.connectionInterval = connectionInterval
        self.peripheralLatency = peripheralLatency
        self.supervisionTimeout = supervisionTimeout
        self.preferredMTU = preferredMTU
        self.phyMode = phyMode
    }
}
