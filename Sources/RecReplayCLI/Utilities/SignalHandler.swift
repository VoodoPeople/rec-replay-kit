import Foundation

final class SignalHandler: @unchecked Sendable {
    private var handler: (() -> Void)?
    private var previousHandler: (@convention(c) (Int32) -> Void)?

    static let shared = SignalHandler()

    private init() {}

    func setup(handler: @escaping () -> Void) {
        self.handler = handler
        previousHandler = signal(SIGINT) { _ in
            SignalHandler.shared.handleSignal()
        }
    }

    func restore() {
        if let previous = previousHandler {
            signal(SIGINT, previous)
        } else {
            signal(SIGINT, SIG_DFL)
        }
        handler = nil
        previousHandler = nil
    }

    private func handleSignal() {
        handler?()
    }
}
