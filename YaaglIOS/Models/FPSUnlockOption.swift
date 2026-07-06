import Foundation

enum FPSUnlockOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case disabled = "default"
    case hz120 = "120"
    case hz144 = "144"

    var id: String { rawValue }

    static func option(forStoredValue value: String?) -> FPSUnlockOption? {
        switch value {
        case "disabled":
            .disabled
        case "hz120":
            .hz120
        case "hz144":
            .hz144
        case let value?:
            FPSUnlockOption(rawValue: value)
        case nil:
            nil
        }
    }

    var title: String {
        switch self {
        case .disabled:
            "Disabled"
        case .hz120:
            "120Hz"
        case .hz144:
            "144Hz"
        }
    }
}
