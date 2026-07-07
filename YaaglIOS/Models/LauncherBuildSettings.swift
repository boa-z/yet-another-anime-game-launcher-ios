import Foundation

nonisolated enum LauncherBuildSettings {
    static var advancedSettingsUnlockEnabled: Bool {
        if let value = Bundle.main.object(forInfoDictionaryKey: "YAAGL_ADVANCED_ENABLE") as? String {
            return value == "1"
        }

        if let value = Bundle.main.object(forInfoDictionaryKey: "YAAGL_ADVANCED_ENABLE") as? NSNumber {
            return value.intValue == 1
        }

        return ProcessInfo.processInfo.environment["YAAGL_ADVANCED_ENABLE"] == "1"
    }
}
