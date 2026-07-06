import Foundation

nonisolated struct LauncherUpdateMetadata: Equatable, Sendable {
    let version: String
    let releaseBody: String
    let resourceID: String
    let resourceAssetName: String
    let downloadURL: String
    let sidecarAssetName: String?
    let sidecarDownloadURL: String?

    var displaySummary: String {
        "\(version) (\(resourceAssetName))"
    }

    var isDownloadableMetadata: Bool {
        !downloadURL.isEmpty
    }

    static func resourceAssetName(for resourceID: String) -> String {
        "resources_\(resourceID).neu"
    }

    static func sidecarAssetName(for resourceID: String) -> String? {
        switch resourceID {
        case "hk4ecn":
            "Yaagl.app.tar.gz"
        case "hk4eos":
            "Yaagl.OS.app.tar.gz"
        case "bh3glb":
            "Yaagl.Honkai.Global.app.tar.gz"
        case "hkrpgcn":
            "Yaagl.HSR.app.tar.gz"
        case "hkrpgos":
            "Yaagl.HSR.OS.app.tar.gz"
        case "napcn":
            "Yaagl.ZZZ.app.tar.gz"
        case "napos":
            "Yaagl.ZZZ.OS.app.tar.gz"
        default:
            nil
        }
    }
}

nonisolated enum LauncherUpdateCheckResult: Equatable, Sendable {
    case available(LauncherUpdateMetadata)
    case latest(resourceID: String)
    case unavailable
}
