import Foundation

enum LauncherAction: String, Identifiable, Sendable {
    case install
    case importExisting
    case update
    case launch
    case predownload
    case checkIntegrity
    case initEnvironment
    case checkLauncherUpdate

    var id: String { rawValue }

    var title: String {
        switch self {
        case .install:
            "Install Game"
        case .importExisting:
            "Import Existing Game"
        case .update:
            "Update Game"
        case .launch:
            "Launch Game"
        case .predownload:
            "Pre-download"
        case .checkIntegrity:
            "Check Integrity"
        case .initEnvironment:
            "Initialize"
        case .checkLauncherUpdate:
            "Check YAAGL Updates"
        }
    }

    var systemImage: String {
        switch self {
        case .install:
            "square.and.arrow.down"
        case .importExisting:
            "folder.badge.gearshape"
        case .update:
            "arrow.triangle.2.circlepath"
        case .launch:
            "play.fill"
        case .predownload:
            "tray.and.arrow.down"
        case .checkIntegrity:
            "checkmark.shield"
        case .initEnvironment:
            "wrench.and.screwdriver"
        case .checkLauncherUpdate:
            "sparkle.magnifyingglass"
        }
    }
}
