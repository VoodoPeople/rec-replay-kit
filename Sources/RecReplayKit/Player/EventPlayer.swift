import Combine
import Foundation

@MainActor
public final class EventPlayer {
    public let eventSubject = PassthroughSubject<Event, Never>()
    public private(set) var isPlaying: Bool = false
    public private(set) var isCompleted: Bool = false
    public let events: [Event]

    private var currentIndex: Int = 0
    private var eventTimer: Timer?
    private var startTime: Date?
    private var pausedElapsedTime: TimeInterval = 0

    public init(events: [Event], validate: Bool = true) throws {
        if validate {
            try EventValidator.validate(events: events)
        }
        self.events = events.sorted { $0.t < $1.t }
    }

    public init(eventsWithoutValidation events: [Event]) {
        self.events = events.sorted { $0.t < $1.t }
    }

    public func start() {
        guard !isPlaying, !isCompleted else { return }

        isPlaying = true

        if startTime == nil {
            startTime = Date()
            currentIndex = 0
        } else {
            startTime = Date().addingTimeInterval(-pausedElapsedTime)
        }

        scheduleNextEvent()
    }

    public func pause() {
        guard isPlaying else { return }

        isPlaying = false
        eventTimer?.invalidate()
        eventTimer = nil

        if let startTime = startTime {
            pausedElapsedTime = Date().timeIntervalSince(startTime)
        }
    }

    public func stop() {
        isPlaying = false
        isCompleted = false
        eventTimer?.invalidate()
        eventTimer = nil
        startTime = nil
        pausedElapsedTime = 0
        currentIndex = 0
    }

    public func reset() {
        stop()
    }

    public func seek(to index: Int) {
        guard !isPlaying else { return }
        guard index >= 0, index < events.count else { return }

        currentIndex = index
        isCompleted = false

        if index < events.count {
            pausedElapsedTime = TimeInterval(events[index].t) / 1000.0
        }
    }

    private func scheduleNextEvent() {
        guard isPlaying, currentIndex < events.count else {
            if currentIndex >= events.count {
                isCompleted = true
                isPlaying = false
            }
            return
        }

        let event = events[currentIndex]
        let eventTimeSeconds = TimeInterval(event.t) / 1000.0

        guard let startTime = startTime else { return }

        let elapsedTime = Date().timeIntervalSince(startTime)
        let delay = max(0, eventTimeSeconds - elapsedTime)

        if delay <= 0 {
            fireEvent(event)
        } else {
            eventTimer = Timer.scheduledTimer(
                withTimeInterval: delay,
                repeats: false
            ) { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.fireCurrentEvent()
                }
            }
        }
    }

    private func fireCurrentEvent() {
        guard isPlaying, currentIndex < events.count else { return }
        fireEvent(events[currentIndex])
    }

    private func fireEvent(_ event: Event) {
        eventSubject.send(event)
        currentIndex += 1
        scheduleNextEvent()
    }
}

public extension EventPlayer {
    var durationMs: Int { events.last?.t ?? 0 }
    var durationSeconds: TimeInterval { TimeInterval(durationMs) / 1000.0 }
    var eventCount: Int { events.count }

    var currentPositionMs: Int {
        guard let startTime = startTime else {
            return Int(pausedElapsedTime * 1000)
        }
        return Int(Date().timeIntervalSince(startTime) * 1000)
    }

    var currentPositionSeconds: TimeInterval { TimeInterval(currentPositionMs) / 1000.0 }
    var remainingMs: Int { max(0, durationMs - currentPositionMs) }
    var remainingSeconds: TimeInterval { TimeInterval(remainingMs) / 1000.0 }

    var progress: Double {
        guard durationMs > 0 else { return 0 }
        return min(1.0, Double(currentPositionMs) / Double(durationMs))
    }

    var currentEventIndex: Int { currentIndex }
    var remainingEventCount: Int { max(0, events.count - currentIndex) }

    var nextEvent: Event? {
        guard currentIndex < events.count else { return nil }
        return events[currentIndex]
    }
}

public extension EventPlayer {
    func events(for instanceId: String) -> [Event] {
        events.filter { $0.instanceId == instanceId }
    }

    func events(ofType type: EventType) -> [Event] {
        events.filter { $0.type == type }
    }

    var instanceIds: Set<String> { Set(events.map(\.instanceId)) }
}
