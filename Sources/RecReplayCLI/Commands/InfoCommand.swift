import ArgumentParser
import Foundation
import RecReplayKit

struct Info: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Display scenario metadata and statistics"
    )

    @OptionGroup var options: GlobalOptions
    @OptionGroup var file: ScenarioFileArgument

    func run() throws {
        let formatter = createFormatter(
            format: options.format,
            useColor: !options.noColor && Terminal.isInteractive()
        )

        do {
            let scenario = try file.loadScenario()
            let output = formatter.formatScenarioInfo(scenario)
            Terminal.print(output)
        } catch let error as DecodingError {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        }
    }
}
