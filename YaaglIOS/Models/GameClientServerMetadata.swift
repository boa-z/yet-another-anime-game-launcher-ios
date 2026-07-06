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
    let manifestURL: String?
    let dlcBaseURL: String?
    let manifestVersion: String?
    let manifestPathOffset: String?
    let manifestPakCount: Int?
    let manifestPayloadBytes: Int?
    let desktopServerChannel: String?
    let backgroundURL: String?
    let compatibilityNote: String?

    init(
        channelID: Int,
        subchannelID: Int,
        cpsReference: String,
        launcherUpdateResourceID: String,
        desktopDefaultWineDistributionID: String,
        blockNetHost: String?,
        blockNetDurationSeconds: Int?,
        removedFiles: [String],
        manifestURL: String? = nil,
        dlcBaseURL: String? = nil,
        manifestVersion: String? = nil,
        manifestPathOffset: String? = nil,
        manifestPakCount: Int? = nil,
        manifestPayloadBytes: Int? = nil,
        desktopServerChannel: String? = nil,
        backgroundURL: String? = nil,
        compatibilityNote: String? = nil
    ) {
        self.channelID = channelID
        self.subchannelID = subchannelID
        self.cpsReference = cpsReference
        self.launcherUpdateResourceID = launcherUpdateResourceID
        self.desktopDefaultWineDistributionID = desktopDefaultWineDistributionID
        self.blockNetHost = blockNetHost
        self.blockNetDurationSeconds = blockNetDurationSeconds
        self.removedFiles = removedFiles
        self.manifestURL = manifestURL
        self.dlcBaseURL = dlcBaseURL
        self.manifestVersion = manifestVersion
        self.manifestPathOffset = manifestPathOffset
        self.manifestPakCount = manifestPakCount
        self.manifestPayloadBytes = manifestPayloadBytes
        self.desktopServerChannel = desktopServerChannel
        self.backgroundURL = backgroundURL
        self.compatibilityNote = compatibilityNote
    }

    var cpsDisplayValue: String {
        cpsReference.isEmpty ? "" : "<\(cpsReference)>"
    }

    var manifestSummary: String? {
        guard let manifestURL,
              let dlcBaseURL,
              let manifestVersion,
              let manifestPathOffset,
              let manifestPakCount
        else {
            return nil
        }

        let payloadSummary = manifestPayloadBytes.map { " payload_bytes=\($0)" } ?? ""
        return "manifest=\(manifestURL) dlc=\(dlcBaseURL) version=\(manifestVersion) pathOffset=\(manifestPathOffset) paks=\(manifestPakCount)\(payloadSummary)"
    }
}
