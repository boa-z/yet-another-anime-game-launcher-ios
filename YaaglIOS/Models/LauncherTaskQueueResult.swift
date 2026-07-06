import Foundation

enum LauncherTaskQueueResult: Equatable, Sendable {
    case completed
    case busy
    case failed(String)
}

