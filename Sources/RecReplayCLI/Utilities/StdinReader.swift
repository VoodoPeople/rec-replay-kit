import Foundation

actor StdinReader {
    private var buffer: String = ""
    private var isRunning = false
    private var readTask: Task<Void, Never>?

    func start() {
        guard !isRunning else { return }
        isRunning = true

        readTask = Task.detached { [weak self] in
            let handle = FileHandle.standardInput

            while await self?.isRunning == true {
                let data = handle.availableData
                if !data.isEmpty, let str = String(data: data, encoding: .utf8) {
                    await self?.appendToBuffer(str)
                }
                try? await Task.sleep(nanoseconds: 50_000_000)
            }
        }
    }

    func stop() {
        isRunning = false
        readTask?.cancel()
        readTask = nil
    }

    func checkForQuit() -> Bool {
        if buffer.contains(":q") || buffer.contains(":quit") {
            return true
        }
        return false
    }

    func clearBuffer() {
        buffer = ""
    }

    private func appendToBuffer(_ str: String) {
        buffer += str
    }
}
