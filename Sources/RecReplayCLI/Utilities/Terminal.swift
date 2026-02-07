import Foundation

enum Terminal {
    static func flush() {
        fflush(stdout)
    }

    static func print(_ message: String, terminator: String = "\n") {
        Swift.print(message, terminator: terminator)
        flush()
    }

    static func printError(_ message: String) {
        fputs(message + "\n", stderr)
    }

    static func isInteractive() -> Bool {
        isatty(STDOUT_FILENO) != 0
    }
}
