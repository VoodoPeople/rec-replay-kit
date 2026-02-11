import ArgumentParser
import Foundation
import RecReplayKit

enum OutputFormat: String, ExpressibleByArgument, CaseIterable {
    case text
    case json
}

protocol OutputFormatter {
    var useColor: Bool { get }

    func formatValidationResult(_ result: EventValidator.ValidationResult, events: [Event]) -> String
    func formatScenarioInfo(_ scenario: Scenario) -> String
    func formatEvent(_ event: Event, elapsedMs: Int) -> String
    func formatPlaybackHeader(file: String, eventCount: Int, durationMs: Int) -> String
    func formatPlaybackFooter(eventsPlayed: Int, durationMs: Int) -> String
    func formatError(_ error: Error) -> String
}

func createFormatter(format: OutputFormat, useColor: Bool) -> OutputFormatter {
    switch format {
    case .text:
        return TextFormatter(useColor: useColor)
    case .json:
        return JsonFormatter()
    }
}
