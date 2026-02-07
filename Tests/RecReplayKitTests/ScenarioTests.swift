import XCTest
@testable import RecReplayKit

final class ScenarioTests: XCTestCase {
    // MARK: - DeviceRef Tests

    func testDeviceRefEquality() {
        let ref1 = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        let ref2 = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        let ref3 = DeviceRef(deviceId: "snow-v1", instanceId: "device-1")

        XCTAssertEqual(ref1, ref2)
        XCTAssertNotEqual(ref1, ref3)
    }

    func testDeviceRefIdentifiable() {
        let ref = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        XCTAssertEqual(ref.id, "device-0")
    }

    func testDeviceRefCodable() throws {
        let ref = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")

        let encoder = JSONEncoder()
        let data = try encoder.encode(ref)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(DeviceRef.self, from: data)

        XCTAssertEqual(ref, decoded)
    }

    // MARK: - Scenario Tests

    func testScenarioCreation() {
        let deviceRef = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1000, instanceId: "device-0", reason: "user")
        ]

        let scenario = Scenario(
            version: "1.0",
            deviceRefs: [deviceRef],
            events: events
        )

        XCTAssertEqual(scenario.version, "1.0")
        XCTAssertEqual(scenario.deviceRefs.count, 1)
        XCTAssertEqual(scenario.events.count, 3)
    }

    func testScenarioDuration() {
        let deviceRef = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1500, instanceId: "device-0")
        ]

        let scenario = Scenario(deviceRefs: [deviceRef], events: events)

        XCTAssertEqual(scenario.durationMs, 1500)
        XCTAssertEqual(scenario.durationSeconds, 1.5)
    }

    func testScenarioSortedEvents() {
        let deviceRef = DeviceRef(deviceId: "snow-v1", instanceId: "device-0")
        let events = [
            Event.disconnect(at: 1000, instanceId: "device-0"),
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let scenario = Scenario(deviceRefs: [deviceRef], events: events)
        let sorted = scenario.sortedEvents

        XCTAssertEqual(sorted[0].t, 0)
        XCTAssertEqual(sorted[1].t, 500)
        XCTAssertEqual(sorted[2].t, 1000)
    }

    func testScenarioEventsForInstance() {
        let refs = [
            DeviceRef(deviceId: "snow-v1", instanceId: "device-0"),
            DeviceRef(deviceId: "snow-v1", instanceId: "device-1")
        ]
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.advertisingStart(at: 100, instanceId: "device-1"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let scenario = Scenario(deviceRefs: refs, events: events)

        let device0Events = scenario.events(for: "device-0")
        let device1Events = scenario.events(for: "device-1")

        XCTAssertEqual(device0Events.count, 2)
        XCTAssertEqual(device1Events.count, 1)
    }

    func testScenarioHasValidInstanceReferences() {
        let refs = [DeviceRef(deviceId: "snow-v1", instanceId: "device-0")]
        let validEvents = [Event.connect(at: 0, instanceId: "device-0")]
        let invalidEvents = [Event.connect(at: 0, instanceId: "device-1")]

        let validScenario = Scenario(deviceRefs: refs, events: validEvents)
        let invalidScenario = Scenario(deviceRefs: refs, events: invalidEvents)

        XCTAssertTrue(validScenario.hasValidInstanceReferences)
        XCTAssertFalse(invalidScenario.hasValidInstanceReferences)
    }

    // MARK: - Scenario Validation Tests

    func testScenarioValidationEmptyDeviceRefs() {
        let scenario = Scenario(deviceRefs: [], events: [])

        XCTAssertThrowsError(try scenario.validateStructure()) { error in
            XCTAssertEqual(error as? Scenario.ValidationError, .emptyDeviceRefs)
        }
    }

    func testScenarioValidationDuplicateInstanceId() {
        let refs = [
            DeviceRef(deviceId: "snow-v1", instanceId: "device-0"),
            DeviceRef(deviceId: "snow-v2", instanceId: "device-0")  // duplicate
        ]
        let scenario = Scenario(deviceRefs: refs, events: [])

        XCTAssertThrowsError(try scenario.validateStructure()) { error in
            XCTAssertEqual(error as? Scenario.ValidationError, .duplicateInstanceId("device-0"))
        }
    }

    func testScenarioValidationUndefinedInstanceId() {
        let refs = [DeviceRef(deviceId: "snow-v1", instanceId: "device-0")]
        let events = [Event.connect(at: 0, instanceId: "device-1")]  // undefined
        let scenario = Scenario(deviceRefs: refs, events: events)

        XCTAssertThrowsError(try scenario.validateStructure()) { error in
            XCTAssertEqual(error as? Scenario.ValidationError, .undefinedInstanceId("device-1"))
        }
    }

    func testScenarioValidationSuccess() {
        let refs = [DeviceRef(deviceId: "snow-v1", instanceId: "device-0")]
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]
        let scenario = Scenario(deviceRefs: refs, events: events)

        XCTAssertNoThrow(try scenario.validateStructure())
    }

    func testScenarioCodable() throws {
        let refs = [DeviceRef(deviceId: "snow-v1", instanceId: "device-0")]
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]
        let scenario = Scenario(version: "1.0", deviceRefs: refs, events: events)

        let encoder = JSONEncoder()
        let data = try encoder.encode(scenario)

        let decoder = JSONDecoder()
        let decoded = try decoder.decode(Scenario.self, from: data)

        XCTAssertEqual(scenario, decoded)
    }
}
