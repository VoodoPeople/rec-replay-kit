import Foundation

/// A single BLE event in a recorded scenario timeline.
///
/// ## Invariants
/// - All events MUST have a non-empty `instanceId`
/// - ATT request/response events MUST have a `requestId`
/// - GATT events (read, write, notify, indicate) MUST have both `serviceUUID` and `characteristicUUID`
/// - MTU events MUST NOT have GATT addressing
///
/// ## Level-Scoped Detail
/// Protocol-layer detail is grouped into optional nested structs that correspond
/// to recording depth (see Recording Levels in the plan):
/// - **GATT level** (`--level gatt`): Only the top-level fields are populated.
///   Clean UUIDs, values, and timing. Sufficient for CoreBluetooth mocking.
/// - **ATT level** (`--level att`): `att` struct is populated with opcodes,
///   handles, error codes, and raw PDU bytes.
/// - **Full level** (`--level full`): `att` + `l2cap` structs are populated,
///   adding channel IDs and raw L2CAP frame bytes.
public struct Event: Codable, Sendable, Equatable {
    // MARK: - Required Fields

    public let t: Int
    public let type: EventType
    public let instanceId: String

    // MARK: - ATT Request/Response Linkage

    public let requestId: String?
    public let mtu: Int?

    // MARK: - GATT-Level Addressing (UUID Path)

    public let serviceUUID: String?
    public let characteristicUUID: String?

    // MARK: - Payload and Metadata

    public let value: String?
    public let status: String?
    public let reason: String?
    public let rssi: Int?

    // MARK: - Protocol Layer Detail (Level-Scoped)

    /// ATT (Attribute Protocol) layer detail.
    /// Present when recording at `--level att` or `--level full`.
    /// `nil` for GATT-only recordings.
    public let att: ATTDetail?

    /// L2CAP (Logical Link Control & Adaptation) layer detail.
    /// Present when recording at `--level full`.
    /// `nil` for GATT-only or ATT-only recordings.
    public let l2cap: L2CAPDetail?

    // MARK: - Initialization

    public init(
        t: Int,
        type: EventType,
        instanceId: String,
        requestId: String? = nil,
        mtu: Int? = nil,
        serviceUUID: String? = nil,
        characteristicUUID: String? = nil,
        value: String? = nil,
        status: String? = nil,
        reason: String? = nil,
        rssi: Int? = nil,
        att: ATTDetail? = nil,
        l2cap: L2CAPDetail? = nil
    ) {
        self.t = t
        self.type = type
        self.instanceId = instanceId
        self.requestId = requestId
        self.mtu = mtu
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
        self.value = value
        self.status = status
        self.reason = reason
        self.rssi = rssi
        self.att = att
        self.l2cap = l2cap
    }
}

// MARK: - ATT Detail

/// ATT (Attribute Protocol) layer detail for an event.
///
/// Populated when recording at `--level att` or deeper. Groups all ATT-specific
/// fields into a single namespace so GATT-level consumers can ignore it entirely.
///
/// ## Example JSON
/// ```json
/// "att": {
///   "opcode": 27,
///   "handle": 15,
///   "rawPDU": "1B000F4E"
/// }
/// ```
public struct ATTDetail: Codable, Sendable, Equatable {
    /// ATT protocol opcode (e.g., 0x0A = Read Request, 0x0B = Read Response,
    /// 0x12 = Write Request, 0x1B = Handle Value Notification, 0x1D = Handle Value Indication).
    public let opcode: Int?

    /// ATT attribute handle (16-bit). Maps to a specific attribute in the GATT database.
    /// Complements the GATT-level UUID addressing on the parent event.
    public let handle: Int?

    /// ATT error code for error responses.
    /// Standard codes: 0x01 = Invalid Handle, 0x02 = Read Not Permitted,
    /// 0x05 = Insufficient Authentication, 0x06 = Request Not Supported,
    /// 0x0A = Attribute Not Found, 0x0E = Unlikely Error, etc.
    public let errorCode: Int?

    /// Raw hex-encoded ATT PDU bytes as observed on the wire.
    /// Full ATT PDU including opcode and payload for forensic analysis or bit-exact replay.
    public let rawPDU: String?

    public init(
        opcode: Int? = nil,
        handle: Int? = nil,
        errorCode: Int? = nil,
        rawPDU: String? = nil
    ) {
        self.opcode = opcode
        self.handle = handle
        self.errorCode = errorCode
        self.rawPDU = rawPDU
    }
}

// MARK: - L2CAP Detail

/// L2CAP (Logical Link Control & Adaptation Protocol) layer detail for an event.
///
/// Populated when recording at `--level full`. Groups all L2CAP-specific fields
/// so ATT-level and GATT-level consumers can ignore it entirely.
///
/// ## Example JSON
/// ```json
/// "l2cap": {
///   "cid": 4,
///   "rawFrame": "0400070000041B000F4E"
/// }
/// ```
public struct L2CAPDetail: Codable, Sendable, Equatable {
    /// L2CAP channel ID (CID) over which this event was transported.
    /// Standard CIDs: 0x0004 = ATT, 0x0005 = LE Signaling, 0x0006 = SMP.
    /// Dynamic CIDs (≥ 0x0040) are used for L2CAP CoC channels.
    public let cid: Int?

