import ArgumentParser
import Combine
import Foundation
import RecReplayKit

struct Play: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Play back events in real-time"
    )

    @OptionGroup var options: GlobalOptions
    @OptionGroup var file: ScenarioFileArgument

    @Option(name: .long, help: "Start from specific timestamp (ms)")
    var skipTo: Int?

    @Flag(name: .long, help: "Print all events immediately without real-time delays")
    var noRealtime: Bool = false

    func run() async throws {
        let formatter = createFormatter(
            format: options.format,
            useColor: !options.noColor && Terminal.isInteractive()
        )

        let events: [Event]
        do {
            events = try file.loadEvents()
        } catch {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        }

        if noRealtime {
            runNonRealtime(events: events, formatter: formatter)
        } else {
            try await runRealtime(events: events, formatter: formatter)
        }
    }

    private func runNonRealtime(events: [Event], formatter: OutputFormatter) {
        let durationMs = events.last?.t ?? 0

        if !options.quiet {
            let header = formatter.formatPlaybackHeader(
                file: file.path,
                eventCount: events.count,
                durationMs: durationMs
            )
            Terminal.print(header)
            Terminal.print("")
        }

        var startIndex = 0
        if let skipTo = skipTo {
            startIndex = events.firstIndex { $0.t >= skipTo } ?? 0
        }

        for i in startIndex..<events.count {
            let event = events[i]
            let output = formatter.formatEvent(event, elapsedMs: event.t)
            Terminal.print(output)
        }

        if !options.quiet {
            Terminal.print("")
            let footer = formatter.formatPlaybackFooter(
                eventsPlayed: events.count - startIndex,
                durationMs: durationMs
            )
            Terminal.print(footer)
        }
    }

    @MainActor
    private func runRealtime(events: [Event], formatter: OutputFormatter) async throws {
        let durationMs = events.last?.t ?? 0
        let useColor = !options.noColor && Terminal.isInteractive()

        if !options.quiet {
            let header = formatter.formatPlaybackHeader(
                file: file.path,
                eventCount: events.count,
                durationMs: durationMs
            )
            Terminal.print(header)
            Terminal.print("Type :q to quit".dim(enabled: useColor))
            Terminal.print("")
        }

        let startIndex = skipTo.flatMap { skip in
            events.firstIndex { $0.t >= skip }
        } ?? 0

        let filteredEvents = Array(events[startIndex...])

        let player: EventPlayer
        do {
            player = try EventPlayer(events: filteredEvents)
        } catch {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        }

        var eventsPlayed = 0
        var cancellables = Set<AnyCancellable>()
        var isInterrupted = false

        let stdinReader = StdinReader()
        await stdinReader.start()

        SignalHandler.shared.setup { [player] in
            Task { @MainActor in
                player.stop()
                isInterrupted = true
            }
            Terminal.print("")
            Terminal.print("Interrupted")
        }

        defer {
            SignalHandler.shared.restore()
            Task { await stdinReader.stop() }
        }

        player.eventSubject.sink { event in
            let output = formatter.formatEvent(event, elapsedMs: event.t)
            Terminal.print(output)
            eventsPlayed += 1
        }.store(in: &cancellables)

        player.start()

        while !player.isCompleted && !isInterrupted {
            if await stdinReader.checkForQuit() {
                player.stop()
                isInterrupted = true
                Terminal.print("")
                Terminal.print("Quit")
                break
            }
            try await Task.sleep(nanoseconds: 100_000_000)
        }

        await stdinReader.stop()

        if !options.quiet && !isInterrupted {
            Terminal.print("")
            let footer = formatter.formatPlaybackFooter(
                eventsPlayed: eventsPlayed,
                durationMs: durationMs
            )
            Terminal.print(footer)
        }
    }
}
