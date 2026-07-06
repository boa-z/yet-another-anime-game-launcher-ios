import Foundation

@MainActor
final class LauncherTaskQueue {
    private var isRunning = false

    func run(
        action: LauncherAction,
        program: CommonUpdateProgram,
        onStart: () -> Void,
        onCommand: (ProgressCommand) -> Void,
        onFailure: (String) -> Void,
        onFinish: () -> Void
    ) async -> LauncherTaskQueueResult {
        guard !isRunning else {
            return .busy
        }

        isRunning = true
        defer {
            isRunning = false
        }

        onStart()

        do {
            for try await command in program {
                onCommand(command)
            }

            onFinish()
            return .completed
        } catch {
            let message = error.localizedDescription
            onFailure(message)
            return .failed(message)
        }
    }
}