    /// Raw hex-encoded L2CAP frame bytes including the L2CAP header.
    /// For forensic analysis and bit-exact protocol replay.
    public let rawFrame: String?

    public init(
        cid: Int? = nil,
        rawFrame: String? = nil
    ) {
        self.cid = cid
        self.rawFrame = rawFrame
    }
}

// MARK: - Factory Methods

public extension Event {
    static func advertisingStart(at t: Int, instanceId: String) -> Event {
        Event(t: t, type: .advertisingStart, instanceId: instanceId)
    }

    static func advertisingStop(at t: Int, instanceId: String) -> Event {
        Event(t: t, type: .advertisingStop, instanceId: instanceId)
    }

    static func advertisingUpdate(at t: Int, instanceId: String) -> Event {
        Event(t: t, type: .advertisingUpdate, instanceId: instanceId)
    }

    static func connect(at t: Int, instanceId: String) -> Event {
        Event(t: t, type: .connect, instanceId: instanceId)
    }

    static func disconnect(at t: Int, instanceId: String, reason: String? = nil) -> Event {
        Event(t: t, type: .disconnect, instanceId: instanceId, reason: reason)
    }

    static func rssi(at t: Int, instanceId: String, rssi: Int) -> Event {
        Event(t: t, type: .rssi, instanceId: instanceId, rssi: rssi)
    }

    static func mtuRequest(at t: Int, instanceId: String, requestId: String, mtu: Int) -> Event {
        Event(t: t, type: .mtuRequest, instanceId: instanceId, requestId: requestId, mtu: mtu)
    }

    static func mtuResponse(
        at t: Int,
        instanceId: String,
        requestId: String,
        mtu: Int,
        status: String = "success"
    ) -> Event {
        Event(t: t, type: .mtuResponse, instanceId: instanceId, requestId: requestId, mtu: mtu, status: status)
    }

    static func readRequest(
        at t: Int,
        instanceId: String,
        requestId: String,
        serviceUUID: String,
        characteristicUUID: String
    ) -> Event {
        Event(
            t: t,
            type: .readRequest,
            instanceId: instanceId,
            requestId: requestId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID
        )
    }

    static func readResponse(
        at t: Int,
        instanceId: String,
        requestId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String,
        status: String = "success"
    ) -> Event {
        Event(
            t: t,
            type: .readResponse,
            instanceId: instanceId,
            requestId: requestId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            value: value,
            status: status
        )
    }

    static func writeRequest(
        at t: Int,
        instanceId: String,
        requestId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String
    ) -> Event {
        Event(
            t: t,
            type: .writeRequest,
            instanceId: instanceId,
            requestId: requestId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            value: value
        )
    }

    static func writeResponse(
        at t: Int,
        instanceId: String,
        requestId: String,
        status: String = "success"
    ) -> Event {
        Event(t: t, type: .writeResponse, instanceId: instanceId, requestId: requestId, status: status)
    }

    static func notify(
        at t: Int,
        instanceId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String
    ) -> Event {
        Event(
            t: t,
            type: .notify,
            instanceId: instanceId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            value: value
        )
    }

    static func indicate(
        at t: Int,
        instanceId: String,
        serviceUUID: String,
        characteristicUUID: String,
        value: String
    ) -> Event {
        Event(
            t: t,
            type: .indicate,
            instanceId: instanceId,
            serviceUUID: serviceUUID,
            characteristicUUID: characteristicUUID,
            value: value
        )
    }
}

// MARK: - GATT Address

/// GATT characteristic address: service UUID + characteristic UUID.
/// Used to uniquely identify a characteristic in the GATT hierarchy when the same
/// characteristic UUID might exist under multiple services.
public struct GattAddress: Codable, Sendable, Equatable, Hashable {
    public let serviceUUID: String
    public let characteristicUUID: String

    public init(serviceUUID: String, characteristicUUID: String) {
        self.serviceUUID = serviceUUID
        self.characteristicUUID = characteristicUUID
    }
}

// MARK: - GattAddress Convenience

public extension GattAddress {
    var path: String {
        "\(serviceUUID)/\(characteristicUUID)"
    }

    var isValid: Bool {
        !serviceUUID.isEmpty && !characteristicUUID.isEmpty
    }
}

// MARK: - Event GATT Address Extensions

public extension Event {
    var gattAddress: GattAddress? {
        guard let service = serviceUUID, !service.isEmpty,
              let characteristic = characteristicUUID, !characteristic.isEmpty else {
            return nil
        }
        return GattAddress(serviceUUID: service, characteristicUUID: characteristic)
    }

    var hasGattAddress: Bool {
        gattAddress != nil
    }

    var isMissingRequiredGattAddress: Bool {
        type.requiresGattAddress && !hasGattAddress
    }

    func targets(serviceUUID: String, characteristicUUID: String) -> Bool {
        self.serviceUUID == serviceUUID && self.characteristicUUID == characteristicUUID
    }

    func targets(address: GattAddress) -> Bool {
        targets(serviceUUID: address.serviceUUID, characteristicUUID: address.characteristicUUID)
    }
}
