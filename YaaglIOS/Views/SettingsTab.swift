import Foundation

nonisolated enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case game
    case wine
    case advanced
    case licenses

    var id: String { rawValue }

    static func visibleTabs(advancedVisible: Bool) -> [SettingsTab] {
        if advancedVisible {
            return [.general, .game, .wine, .advanced, .licenses]
        }

        return [.general, .game, .wine, .licenses]
    }

    var title: String {
        switch self {
        case .general:
            "General"
        case .game:
            "Game"
        case .wine:
            "Wine"
        case .advanced:
            "Advanced"
        case .licenses:
            "Licenses"
        }
    }
}
