import XCTest
@testable import YaaglIOS

final class LauncherTaskQueueTests: XCTestCase {
    @MainActor
    func testReturnsBusyWhileTaskIsRunning() async {
        let queue = LauncherTaskQueue()
        var started = false
        let firstTask = Task { @MainActor in
            await queue.run(
                action: .install,
                program: Self.delayedProgram(),
                onStart: { started = true },
                onCommand: { _ in },
                onFailure: { _ in },
                onFinish: { }
            )
        }

        while !started {
            await Task.yield()
        }

        let busyResult = await queue.run(
            action: .update,
            program: Self.succeedingProgram(),
            onStart: { XCTFail("Busy queue should not start a second task") },
            onCommand: { _ in },
            onFailure: { _ in },
            onFinish: { }
        )
        let firstResult = await firstTask.value

        XCTAssertEqual(busyResult, .busy)
        XCTAssertEqual(firstResult, .completed)
    }

    @MainActor
    func testFailureReleasesQueueForNextTask() async {
        let queue = LauncherTaskQueue()

        let failedResult = await queue.run(
            action: .install,
            program: Self.failingProgram(),
            onStart: { },
            onCommand: { _ in },
            onFailure: { _ in },
            onFinish: { XCTFail("Failing task should not finish successfully") }
        )

        let completedResult = await queue.run(
            action: .update,
            program: Self.succeedingProgram(),
            onStart: { },
            onCommand: { _ in },
            onFailure: { _ in },
            onFinish: { }
        )

        if case .failed = failedResult {
            XCTAssertEqual(completedResult, .completed)
        } else {
            XCTFail("Expected failed result")
        }
    }

    private static func delayedProgram() -> CommonUpdateProgram {
        CommonUpdateProgram { continuation in
            Task {
                continuation.yield(.setStateText("Holding queue"))
                try? await Task.sleep(for: .milliseconds(80))
                continuation.finish()
            }
        }
    }

    private static func succeedingProgram() -> CommonUpdateProgram {
        CommonUpdateProgram { continuation in
            continuation.yield(.setProgress(1))
            continuation.yield(.setVirtualPatchState(false))
            continuation.finish()
        }
    }

    private static func failingProgram() -> CommonUpdateProgram {
        CommonUpdateProgram { continuation in
            continuation.finish(throwing: QueueTestError.failure)
        }
    }
}

private enum QueueTestError: Error {
    case failure
}
