import Foundation

/// Raw advertising data as observed from a BLE device.
///
/// ## GAP Observation Discipline
/// - Only PDU type and raw AD elements are stored
/// - No inferred fields (connectable, scannable, decoded names)
/// - Manufacturer data is represented as AD element type 0xFF
/// - Interpretation is deferred to player or tooling
///
/// ## Common PDU Types
/// - `ADV_IND`: Connectable undirected advertising
/// - `ADV_DIRECT_IND`: Connectable directed advertising
/// - `ADV_NONCONN_IND`: Non-connectable undirected advertising
/// - `ADV_SCAN_IND`: Scannable undirected advertising
/// - `SCAN_RSP`: Scan response
public struct RawAdvertisementData: Codable, Sendable, Equatable {
    // MARK: - PDU Type Constants (GAP)

    /// Connectable undirected advertising
    public static let pduTypeAdvInd = "ADV_IND"

    /// Connectable directed advertising
    public static let pduTypeAdvDirectInd = "ADV_DIRECT_IND"

    /// Non-connectable undirected advertising
    public static let pduTypeAdvNonconnInd = "ADV_NONCONN_IND"

    /// Scannable undirected advertising
    public static let pduTypeAdvScanInd = "ADV_SCAN_IND"

    /// Scan response
    public static let pduTypeScanRsp = "SCAN_RSP"

    // MARK: - Properties

    /// Observed GAP PDU type.
    ///
    /// Common values:
    /// - `ADV_IND`: Connectable undirected advertising
    /// - `ADV_DIRECT_IND`: Connectable directed advertising
    /// - `ADV_NONCONN_IND`: Non-connectable undirected advertising
    /// - `ADV_SCAN_IND`: Scannable undirected advertising
    /// - `SCAN_RSP`: Scan response
    public let pduType: String
    public let adElements: [ADElement]

    // MARK: - Initialization

    public init(pduType: String, adElements: [ADElement]) {
        self.pduType = pduType
        self.adElements = adElements
    }
}

// MARK: - Convenience Methods

public extension RawAdvertisementData {
    func element(ofType type: Int) -> ADElement? {
        adElements.first { $0.type == type }
    }

    func elements(ofType type: Int) -> [ADElement] {
        adElements.filter { $0.type == type }
    }

    func hasElement(ofType type: Int) -> Bool {
        adElements.contains { $0.type == type }
    }

    var manufacturerData: ADElement? {
        element(ofType: ADElement.typeManufacturerData)
    }

    var localNameElement: ADElement? {
        element(ofType: ADElement.typeCompleteLocalName) ??
        element(ofType: ADElement.typeShortenedLocalName)
    }

    var isConnectable: Bool {
        pduType == Self.pduTypeAdvInd || pduType == Self.pduTypeAdvDirectInd
    }

    var isScanResponse: Bool {
        pduType == Self.pduTypeScanRsp
    }
}

// MARK: - Factory Methods

public extension RawAdvertisementData {
    static func connectable(adElements: [ADElement]) -> RawAdvertisementData {
        RawAdvertisementData(pduType: pduTypeAdvInd, adElements: adElements)
    }

    static func nonConnectable(adElements: [ADElement]) -> RawAdvertisementData {
        RawAdvertisementData(pduType: pduTypeAdvNonconnInd, adElements: adElements)
    }

    static func scanResponse(adElements: [ADElement]) -> RawAdvertisementData {
        RawAdvertisementData(pduType: pduTypeScanRsp, adElements: adElements)
    }
}
