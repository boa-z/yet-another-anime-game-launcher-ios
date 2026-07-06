import Foundation

nonisolated enum DesktopCommandSegment: Equatable, Sendable {
    case string(String)
    case raw(String)
    case nested([DesktopCommandSegment])

    static func rawString(_ value: String) -> DesktopCommandSegment {
        .raw(value)
    }
}
