import Foundation

/// A single BLE event in a recorded scenario timeline.
///
/// ## Invariants
/// - All events MUST have a non-empty `instanceId`
/// - ATT request/response events MUST have a `requestId`
/// - GATT events (read, write, notify, indicate) MUST have both `serviceUUID` and `characteristicUUID`
/// - MTU events MUST NOT have GATT addressing
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

    // MARK: - Protocol Layer Detail (Optional — ATT/L2CAP visibility)
    //
    // These fields are populated when ATT-level or L2CAP-level recording is
    // available (e.g., via HCI monitor on Linux, or embedded stacks like NimBLE).
    // They are always optional — GATT-level recordings omit them entirely.
    // Existing GATT-level events remain valid without these fields.

    /// ATT protocol opcode observed for this event (e.g., 0x0A = Read Request,
    /// 0x0B = Read Response, 0x1B = Handle Value Notification).
    /// Populated only when ATT-level recording is available.
    public let attOpcode: Int?

    /// ATT attribute handle (16-bit) for this event.
    /// Provides the ATT-level handle in addition to the GATT-level UUID path.
    /// Populated only when ATT-level recording is available.
    public let attHandle: Int?

    /// ATT error code when the event represents an ATT error response.
    /// Standard ATT error codes: 0x01 = Invalid Handle, 0x02 = Read Not Permitted,
    /// 0x05 = Insufficient Authentication, 0x06 = Request Not Supported, etc.
    /// Populated only when ATT-level recording is available.
    public let attErrorCode: Int?

    /// L2CAP channel ID (CID) over which this event was transported.
    /// Standard CIDs: 0x0004 = ATT, 0x0005 = LE Signaling, 0x0006 = SMP.
    /// Populated only when L2CAP-level recording is available.
    public let l2capCid: Int?

    /// Raw hex-encoded PDU bytes as observed on the wire.
    /// Contains the full ATT or L2CAP PDU for forensic analysis or
    /// bit-exact replay. Populated only when protocol-level recording is available.
    public let rawPDU: String?

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
        attOpcode: Int? = nil,
        attHandle: Int? = nil,
        attErrorCode: Int? = nil,
        l2capCid: Int? = nil,
        rawPDU: String? = nil
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
        self.attOpcode = attOpcode
        self.attHandle = attHandle
        self.attErrorCode = attErrorCode
        self.l2capCid = l2capCid
        self.rawPDU = rawPDU
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
