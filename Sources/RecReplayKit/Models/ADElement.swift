import Foundation

/// A single Advertising Data (AD) element as observed in BLE advertising packets.
///
/// AD elements are the building blocks of BLE advertising data, defined in
/// Bluetooth Core Specification Supplement (CSS). Each element has a type
/// code and raw data payload.
///
/// ## Common AD Type Codes
/// - `0x01`: Flags
/// - `0x02`: Incomplete List of 16-bit Service UUIDs
/// - `0x03`: Complete List of 16-bit Service UUIDs
/// - `0x08`: Shortened Local Name
/// - `0x09`: Complete Local Name
/// - `0x0A`: TX Power Level
/// - `0x16`: Service Data - 16-bit UUID
/// - `0xFF`: Manufacturer Specific Data
///
/// ## Invariants
/// - `type` is the AD type code (1 byte, 0x00-0xFF)
/// - `data` is hex-encoded raw bytes (no interpretation)
/// - Manufacturer data uses type `0xFF`
public struct ADElement: Codable, Sendable, Equatable, Hashable {
    // MARK: - Common AD Type Constants (Bluetooth CSS)

    /// Flags (0x01)
    public static let typeFlags: Int = 0x01

    /// Incomplete List of 16-bit Service Class UUIDs (0x02)
    public static let typeIncompleteServiceUUIDs16: Int = 0x02

    /// Complete List of 16-bit Service Class UUIDs (0x03)
    public static let typeCompleteServiceUUIDs16: Int = 0x03

    /// Incomplete List of 128-bit Service Class UUIDs (0x06)
    public static let typeIncompleteServiceUUIDs128: Int = 0x06

    /// Complete List of 128-bit Service Class UUIDs (0x07)
    public static let typeCompleteServiceUUIDs128: Int = 0x07

    /// Shortened Local Name (0x08)
    public static let typeShortenedLocalName: Int = 0x08

    /// Complete Local Name (0x09)
    public static let typeCompleteLocalName: Int = 0x09

    /// TX Power Level (0x0A)
    public static let typeTxPowerLevel: Int = 0x0A

    /// Service Data - 16-bit UUID (0x16)
    public static let typeServiceData16: Int = 0x16

    /// Appearance (0x19)
    public static let typeAppearance: Int = 0x19

    /// Manufacturer Specific Data (0xFF)
    public static let typeManufacturerData: Int = 0xFF

    // MARK: - Properties

    public let type: Int
    public let data: String

    // MARK: - Initialization

    public init(type: Int, data: String) {
        self.type = type
        self.data = data
    }
}

// MARK: - Factory Methods

public extension ADElement {
    static func completeLocalName(_ name: String) -> ADElement {
        let hexData = name.data(using: .utf8)?.hexEncodedString() ?? ""
        return ADElement(type: typeCompleteLocalName, data: hexData)
    }

    static func shortenedLocalName(_ name: String) -> ADElement {
        let hexData = name.data(using: .utf8)?.hexEncodedString() ?? ""
        return ADElement(type: typeShortenedLocalName, data: hexData)
    }

    /// Company ID is stored little-endian followed by data
    static func manufacturerData(companyId: UInt16, data: String) -> ADElement {
        let companyIdHex = String(format: "%02X%02X", companyId & 0xFF, (companyId >> 8) & 0xFF)
        return ADElement(type: typeManufacturerData, data: companyIdHex + data)
    }

    static func flags(_ value: UInt8) -> ADElement {
        ADElement(type: typeFlags, data: String(format: "%02X", value))
    }

    static func txPowerLevel(_ dbm: Int8) -> ADElement {
        ADElement(type: typeTxPowerLevel, data: String(format: "%02X", UInt8(bitPattern: dbm)))
    }

    /// Appearance is stored little-endian
    static func appearance(_ value: UInt16) -> ADElement {
        let hex = String(format: "%02X%02X", value & 0xFF, (value >> 8) & 0xFF)
        return ADElement(type: typeAppearance, data: hex)
    }
}

// MARK: - Classification

public extension ADElement {
    var isManufacturerData: Bool {
        type == Self.typeManufacturerData
    }

    var isLocalName: Bool {
        type == Self.typeCompleteLocalName || type == Self.typeShortenedLocalName
    }

    var isServiceUUIDList: Bool {
        type == Self.typeIncompleteServiceUUIDs16 ||
        type == Self.typeCompleteServiceUUIDs16 ||
        type == Self.typeIncompleteServiceUUIDs128 ||
        type == Self.typeCompleteServiceUUIDs128
    }
}

// MARK: - Data Extension

private extension Data {
    func hexEncodedString() -> String {
        map { String(format: "%02X", $0) }.joined()
    }
}
