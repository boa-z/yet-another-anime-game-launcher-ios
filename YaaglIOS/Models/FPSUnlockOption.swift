import Foundation

enum FPSUnlockOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case disabled
    case hz120
    case hz144

    var id: String { rawValue }

    var title: String {
        switch self {
        case .disabled:
            "Disabled"
        case .hz120:
            "120 Hz"
        case .hz144:
            "144 Hz"
        }
    }
}

