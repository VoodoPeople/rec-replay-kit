import Foundation

// MARK: - Security Configuration

/// Security configuration for a BLE device.
///
/// ## Level-Scoped Detail
/// - **GATT level**: `authenticationRequired`, `authorizationRequired`, `securityLevel`
///   are partially inferable from BlueZ D-Bus characteristic security flags.
/// - **ATT level**: `encryptionKeySize` becomes available via HCI monitor / mgmt API.
/// - **Full level**: `smp` struct is populated from SMP Pairing Request/Response
///   PDUs (pairing method, IO capabilities, bonding flags).
///
/// GATT-level consumers only see the top-level fields. The nested `smp` struct
/// is `nil` unless SMP-level data was captured.
public struct SecurityConfiguration: Codable, Sendable, Equatable {
    // -- GATT level (always present when capturable) --

    /// Whether authentication is required
    public let authenticationRequired: Bool?

    /// Whether authorization is required
    public let authorizationRequired: Bool?

    /// Encryption key size in bytes.
    /// Available via HCI monitor or mgmt API (ATT level or deeper).
    public let encryptionKeySize: Int?

    /// Security level (e.g., "none", "unauthenticated", "authenticated", "secure_connections")
    public let securityLevel: String?

    // -- Full level (--level full) --

    /// SMP (Security Manager Protocol) pairing detail.
    /// Present only when recording at `--level full` with SMP capture.
    public let smp: SMPDetail?

    public init(
        authenticationRequired: Bool? = nil,
        authorizationRequired: Bool? = nil,
        encryptionKeySize: Int? = nil,
        securityLevel: String? = nil,
        smp: SMPDetail? = nil
    ) {
        self.authenticationRequired = authenticationRequired
        self.authorizationRequired = authorizationRequired
        self.encryptionKeySize = encryptionKeySize
        self.securityLevel = securityLevel
        self.smp = smp
    }
}

// MARK: - SMP Detail

/// SMP (Security Manager Protocol) pairing detail.
///
/// Populated only when recording at `--level full`, parsed from SMP Pairing
/// Request/Response PDUs captured on L2CAP CID 0x0006.
///
/// ## Example JSON
/// ```json
/// "smp": {
///   "pairingMethod": "just_works",
///   "ioCapability": "no_input_no_output",
///   "bondingEnabled": true
/// }
/// ```
public struct SMPDetail: Codable, Sendable, Equatable {
    /// Pairing method used or required.
    /// Possible values: "just_works", "passkey_entry", "numeric_comparison", "oob"
    public let pairingMethod: String?

    /// IO capability of the device as observed during SMP pairing.
    /// Possible values: "display_only", "display_yes_no", "keyboard_only",
    /// "no_input_no_output", "keyboard_display"
    public let ioCapability: String?

    /// Whether bonding (long-term key storage) is enabled.
    public let bondingEnabled: Bool?

    public init(
        pairingMethod: String? = nil,
        ioCapability: String? = nil,
        bondingEnabled: Bool? = nil
    ) {
        self.pairingMethod = pairingMethod
        self.ioCapability = ioCapability
        self.bondingEnabled = bondingEnabled
    }
}
