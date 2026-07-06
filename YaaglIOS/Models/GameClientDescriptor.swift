import Foundation

struct GameClientDescriptor: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let shortTitle: String
    let region: String
    let serverID: String
    let gameType: String
    let releaseType: String
    let productName: String
    let executable: String
    let dataDirectory: String
    let latestVersion: String
    let currentSupportedVersion: String
    let updatableVersions: [String]
    let predownloadVersion: String?
    let predownloadAvailable: Bool
    let installSize: String
    let accentHex: String
    let secondaryHex: String
    let launchButtonLocation: LaunchButtonLocation
}

