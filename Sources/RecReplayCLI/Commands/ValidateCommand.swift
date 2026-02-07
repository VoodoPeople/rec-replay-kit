import ArgumentParser
import Foundation
import RecReplayKit

struct Validate: ParsableCommand {
    static let configuration = CommandConfiguration(
        abstract: "Validate a scenario or events JSON file"
    )

    @OptionGroup var options: GlobalOptions
    @OptionGroup var file: ScenarioFileArgument

    func run() throws {
        let formatter = createFormatter(
            format: options.format,
            useColor: !options.noColor && Terminal.isInteractive()
        )

        do {
            let events = try file.loadEvents()
            let result = EventValidator.validateWithResult(events: events)

            let output = formatter.formatValidationResult(result, events: events)
            Terminal.print(output)

            if !result.isValid {
                throw ExitCode.failure
            }
        } catch let error as DecodingError {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        } catch let error as EventValidator.ValidationError {
            Terminal.printError(formatter.formatError(error))
            throw ExitCode.failure
        }
    }
}
