import Foundation

enum SettingsTab: String, CaseIterable, Identifiable {
    case general
    case game
    case wine
    case advanced
    case licenses

    var id: String { rawValue }

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

