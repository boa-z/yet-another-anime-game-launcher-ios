import CryptoKit
import Foundation

struct PredownloadArchiveMarker: Equatable, Hashable, Sendable {
    let basename: String

    var key: String {
        "predownloaded_\(Self.sha1Prefix32(for: basename))"
    }

    static func markers(for client: GameClientDescriptor) -> [PredownloadArchiveMarker] {
        guard usesAria2ArchiveMarkers(client) else {
            return []
        }

        let targetVersion = client.predownloadVersion ?? client.latestVersion
        let versionPair = "\(client.currentSupportedVersion)_to_\(targetVersion)"

        return [
            PredownloadArchiveMarker(basename: "\(client.serverID)_\(versionPair)_game.zip"),
            PredownloadArchiveMarker(basename: "\(client.serverID)_\(versionPair)_voice_pack.zip")
        ]
    }

    private static func usesAria2ArchiveMarkers(_ client: GameClientDescriptor) -> Bool {
        switch client.gameType {
        case "nap", "hkrpg", "bh3":
            true
        default:
            false
        }
    }

    private static func sha1Prefix32(for basename: String) -> String {
        let hash = Insecure.SHA1.hash(data: Data(basename.utf8))
        let hexDigits = Array("0123456789abcdef".utf8)
        let bytes = hash.flatMap { byte in
            [
                hexDigits[Int(byte >> 4)],
                hexDigits[Int(byte & 0x0f)]
            ]
        }

        return String(decoding: bytes.prefix(32), as: UTF8.self)
    }
}
