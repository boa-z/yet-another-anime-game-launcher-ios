import Foundation

enum UILocaleOption: String, CaseIterable, Identifiable, Codable, Sendable {
    case simplifiedChinese = "zh_cn"
    case english = "en"
    case vietnamese = "vi_vn"
    case spanish = "es_es"
    case french = "fr_FR"
    case russian = "ru_ru"
    case japanese = "ja_jp"
    case korean = "ko_kr"
    case german = "de_de"
    case thai = "th_th"

    var id: String { rawValue }

    static var defaultOption: UILocaleOption {
        option(matchingSystemIdentifier: Locale.autoupdatingCurrent.identifier) ?? .english
    }

    static func option(forStoredValue value: String?) -> UILocaleOption? {
        switch value {
        case "simplifiedChinese":
            .simplifiedChinese
        case "english":
            .english
        case "japanese":
            .japanese
        case "korean":
            .korean
        case "french":
            .french
        case "german":
            .german
        case "spanish":
            .spanish
        case "thai":
            .thai
        case "vietnamese":
            .vietnamese
        case "russian":
            .russian
        case let value?:
            UILocaleOption(rawValue: value)
        case nil:
            nil
        }
    }

    static func option(matchingSystemIdentifier identifier: String) -> UILocaleOption? {
        let normalizedIdentifier = identifier.replacing("_", with: "-").lowercased()
        if normalizedIdentifier.hasPrefix("zh") {
            return .simplifiedChinese
        }

        return allCases.first { option in
            let normalizedRawValue = option.rawValue.replacing("_", with: "-").lowercased()
            return normalizedIdentifier == normalizedRawValue
                || normalizedIdentifier.hasPrefix("\(normalizedRawValue)-")
        }
    }

    var title: String {
        switch self {
        case .simplifiedChinese:
            "简体中文"
        case .english:
            "English"
        case .vietnamese:
            "Tiếng Việt"
        case .spanish:
            "Español"
        case .french:
            "Français"
        case .russian:
            "Русский"
        case .japanese:
            "日本語"
        case .korean:
            "한국어"
        case .german:
            "Deutsch"
        case .thai:
            "ไทย"
        }
    }
}
