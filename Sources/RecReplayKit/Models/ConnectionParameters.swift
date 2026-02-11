import Foundation

// MARK: - Connection Parameters

/// Connection parameters for a BLE device.
///
/// ## Level-Scoped Design
/// - **GATT level**: Only `preferredMTU` is available (from BlueZ D-Bus
///   `GattCharacteristic1.MTU` property after connection).
/// - **HCI level** (`--level att` / `--level full`): `hci` struct is populated
///   with connection interval, peripheral latency, supervision timeout, and PHY mode —
///   all parsed from HCI LE Connection Complete / LE Connection Update Complete events.
///
/// GATT-level consumers see only `preferredMTU`. The nested `hci` struct is `nil`.
public struct ConnectionParameters: Codable, Sendable, Equatable {
    // -- GATT level (always available) --

    /// Preferred / negotiated MTU size.
    /// BlueZ source: `GattCharacteristic1.MTU` property.
    public let preferredMTU: Int?

    // -- HCI level (--level att or deeper) --

    /// HCI-level connection detail. Present only with HCI-level recording.
    /// Contains negotiated connection parameters from LE Connection Complete /
    /// LE Connection Update Complete events.
    public let hci: HCIConnectionDetail?

    public init(
        preferredMTU: Int? = nil,
        hci: HCIConnectionDetail? = nil
    ) {
        self.preferredMTU = preferredMTU
        self.hci = hci
    }
}

// MARK: - HCI Connection Detail

/// HCI-level connection parameter detail.
///
/// Populated from LE Connection Complete and LE Connection Update Complete
/// HCI events. Only available when recording at `--level att` or deeper.
///
/// ## Example JSON
/// ```json
/// "hci": {
///   "connectionInterval": "15.0...30.0",
///   "peripheralLatency": 0,
///   "supervisionTimeout": 6.0,
///   "phyMode": "2M"
/// }
/// ```
public struct HCIConnectionDetail: Codable, Sendable, Equatable {
    /// Connection interval range as string (e.g., "15.0...30.0"), in milliseconds.
    /// From LE Connection Complete / LE Connection Update Complete.
    public let connectionInterval: String?

    /// Peripheral latency (number of connection events the peripheral may skip).
    /// From LE Connection Complete / LE Connection Update Complete.
    public let peripheralLatency: Int?

    /// Supervision timeout in seconds.
    /// From LE Connection Complete / LE Connection Update Complete.
    public let supervisionTimeout: Double?

    /// PHY mode in use for the connection.
    /// From LE PHY Update Complete event.
    /// Possible values: "1M", "2M", "Coded"
    public let phyMode: String?

    public init(
        connectionInterval: String? = nil,
        peripheralLatency: Int? = nil,
        supervisionTimeout: Double? = nil,
        phyMode: String? = nil
    ) {
        self.connectionInterval = connectionInterval
        self.peripheralLatency = peripheralLatency
        self.supervisionTimeout = supervisionTimeout
        self.phyMode = phyMode
    }
}
