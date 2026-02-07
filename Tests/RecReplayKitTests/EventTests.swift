import XCTest
@testable import RecReplayKit

final class EventTests: XCTestCase {
    func testEventTypeClassification() {
        // Request types
        XCTAssertTrue(EventType.mtuRequest.isRequest)
        XCTAssertTrue(EventType.readRequest.isRequest)
        XCTAssertTrue(EventType.writeRequest.isRequest)
        XCTAssertFalse(EventType.connect.isRequest)

        // Response types
        XCTAssertTrue(EventType.mtuResponse.isResponse)
        XCTAssertTrue(EventType.readResponse.isResponse)
        XCTAssertTrue(EventType.writeResponse.isResponse)
        XCTAssertFalse(EventType.disconnect.isResponse)

        // GATT addressing required
        XCTAssertTrue(EventType.readRequest.requiresGattAddress)
        XCTAssertTrue(EventType.writeRequest.requiresGattAddress)
        XCTAssertTrue(EventType.notify.requiresGattAddress)
        XCTAssertTrue(EventType.indicate.requiresGattAddress)
        XCTAssertFalse(EventType.mtuRequest.requiresGattAddress)
        XCTAssertFalse(EventType.connect.requiresGattAddress)

        // MTU events
        XCTAssertTrue(EventType.mtuRequest.isMtuEvent)
        XCTAssertTrue(EventType.mtuResponse.isMtuEvent)
        XCTAssertFalse(EventType.readRequest.isMtuEvent)

        // Notifications
        XCTAssertTrue(EventType.notify.isNotification)
        XCTAssertTrue(EventType.indicate.isNotification)
        XCTAssertFalse(EventType.readResponse.isNotification)
    }

    func testEventFactoryMethods() {
        let connectEvent = Event.connect(at: 100, instanceId: "device-0")
        XCTAssertEqual(connectEvent.t, 100)
        XCTAssertEqual(connectEvent.type, .connect)
        XCTAssertEqual(connectEvent.instanceId, "device-0")

        let mtuRequest = Event.mtuRequest(at: 200, instanceId: "device-0", requestId: "req-1", mtu: 247)
        XCTAssertEqual(mtuRequest.mtu, 247)
        XCTAssertEqual(mtuRequest.requestId, "req-1")

        let notify = Event.notify(
            at: 300,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )
        XCTAssertEqual(notify.serviceUUID, "180F")
        XCTAssertEqual(notify.characteristicUUID, "2A19")
        XCTAssertEqual(notify.value, "64")
    }

    func testEventCodable() throws {
        let event = Event.mtuRequest(at: 500, instanceId: "device-0", requestId: "req-1", mtu: 247)

        let encoder = JSONEncoder()
        let data = try encoder.encode(event)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Event.self, from: data)

        XCTAssertEqual(event, decoded)
    }

    // MARK: - GattAddress Tests

    func testGattAddressCreation() {
        let address = GattAddress(
            serviceUUID: "0000180F-0000-1000-8000-00805F9B34FB",
            characteristicUUID: "00002A19-0000-1000-8000-00805F9B34FB"
        )

        XCTAssertEqual(address.serviceUUID, "0000180F-0000-1000-8000-00805F9B34FB")
        XCTAssertEqual(address.characteristicUUID, "00002A19-0000-1000-8000-00805F9B34FB")
    }

    func testGattAddressPath() {
        let address = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        XCTAssertEqual(address.path, "180F/2A19")
    }

    func testGattAddressIsValid() {
        let validAddress = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        XCTAssertTrue(validAddress.isValid)

        let emptyService = GattAddress(serviceUUID: "", characteristicUUID: "2A19")
        XCTAssertFalse(emptyService.isValid)

        let emptyCharacteristic = GattAddress(serviceUUID: "180F", characteristicUUID: "")
        XCTAssertFalse(emptyCharacteristic.isValid)

        let bothEmpty = GattAddress(serviceUUID: "", characteristicUUID: "")
        XCTAssertFalse(bothEmpty.isValid)
    }

    func testGattAddressEquatable() {
        let address1 = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        let address2 = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        let address3 = GattAddress(serviceUUID: "180F", characteristicUUID: "2A1C")

        XCTAssertEqual(address1, address2)
        XCTAssertNotEqual(address1, address3)
    }

    func testGattAddressHashable() {
        let address1 = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        let address2 = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")

        var set = Set<GattAddress>()
        set.insert(address1)
        set.insert(address2)

        XCTAssertEqual(set.count, 1)
    }

    func testGattAddressCodable() throws {
        let address = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")

        let encoder = JSONEncoder()
        let data = try encoder.encode(address)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(GattAddress.self, from: data)

        XCTAssertEqual(address, decoded)
    }

    // MARK: - Event GATT Address Extensions Tests

    func testEventGattAddress() {
        let notifyEvent = Event.notify(
            at: 100,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )

        let address = notifyEvent.gattAddress
        XCTAssertNotNil(address)
        XCTAssertEqual(address?.serviceUUID, "180F")
        XCTAssertEqual(address?.characteristicUUID, "2A19")
    }

    func testEventGattAddressNil() {
        let connectEvent = Event.connect(at: 100, instanceId: "device-0")
        XCTAssertNil(connectEvent.gattAddress)

        let mtuEvent = Event.mtuRequest(at: 100, instanceId: "device-0", requestId: "req-1", mtu: 247)
        XCTAssertNil(mtuEvent.gattAddress)
    }

    func testEventHasGattAddress() {
        let notifyEvent = Event.notify(
            at: 100,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )
        XCTAssertTrue(notifyEvent.hasGattAddress)

        let connectEvent = Event.connect(at: 100, instanceId: "device-0")
        XCTAssertFalse(connectEvent.hasGattAddress)
    }

    func testEventIsMissingRequiredGattAddress() {
        // Notify event with GATT address - not missing
        let validNotify = Event.notify(
            at: 100,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )
        XCTAssertFalse(validNotify.isMissingRequiredGattAddress)

        // Notify event without GATT address - missing
        let invalidNotify = Event(
            t: 100,
            type: .notify,
            instanceId: "device-0",
            value: "64"
        )
        XCTAssertTrue(invalidNotify.isMissingRequiredGattAddress)

        // Connect event doesn't require GATT address
        let connectEvent = Event.connect(at: 100, instanceId: "device-0")
        XCTAssertFalse(connectEvent.isMissingRequiredGattAddress)
    }

    func testEventTargetsWithUUIDs() {
        let notifyEvent = Event.notify(
            at: 100,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )

        XCTAssertTrue(notifyEvent.targets(serviceUUID: "180F", characteristicUUID: "2A19"))
        XCTAssertFalse(notifyEvent.targets(serviceUUID: "180F", characteristicUUID: "2A1C"))
        XCTAssertFalse(notifyEvent.targets(serviceUUID: "180A", characteristicUUID: "2A19"))
    }

    func testEventTargetsWithGattAddress() {
        let notifyEvent = Event.notify(
            at: 100,
            instanceId: "device-0",
            serviceUUID: "180F",
            characteristicUUID: "2A19",
            value: "64"
        )

        let matchingAddress = GattAddress(serviceUUID: "180F", characteristicUUID: "2A19")
        let differentAddress = GattAddress(serviceUUID: "180A", characteristicUUID: "2A29")

        XCTAssertTrue(notifyEvent.targets(address: matchingAddress))
        XCTAssertFalse(notifyEvent.targets(address: differentAddress))
    }
}
