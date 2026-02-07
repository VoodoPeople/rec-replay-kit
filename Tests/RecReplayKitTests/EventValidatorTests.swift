import XCTest
@testable import RecReplayKit

final class EventValidatorTests: XCTestCase {
    func testValidEmptyEventStream() throws {
        let events: [Event] = []
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidSimpleEventStream() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1000, instanceId: "device-0")
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidMtuRequestResponse() throws {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247),
            Event.mtuResponse(at: 110, instanceId: "device-0", requestId: "req-1", mtu: 247)
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidReadRequestResponse() throws {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.readRequest(
                at: 100,
                instanceId: "device-0",
                requestId: "req-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19"
            ),
            Event.readResponse(
                at: 110,
                instanceId: "device-0",
                requestId: "req-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "64"
            )
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidWriteRequestResponse() throws {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.writeRequest(
                at: 100,
                instanceId: "device-0",
                requestId: "req-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "01"
            ),
            Event.writeResponse(at: 110, instanceId: "device-0", requestId: "req-1")
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidNotificationsWithoutRequest() throws {
        // Notifications are exceptions - no request needed
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.notify(
                at: 100,
                instanceId: "device-0",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "64"
            ),
            Event.indicate(
                at: 200,
                instanceId: "device-0",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "65"
            )
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    func testValidMultipleRequestResponsePairs() throws {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "mtu-1", mtu: 247),
            Event.mtuResponse(at: 110, instanceId: "device-0", requestId: "mtu-1", mtu: 247),
            Event.readRequest(
                at: 200,
                instanceId: "device-0",
                requestId: "read-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19"
            ),
            Event.readResponse(
                at: 210,
                instanceId: "device-0",
                requestId: "read-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "64"
            )
        ]
        XCTAssertNoThrow(try EventValidator.validate(events: events))
    }

    // MARK: - Orphan Response Errors

    func testOrphanMtuResponse() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            // No mtu_request before this response
            Event.mtuResponse(at: 110, instanceId: "device-0", requestId: "req-1", mtu: 247)
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.orphanResponse = error else {
                XCTFail("Expected orphanResponse error")
                return
            }
        }
    }

    func testOrphanReadResponse() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.readResponse(
                at: 110,
                instanceId: "device-0",
                requestId: "req-1",
                serviceUUID: "180F",
                characteristicUUID: "2A19",
                value: "64"
            )
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.orphanResponse = error else {
                XCTFail("Expected orphanResponse error")
                return
            }
        }
    }

    func testOrphanWriteResponse() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.writeResponse(at: 110, instanceId: "device-0", requestId: "req-1")
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.orphanResponse = error else {
                XCTFail("Expected orphanResponse error")
                return
            }
        }
    }

    func testMismatchedRequestId() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247),
            // Response uses different requestId
            Event.mtuResponse(at: 110, instanceId: "device-0", requestId: "req-2", mtu: 247)
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.orphanResponse = error else {
                XCTFail("Expected orphanResponse error")
                return
            }
        }
    }

    // MARK: - Duplicate RequestId Errors

    func testDuplicateRequestId() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247),
            Event.mtuResponse(at: 110, instanceId: "device-0", requestId: "req-1", mtu: 247),
            // Reusing the same requestId
            Event.mtuRequest(at: 200, instanceId: "device-0", requestId: "req-1", mtu: 512)
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case let EventValidator.ValidationError.duplicateRequestId(id) = error else {
                XCTFail("Expected duplicateRequestId error")
                return
            }
            XCTAssertEqual(id, "req-1")
        }
    }

    // MARK: - Missing RequestId Errors

    func testMissingRequestIdOnRequest() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(t: 100, type: .mtuRequest, instanceId: "device-0", mtu: 247)  // No requestId
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.missingRequestId = error else {
                XCTFail("Expected missingRequestId error")
                return
            }
        }
    }

    func testMissingRequestIdOnResponse() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247),
            Event(t: 110, type: .mtuResponse, instanceId: "device-0", mtu: 247)  // No requestId
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.missingRequestId = error else {
                XCTFail("Expected missingRequestId error")
                return
            }
        }
    }

    // MARK: - Missing InstanceId Errors

    func testMissingInstanceId() {
        let events = [
            Event(t: 0, type: .connect, instanceId: "")  // Empty instanceId
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.missingInstanceId = error else {
                XCTFail("Expected missingInstanceId error")
                return
            }
        }
    }

    // MARK: - Invalid GATT Address Errors

    func testMissingServiceUUID() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(
                t: 100,
                type: .notify,
                instanceId: "device-0",
                characteristicUUID: "2A19",
                value: "64"
            )  // Missing serviceUUID
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.invalidGattAddress = error else {
                XCTFail("Expected invalidGattAddress error")
                return
            }
        }
    }

    func testMissingCharacteristicUUID() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(
                t: 100,
                type: .notify,
                instanceId: "device-0",
                serviceUUID: "180F",
                value: "64"
            )  // Missing characteristicUUID
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.invalidGattAddress = error else {
                XCTFail("Expected invalidGattAddress error")
                return
            }
        }
    }

    func testReadRequestMissingGattAddress() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(t: 100, type: .readRequest, instanceId: "device-0", requestId: "req-1")
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.invalidGattAddress = error else {
                XCTFail("Expected invalidGattAddress error")
                return
            }
        }
    }

    func testWriteRequestMissingGattAddress() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(t: 100, type: .writeRequest, instanceId: "device-0", requestId: "req-1", value: "01")
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.invalidGattAddress = error else {
                XCTFail("Expected invalidGattAddress error")
                return
            }
        }
    }

    // MARK: - MTU Event With GATT Address Errors

    func testMtuRequestWithGattAddress() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event(
                t: 100,
                type: .mtuRequest,
                instanceId: "device-0",
                requestId: "req-1",
                mtu: 247,
                serviceUUID: "180F",
                characteristicUUID: "2A19"
            )
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.mtuEventWithGattAddress = error else {
                XCTFail("Expected mtuEventWithGattAddress error")
                return
            }
        }
    }

    func testMtuResponseWithGattAddress() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247),
            Event(
                t: 110,
                type: .mtuResponse,
                instanceId: "device-0",
                requestId: "req-1",
                mtu: 247,
                serviceUUID: "180F"
            )
        ]

        XCTAssertThrowsError(try EventValidator.validate(events: events)) { error in
            guard case EventValidator.ValidationError.mtuEventWithGattAddress = error else {
                XCTFail("Expected mtuEventWithGattAddress error")
                return
            }
        }
    }

    // MARK: - Timestamp Warnings

    func testOutOfOrderTimestampsProducesWarning() {
        let events = [
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 100, instanceId: "device-0")  // Out of order
        ]

        let result = EventValidator.validateWithResult(events: events)

        XCTAssertTrue(result.isValid)  // Warnings don't fail validation
        XCTAssertEqual(result.warnings.count, 1)
        guard let warning = result.warnings.first,
              case EventValidator.ValidationError.outOfOrderTimestamps = warning else {
            XCTFail("Expected outOfOrderTimestamps warning")
            return
        }
    }

    // MARK: - ValidationResult Tests

    func testValidationResultIsValid() {
        let validEvents = [
            Event.connect(at: 0, instanceId: "device-0")
        ]
        let result = EventValidator.validateWithResult(events: validEvents)

        XCTAssertTrue(result.isValid)
        XCTAssertTrue(result.errors.isEmpty)
    }

    func testValidationResultWithErrors() {
        let invalidEvents = [
            Event(t: 0, type: .connect, instanceId: "")  // Missing instanceId
        ]
        let result = EventValidator.validateWithResult(events: invalidEvents)

        XCTAssertFalse(result.isValid)
        XCTAssertEqual(result.errors.count, 1)
    }

    // MARK: - Single Event Validation

    func testValidateSingleValidEvent() {
        let event = Event.connect(at: 0, instanceId: "device-0")
        let errors = EventValidator.validateSingle(event: event)
        XCTAssertTrue(errors.isEmpty)
    }

    func testValidateSingleInvalidEvent() {
        let event = Event(t: 0, type: .connect, instanceId: "")
        let errors = EventValidator.validateSingle(event: event)
        XCTAssertEqual(errors.count, 1)
    }

    // MARK: - Array Extension Tests

    func testArrayValidateExtension() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0")
        ]
        XCTAssertNoThrow(try events.validate())
    }

    func testArrayValidateWithResultExtension() {
        let events = [
            Event.connect(at: 0, instanceId: "device-0")
        ]
        let result = events.validateWithResult()
        XCTAssertTrue(result.isValid)
    }

    // MARK: - Error Description Tests

    func testValidationErrorDescriptions() {
        let event = Event.connect(at: 100, instanceId: "device-0")

        let orphanError = EventValidator.ValidationError.orphanResponse(event)
        XCTAssertTrue(orphanError.description.contains("Orphan response"))

        let duplicateError = EventValidator.ValidationError.duplicateRequestId("req-1")
        XCTAssertTrue(duplicateError.description.contains("Duplicate requestId"))
        XCTAssertTrue(duplicateError.description.contains("req-1"))

        let missingIdError = EventValidator.ValidationError.missingInstanceId(event)
        XCTAssertTrue(missingIdError.description.contains("Missing instanceId"))

        let gattError = EventValidator.ValidationError.invalidGattAddress(event)
        XCTAssertTrue(gattError.description.contains("Invalid GATT address"))
    }
}
