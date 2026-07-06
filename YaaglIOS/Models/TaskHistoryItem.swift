import Foundation

struct TaskHistoryItem: Identifiable, Equatable, Sendable {
    let id: UUID
    let date: Date
    let action: LauncherAction
    let message: String

    init(
        id: UUID = UUID(),
        date: Date = .now,
        action: LauncherAction,
        message: String
    ) {
        self.id = id
        self.date = date
        self.action = action
        self.message = message
    }
}

