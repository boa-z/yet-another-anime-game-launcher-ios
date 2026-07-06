import Foundation

enum TaskStatus: Equatable, Sendable {
    case idle
    case running(LauncherAction)
    case completed(LauncherAction)
    case failed(String)
}

