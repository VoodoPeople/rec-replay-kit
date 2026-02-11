import Foundation

// MARK: - Advertisement Data (Level-Scoped)

/// Advertisement data observed for a BLE device.
///
/// ## Level-Scoped Design
/// - **GATT level** (`--level gatt`): Application-level parsed properties — `localName`,
///   `serviceUUIDs`, `manufacturerData`, `txPowerLevel`, `appearance`, `isConnectable`.
///   These map directly to CoreBluetooth `CBAdvertisementData` keys and are what
///   BlueZ D-Bus exposes via `Device1` properties.
/// - **HCI level** (`--level att` / `--level full`): Raw protocol data in `raw` struct —
///   `pduType`, `adElements`. Optional `rawScanResponse` for separate scan response PDU.
///
/// At GATT level the easy case stays easy: clean strings, UUIDs, and booleans.
/// At HCI level you dig into `raw` for the protocol-level blobs.
///
/// ## Example JSON
/// ```json
/// // GATT level (clean, no blobs):
/// { "localName": "Snow Core [C34]",
///   "serviceUUIDs": ["0000180F-0000-1000-8000-00805F9B34FB"],
///   "isConnectable": true, "txPowerLevel": 4 }
///
/// // HCI level (adds raw protocol detail):
/// { "localName": "Snow Core [C34]",
///   "serviceUUIDs": ["0000180F-0000-1000-8000-00805F9B34FB"],
///   "isConnectable": true, "txPowerLevel": 4,
///   "raw": { "pduType": "ADV_IND",
///            "adElements": [{"type":1,"data":"06"}, {"type":9,"data":"536E6F77..."}] },
///   "rawScanResponse": { "pduType": "SCAN_RSP",
///                         "adElements": [{"type":9,"data":"536E6F77..."}] } }
/// ```
public struct AdvertisementData: Codable, Sendable, Equatable {
    // MARK: - GATT Level (Application-Level Properties)
    // Available from BlueZ D-Bus at --level gatt.
    // Maps to CoreBluetooth CBAdvertisementData keys.

    /// Advertised local name (Complete or Shortened Local Name).
    /// BlueZ source: `Device1.Name` or `Device1.Alias`.
    /// CoreBluetooth: `CBAdvertisementDataLocalNameKey`.
    public let localName: String?

    /// Advertised service UUIDs.
    /// BlueZ source: `Device1.UUIDs`.
    /// CoreBluetooth: `CBAdvertisementDataServiceUUIDsKey`.
    public let serviceUUIDs: [String]?

    /// Manufacturer-specific data, hex-encoded.
    /// Company ID (2 bytes LE) followed by payload, e.g., "3905FF416C65636B2A00".
    /// BlueZ source: `Device1.ManufacturerData` (dict of company_id → bytes).
    /// CoreBluetooth: `CBAdvertisementDataManufacturerDataKey`.
    public let manufacturerData: String?

    /// Service data, as a dictionary of service UUID → hex-encoded data.
    /// BlueZ source: `Device1.ServiceData` (dict of UUID → bytes).
    /// CoreBluetooth: `CBAdvertisementDataServiceDataKey`.
    public let serviceData: [String: String]?

    /// TX power level in dBm.
    /// BlueZ source: `Device1.TxPower`.
    /// CoreBluetooth: `CBAdvertisementDataTxPowerLevelKey`.
    public let txPowerLevel: Int?

    /// GAP Appearance value.
    /// BlueZ source: `Device1.Appearance`.
    public let appearance: Int?

    /// Whether the device is connectable.
    /// BlueZ source: inferred from `Device1` presence in scan results / connect success.
    /// CoreBluetooth: `CBAdvertisementDataIsConnectable`.
    public let isConnectable: Bool?

    // MARK: - HCI Level (Raw Protocol Detail)

    /// Raw advertisement PDU as captured from HCI monitor.
    /// Contains the exact observed `pduType` and raw `adElements`.
    /// Present only when recording at `--level att` or deeper.
    /// `nil` for GATT-only recordings.
    public let raw: RawAdvertisementPDU?

    /// Raw scan response PDU, if the device responds to active scans.
    /// In BLE, a device sends ADV PDUs and may also send SCAN_RSP PDUs
    /// with additional AD elements. Only HCI monitor can distinguish them.
    /// Present only when HCI-level recording captures both PDU types.
    public let rawScanResponse: RawAdvertisementPDU?

    // MARK: - Initialization

    public init(
        localName: String? = nil,
        serviceUUIDs: [String]? = nil,
        manufacturerData: String? = nil,
        serviceData: [String: String]? = nil,
        txPowerLevel: Int? = nil,
        appearance: Int? = nil,
        isConnectable: Bool? = nil,
        raw: RawAdvertisementPDU? = nil,
        rawScanResponse: RawAdvertisementPDU? = nil
    ) {
        self.localName = localName
        self.serviceUUIDs = serviceUUIDs
        self.manufacturerData = manufacturerData
        self.serviceData = serviceData
        self.txPowerLevel = txPowerLevel
        self.appearance = appearance
        self.isConnectable = isConnectable
        self.raw = raw
        self.rawScanResponse = rawScanResponse
    }
}

// MARK: - Convenience Methods

public extension AdvertisementData {
    /// Whether advertisement has any raw HCI-level data.
    var hasRawData: Bool {
        raw != nil
    }

    /// Whether advertisement has a scan response.
    var hasScanResponse: Bool {
        rawScanResponse != nil
    }
}

// MARK: - Raw Advertisement PDU (HCI Level)

/// Raw advertisement PDU as captured from HCI monitor.
///
/// Contains the exact observed GAP PDU type and raw AD elements as they
/// appeared on the wire. This is the truthful HCI-level representation —
/// no reconstruction, no inference.
///
/// ## Common PDU Types
/// - `ADV_IND`: Connectable undirected advertising
/// - `ADV_DIRECT_IND`: Connectable directed advertising
/// - `ADV_NONCONN_IND`: Non-connectable undirected advertising
/// - `ADV_SCAN_IND`: Scannable undirected advertising
/// - `SCAN_RSP`: Scan response
public struct RawAdvertisementPDU: Codable, Sendable, Equatable {
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
    public let pduType: String

    /// Raw AD elements as observed in the advertising PDU.
    public let adElements: [ADElement]

    // MARK: - Initialization

    public init(pduType: String, adElements: [ADElement]) {
        self.pduType = pduType
        self.adElements = adElements
    }
}

// MARK: - RawAdvertisementPDU Convenience

public extension RawAdvertisementPDU {
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

// MARK: - RawAdvertisementPDU Factory Methods

public extension RawAdvertisementPDU {
    static func connectable(adElements: [ADElement]) -> RawAdvertisementPDU {
        RawAdvertisementPDU(pduType: pduTypeAdvInd, adElements: adElements)
    }

    static func nonConnectable(adElements: [ADElement]) -> RawAdvertisementPDU {
        RawAdvertisementPDU(pduType: pduTypeAdvNonconnInd, adElements: adElements)
    }

    static func scanResponse(adElements: [ADElement]) -> RawAdvertisementPDU {
        RawAdvertisementPDU(pduType: pduTypeScanRsp, adElements: adElements)
    }
}
