import Foundation

/// BLE event types for recording and replay.
///
/// Events are categorized into:
/// - Advertising events (start, stop, update)
/// - Connection events (connect, disconnect, rssi)
/// - ATT request/response pairs (mtu, read, write)
/// - Notifications (notify, indicate) - exceptions to request/response symmetry
public enum EventType: String, Codable, Sendable {
    // MARK: - Advertising Events

    case advertisingStart = "advertising_start"
    case advertisingStop = "advertising_stop"
    case advertisingUpdate = "advertising_update"

    // MARK: - Connection Events

    case connect
    case disconnect
    case rssi

    // MARK: - ATT Request/Response Pairs

    /// MTU exchange request (initiator -> responder)
    case mtuRequest = "mtu_request"

    /// MTU exchange response (responder -> initiator)
    case mtuResponse = "mtu_response"

    case readRequest = "read_request"
    case readResponse = "read_response"
    case writeRequest = "write_request"
    case writeResponse = "write_response"

    // MARK: - Notifications (No request needed)

    /// Characteristic notification (server -> client, no confirmation)
    case notify

    /// Characteristic indication (server -> client, with confirmation)
    case indicate
}

// MARK: - Event Type Classification

public extension EventType {
    var isRequest: Bool {
        switch self {
        case .mtuRequest, .readRequest, .writeRequest:
            return true
        default:
            return false
        }
    }

    var isResponse: Bool {
        switch self {
        case .mtuResponse, .readResponse, .writeResponse:
            return true
        default:
            return false
        }
    }

    var requiresGattAddress: Bool {
        switch self {
        case .readRequest, .readResponse, .writeRequest, .notify, .indicate:
            return true
        default:
            return false
        }
    }

    var isMtuEvent: Bool {
        switch self {
        case .mtuRequest, .mtuResponse:
            return true
        default:
            return false
        }
    }

    var requiresRequestId: Bool {
        isRequest || isResponse
    }

    var isNotification: Bool {
        switch self {
        case .notify, .indicate:
            return true
        default:
            return false
        }
    }
}
