import ArgumentParser
import Foundation
import RecReplayKit

@main
struct RecReplay: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "recreplay",
        abstract: "BLE scenario recorder and player CLI",
        version: "1.0.0",
        subcommands: [
            Validate.self,
            Info.self,
            Play.self,
            Convert.self
        ],
        defaultSubcommand: Info.self
    )
}

// MARK: - Shared Options

struct GlobalOptions: ParsableArguments {
    @Option(name: .long, help: "Output format (text or json)")
    var format: OutputFormat = .text

    @Flag(name: .long, help: "Disable colored output")
    var noColor: Bool = false

    @Flag(name: .long, help: "Suppress non-essential output")
    var quiet: Bool = false
}

struct ScenarioFileArgument: ParsableArguments {
    @Argument(help: "Path to the scenario JSON file")
    var path: String

    func loadScenario() throws -> Scenario {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Scenario.self, from: data)
    }

    func loadEvents() throws -> [Event] {
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)

        if let scenario = try? JSONDecoder().decode(Scenario.self, from: data) {
            return scenario.events
        }

        return try JSONDecoder().decode([Event].self, from: data)
    }
}
