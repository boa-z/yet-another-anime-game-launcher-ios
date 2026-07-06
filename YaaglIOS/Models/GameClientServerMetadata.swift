import Foundation

struct GameClientServerMetadata: Hashable, Sendable {
    let channelID: Int
    let subchannelID: Int
    let cpsReference: String
    let launcherUpdateResourceID: String
    let desktopDefaultWineDistributionID: String
    let blockNetHost: String?
    let blockNetDurationSeconds: Int?
    let removedFiles: [String]

    var cpsDisplayValue: String {
        cpsReference.isEmpty ? "" : "<\(cpsReference)>"
    }
}
