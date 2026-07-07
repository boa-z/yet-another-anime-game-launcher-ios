import Foundation

struct VirtualInstallManifestMetadata: Codable, Hashable, Sendable {
    struct Pak: Codable, Hashable, Sendable {
        var name: String
        var hash: String
        var sizeInBytes: Int64
        var bPrimary: Bool
        var base: String
        var diff: String
        var diffSizeBytes: String

        init(
            name: String,
            hash: String,
            sizeInBytes: Int64,
            bPrimary: Bool,
            base: String,
            diff: String,
            diffSizeBytes: String
        ) {
            self.name = name
            self.hash = hash
            self.sizeInBytes = sizeInBytes
            self.bPrimary = bPrimary
            self.base = base
            self.diff = diff
            self.diffSizeBytes = diffSizeBytes
        }
    }

    var manifestVersion: String
    var projectVersion: String
    var pathOffset: String
    var paks: [Pak]
    var sourceServerID: String
    var channel: String?
    var expectedPakCount: Int?
    var expectedPayloadBytes: Int64?

    var pakCount: Int {
        expectedPakCount ?? paks.count
    }

    var payloadBytes: Int64 {
        expectedPayloadBytes ?? paks.reduce(0) { $0 + $1.sizeInBytes }
    }

    init(
        manifestVersion: String,
        projectVersion: String,
        pathOffset: String,
        paks: [Pak],
        sourceServerID: String,
        channel: String?,
        expectedPakCount: Int? = nil,
        expectedPayloadBytes: Int64? = nil
    ) {
        self.manifestVersion = manifestVersion
        self.projectVersion = projectVersion
        self.pathOffset = pathOffset
        self.paks = paks
        self.sourceServerID = sourceServerID
        self.channel = channel
        self.expectedPakCount = expectedPakCount
        self.expectedPayloadBytes = expectedPayloadBytes
    }

    init?(client: GameClientDescriptor, projectVersion: String) {
        guard let manifestVersion = client.server.manifestVersion,
              let pathOffset = client.server.manifestPathOffset,
              let pakCount = client.server.manifestPakCount,
              let payloadBytes = client.server.manifestPayloadBytes
        else {
            return nil
        }

        self.init(
            manifestVersion: manifestVersion,
            projectVersion: projectVersion,
            pathOffset: pathOffset,
            paks: [],
            sourceServerID: client.serverID,
            channel: client.server.desktopServerChannel,
            expectedPakCount: pakCount,
            expectedPayloadBytes: Int64(payloadBytes)
        )
    }

    func applying(client: GameClientDescriptor) -> VirtualInstallManifestMetadata {
        VirtualInstallManifestMetadata(
            manifestVersion: manifestVersion,
            projectVersion: projectVersion,
            pathOffset: pathOffset,
            paks: paks,
            sourceServerID: client.serverID,
            channel: client.server.desktopServerChannel,
            expectedPakCount: expectedPakCount,
            expectedPayloadBytes: expectedPayloadBytes
        )
    }

    private enum CodingKeys: String, CodingKey {
        case manifestVersion = "version"
        case projectVersion
        case pathOffset
        case paks
        case sourceServerID
        case channel
        case expectedPakCount
        case expectedPayloadBytes
    }
}
