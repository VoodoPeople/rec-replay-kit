import Foundation

/// Validates BLE event streams for correctness and invariant compliance.
///
/// ## ATT Request-Response Symmetry
/// - Every `*_response` event MUST have a preceding `*_request` with matching `requestId`
/// - `notify` and `indicate` events are exempt (no request needed)
/// - No duplicate `requestId` values
///
/// ## GATT-Level Addressing
/// - GATT events (read, write, notify, indicate) MUST have both `serviceUUID` and `characteristicUUID`
/// - MTU events MUST NOT have GATT addressing
///
/// ## Instance ID
/// - All events MUST have a non-empty `instanceId`
public struct EventValidator {
    // MARK: - Validation Errors

    public enum ValidationError: Error, Equatable, CustomStringConvertible {
        /// Response event has no matching request
        case orphanResponse(Event)

        /// requestId was used more than once
        case duplicateRequestId(String)

        /// Request or response event is missing its requestId
        case missingRequestId(Event)

        /// Event is missing its instanceId
        case missingInstanceId(Event)

        /// GATT event is missing serviceUUID or characteristicUUID
        case invalidGattAddress(Event)

        /// MTU event incorrectly has GATT addressing
        case mtuEventWithGattAddress(Event)

        /// Events are not in chronological order (warning, not fatal)
        case outOfOrderTimestamps(Event, previousTimestamp: Int)

        public var description: String {
            switch self {
            case let .orphanResponse(event):
                return "Orphan response: \(event.type) at t=\(event.t) has no matching request (requestId: \(event.requestId ?? "nil"))"
            case let .duplicateRequestId(id):
                return "Duplicate requestId: '\(id)' was already used"
            case let .missingRequestId(event):
                return "Missing requestId: \(event.type) at t=\(event.t) requires a requestId"
            case let .missingInstanceId(event):
                return "Missing instanceId: \(event.type) at t=\(event.t) has empty instanceId"
            case let .invalidGattAddress(event):
                return "Invalid GATT address: \(event.type) at t=\(event.t) requires both serviceUUID and characteristicUUID"
            case let .mtuEventWithGattAddress(event):
                return "MTU event with GATT address: \(event.type) at t=\(event.t) should not have serviceUUID or characteristicUUID"
            case let .outOfOrderTimestamps(event, previousTimestamp):
                return "Out of order: \(event.type) at t=\(event.t) comes after t=\(previousTimestamp)"
            }
        }
    }

    // MARK: - Validation Result

    public struct ValidationResult: Equatable {
        public let errors: [ValidationError]
        public let warnings: [ValidationError]
        public var isValid: Bool { errors.isEmpty }

        public init(errors: [ValidationError] = [], warnings: [ValidationError] = []) {
            self.errors = errors
            self.warnings = warnings
        }
    }

    // MARK: - Public API

    public static func validate(events: [Event]) throws {
        let result = validateWithResult(events: events)
        if let firstError = result.errors.first {
            throw firstError
        }
    }

    public static func validateWithResult(events: [Event]) -> ValidationResult {
        var errors: [ValidationError] = []
        var warnings: [ValidationError] = []

        var seenRequestIds = Set<String>()
        var pendingRequests = [String: Event]()
        var previousTimestamp: Int?

        for event in events {
            if let prevT = previousTimestamp, event.t < prevT {
                warnings.append(.outOfOrderTimestamps(event, previousTimestamp: prevT))
            }
            previousTimestamp = event.t

            if event.instanceId.isEmpty {
                errors.append(.missingInstanceId(event))
                continue
            }

            if event.type.isRequest {
                guard let requestId = event.requestId, !requestId.isEmpty else {
                    errors.append(.missingRequestId(event))
                    continue
                }

                if seenRequestIds.contains(requestId) {
                    errors.append(.duplicateRequestId(requestId))
                    continue
                }

                seenRequestIds.insert(requestId)
                pendingRequests[requestId] = event
            }

            if event.type.isResponse {
                guard let requestId = event.requestId, !requestId.isEmpty else {
                    errors.append(.missingRequestId(event))
                    continue
                }

                if pendingRequests[requestId] == nil {
                    errors.append(.orphanResponse(event))
                    continue
                }

                pendingRequests.removeValue(forKey: requestId)
            }

            if event.type.requiresGattAddress {
                let hasService = event.serviceUUID != nil && !event.serviceUUID!.isEmpty
                let hasCharacteristic = event.characteristicUUID != nil && !event.characteristicUUID!.isEmpty

                if !hasService || !hasCharacteristic {
                    errors.append(.invalidGattAddress(event))
                    continue
                }
            }

            if event.type.isMtuEvent {
                let hasService = event.serviceUUID != nil && !event.serviceUUID!.isEmpty
                let hasCharacteristic = event.characteristicUUID != nil && !event.characteristicUUID!.isEmpty

                if hasService || hasCharacteristic {
                    errors.append(.mtuEventWithGattAddress(event))
                    continue
                }
            }
        }

        return ValidationResult(errors: errors, warnings: warnings)
    }

    // MARK: - Convenience Methods

    public static func validateSingle(event: Event) -> [ValidationError] {
        var errors: [ValidationError] = []

        if event.instanceId.isEmpty {
            errors.append(.missingInstanceId(event))
        }

        if event.type.requiresRequestId {
            if event.requestId == nil || event.requestId!.isEmpty {
                errors.append(.missingRequestId(event))
            }
        }

        if event.type.requiresGattAddress {
            let hasService = event.serviceUUID != nil && !event.serviceUUID!.isEmpty
            let hasCharacteristic = event.characteristicUUID != nil && !event.characteristicUUID!.isEmpty

            if !hasService || !hasCharacteristic {
                errors.append(.invalidGattAddress(event))
            }
        }

        if event.type.isMtuEvent {
            let hasService = event.serviceUUID != nil && !event.serviceUUID!.isEmpty
            let hasCharacteristic = event.characteristicUUID != nil && !event.characteristicUUID!.isEmpty

            if hasService || hasCharacteristic {
                errors.append(.mtuEventWithGattAddress(event))
            }
        }

        return errors
    }
}

// MARK: - Array Extension

public extension Array where Element == Event {
    func validate() throws {
        try EventValidator.validate(events: self)
    }

    func validateWithResult() -> EventValidator.ValidationResult {
        EventValidator.validateWithResult(events: self)
    }
}
