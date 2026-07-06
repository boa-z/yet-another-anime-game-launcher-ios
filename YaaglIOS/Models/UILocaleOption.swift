import Foundation

enum UILocaleOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case simplifiedChinese
    case english
    case japanese
    case korean
    case french
    case german
    case spanish
    case thai
    case vietnamese
    case russian

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simplifiedChinese:
            "简体中文"
        case .english:
            "English"
        case .japanese:
            "日本語"
        case .korean:
            "한국어"
        case .french:
            "Français"
        case .german:
            "Deutsch"
        case .spanish:
            "Español"
        case .thai:
            "ไทย"
        case .vietnamese:
            "Tiếng Việt"
        case .russian:
            "Русский"
        }
    }
}

