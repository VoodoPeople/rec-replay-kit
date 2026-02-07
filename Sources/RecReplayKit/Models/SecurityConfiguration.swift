import Foundation

// MARK: - Security Configuration

/// Security configuration for a BLE device.
///
/// ## Capture Availability
/// - `authenticationRequired`, `securityLevel`: Partially inferable from GATT characteristic
///   security flags via BlueZ D-Bus. Fully observable via HCI monitor (SMP events).
/// - `encryptionKeySize`: Only available via HCI monitor or mgmt API.
/// - `pairingMethod`, `ioCapability`, `bondingEnabled`: Only available via HCI monitor
///   (SMP Pairing Request/Response). Reserved for future ATT/L2CAP-level recording.
public struct SecurityConfiguration: Codable, Sendable, Equatable {
    /// Whether authentication is required
    public let authenticationRequired: Bool?

    /// Whether authorization is required
    public let authorizationRequired: Bool?

    /// Encryption key size in bytes
    public let encryptionKeySize: Int?

    /// Security level (e.g., "none", "unauthenticated", "authenticated", "secure_connections")
    public let securityLevel: String?

    /// Pairing method used or required.
    /// Populated only when SMP-level recording is available.
    /// Possible values: "just_works", "passkey_entry", "numeric_comparison", "oob"
    public let pairingMethod: String?

    /// IO capability of the device as observed during pairing.
    /// Populated only when SMP-level recording is available.
    /// Possible values: "display_only", "display_yes_no", "keyboard_only",
    /// "no_input_no_output", "keyboard_display"
    public let ioCapability: String?

    /// Whether bonding (long-term key storage) is enabled.
    /// Populated only when SMP-level recording is available.
    public let bondingEnabled: Bool?

    public init(
        authenticationRequired: Bool? = nil,
        authorizationRequired: Bool? = nil,
        encryptionKeySize: Int? = nil,
        securityLevel: String? = nil,
        pairingMethod: String? = nil,
        ioCapability: String? = nil,
        bondingEnabled: Bool? = nil
    ) {
        self.authenticationRequired = authenticationRequired
        self.authorizationRequired = authorizationRequired
        self.encryptionKeySize = encryptionKeySize
        self.securityLevel = securityLevel
        self.pairingMethod = pairingMethod
        self.ioCapability = ioCapability
        self.bondingEnabled = bondingEnabled
    }
}
