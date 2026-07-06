import Foundation

struct VirtualInstallMetadata: Equatable, Sendable {
    var gameVersion: String
    var channelID: Int
    var subchannelID: Int
    var cpsReference: String
    var sourceServerID: String

    init(
        gameVersion: String,
        channelID: Int,
        subchannelID: Int,
        cpsReference: String,
        sourceServerID: String
    ) {
        self.gameVersion = gameVersion
        self.channelID = channelID
        self.subchannelID = subchannelID
        self.cpsReference = cpsReference
        self.sourceServerID = sourceServerID
    }

    init(client: GameClientDescriptor, gameVersion: String) {
        self.init(
            gameVersion: gameVersion,
            channelID: client.server.channelID,
            subchannelID: client.server.subchannelID,
            cpsReference: client.server.cpsReference,
            sourceServerID: client.serverID
        )
    }
}
