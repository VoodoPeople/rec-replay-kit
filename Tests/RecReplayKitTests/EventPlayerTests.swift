import Combine
import XCTest
@testable import RecReplayKit

@MainActor
final class EventPlayerTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()

    override func tearDown() {
        cancellables.removeAll()
        super.tearDown()
    }

    func testInitWithValidEvents() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.eventCount, 2)
        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.isCompleted)
    }

    func testInitWithInvalidEventsThrows() {
        let events = [
            Event(t: 0, type: .connect, instanceId: "")
        ]

        XCTAssertThrowsError(try EventPlayer(events: events)) { error in
            guard case EventValidator.ValidationError.missingInstanceId = error else {
                XCTFail("Expected missingInstanceId error")
                return
            }
        }
    }

    func testInitWithoutValidation() {
        let events = [
            Event(t: 0, type: .connect, instanceId: "")
        ]

        let player = EventPlayer(eventsWithoutValidation: events)
        XCTAssertEqual(player.eventCount, 1)
    }

    func testInitWithValidateFalse() throws {
        let events = [
            Event(t: 0, type: .connect, instanceId: "")
        ]

        let player = try EventPlayer(events: events, validate: false)
        XCTAssertEqual(player.eventCount, 1)
    }

    func testEventsSortedByTimestamp() throws {
        let events = [
            Event.disconnect(at: 1000, instanceId: "device-0"),
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.events[0].t, 0)
        XCTAssertEqual(player.events[1].t, 500)
        XCTAssertEqual(player.events[2].t, 1000)
    }

    func testDuration() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.durationMs, 1500)
        XCTAssertEqual(player.durationSeconds, 1.5)
    }

    func testEmptyDuration() throws {
        let player = try EventPlayer(events: [])

        XCTAssertEqual(player.durationMs, 0)
        XCTAssertEqual(player.durationSeconds, 0)
    }

    func testInitialPosition() throws {
        let events = [Event.connect(at: 100, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.currentEventIndex, 0)
        XCTAssertEqual(player.remainingEventCount, 1)
    }

    func testStartSetsIsPlaying() throws {
        let events = [Event.connect(at: 1000, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        player.start()
        XCTAssertTrue(player.isPlaying)

        player.stop()
    }

    func testPauseSetsIsPlayingFalse() throws {
        let events = [Event.connect(at: 1000, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        player.start()
        player.pause()

        XCTAssertFalse(player.isPlaying)
    }

    func testStopResetsState() throws {
        let events = [Event.connect(at: 1000, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        player.start()
        player.stop()

        XCTAssertFalse(player.isPlaying)
        XCTAssertFalse(player.isCompleted)
        XCTAssertEqual(player.currentEventIndex, 0)
    }

    func testResetEqualsStop() throws {
        let events = [Event.connect(at: 1000, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        player.start()
        player.reset()

        XCTAssertFalse(player.isPlaying)
        XCTAssertEqual(player.currentEventIndex, 0)
    }

    func testSeekToIndex() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1000, instanceId: "device-0")
        ]
        let player = try EventPlayer(events: events)

        player.seek(to: 1)

        XCTAssertEqual(player.currentEventIndex, 1)
        XCTAssertEqual(player.nextEvent?.type, .connect)
    }

    func testSeekWhilePlayingIsIgnored() throws {
        let events = [
            Event.connect(at: 1000, instanceId: "device-0"),
            Event.disconnect(at: 2000, instanceId: "device-0")
        ]
        let player = try EventPlayer(events: events)

        player.start()
        player.seek(to: 1)

        XCTAssertEqual(player.currentEventIndex, 0)

        player.stop()
    }

    func testSeekOutOfBoundsIsIgnored() throws {
        let events = [Event.connect(at: 0, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        player.seek(to: 10)
        XCTAssertEqual(player.currentEventIndex, 0)

        player.seek(to: -1)
        XCTAssertEqual(player.currentEventIndex, 0)
    }

    func testImmediateEventEmission() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 0, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        var receivedEvents: [Event] = []
        let expectation = expectation(description: "Events received")

        player.eventSubject.sink { event in
            receivedEvents.append(event)
            if receivedEvents.count == 2 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        player.start()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedEvents.count, 2)
        XCTAssertEqual(receivedEvents[0].type, .advertisingStart)
        XCTAssertEqual(receivedEvents[1].type, .connect)

        player.stop()
    }

    func testDelayedEventEmission() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 100, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        var receivedEvents: [Event] = []
        let expectation = expectation(description: "Events received")

        player.eventSubject.sink { event in
            receivedEvents.append(event)
            if receivedEvents.count == 2 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        player.start()

        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(receivedEvents.count, 2)

        player.stop()
    }

    func testCompletionAfterAllEvents() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        let expectation = expectation(description: "Event received")

        player.eventSubject.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        player.start()

        wait(for: [expectation], timeout: 1.0)

        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertTrue(player.isCompleted)
        XCTAssertFalse(player.isPlaying)
    }

    func testEventsForInstance() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.advertisingStart(at: 0, instanceId: "device-1"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        let device0Events = player.events(for: "device-0")
        XCTAssertEqual(device0Events.count, 2)

        let device1Events = player.events(for: "device-1")
        XCTAssertEqual(device1Events.count, 1)
    }

    func testEventsOfType() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0"),
            Event.disconnect(at: 1000, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        let connectEvents = player.events(ofType: .connect)
        XCTAssertEqual(connectEvents.count, 1)

        let rssiEvents = player.events(ofType: .rssi)
        XCTAssertTrue(rssiEvents.isEmpty)
    }

    func testInstanceIds() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.advertisingStart(at: 0, instanceId: "device-1"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.instanceIds, ["device-0", "device-1"])
    }

    func testNextEvent() throws {
        let events = [
            Event.advertisingStart(at: 0, instanceId: "device-0"),
            Event.connect(at: 500, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.nextEvent?.type, .advertisingStart)

        player.seek(to: 1)
        XCTAssertEqual(player.nextEvent?.type, .connect)
    }

    func testNextEventAfterCompletion() throws {
        let events = [Event.connect(at: 0, instanceId: "device-0")]
        let player = try EventPlayer(events: events)

        let expectation = expectation(description: "Event received")

        player.eventSubject.sink { _ in
            expectation.fulfill()
        }.store(in: &cancellables)

        player.start()

        wait(for: [expectation], timeout: 1.0)
        RunLoop.current.run(until: Date().addingTimeInterval(0.1))

        XCTAssertNil(player.nextEvent)
    }

    func testProgressCalculation() throws {
        let events = [
            Event.connect(at: 0, instanceId: "device-0"),
            Event.disconnect(at: 1000, instanceId: "device-0")
        ]

        let player = try EventPlayer(events: events)

        XCTAssertEqual(player.progress, 0.0, accuracy: 0.01)

        let expectation = expectation(description: "Events received")
        var count = 0

        player.eventSubject.sink { _ in
            count += 1
            if count == 2 {
                expectation.fulfill()
            }
        }.store(in: &cancellables)

        player.start()
        wait(for: [expectation], timeout: 2.0)

        XCTAssertGreaterThan(player.progress, 0.9)
    }

    func testProgressWithEmptyEvents() throws {
        let player = try EventPlayer(events: [])
        XCTAssertEqual(player.progress, 0.0)
    }
}
