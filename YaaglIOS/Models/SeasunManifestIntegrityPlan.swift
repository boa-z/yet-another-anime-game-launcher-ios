import Foundation

struct SeasunManifestIntegrityPlan: Equatable, Sendable {
    struct Entry: Equatable, Sendable {
        var remoteName: String
        var md5: String
        var fileSize: Int64
        var localPath: String
        var repairURL: String
    }

    var entries: [Entry]

    static func make(
        manifest: VirtualInstallManifestMetadata,
        gameDirectory: String,
        dlcBaseURL: String
    ) -> SeasunManifestIntegrityPlan {
        let entries = manifest.paks.map { pak in
            Entry(
                remoteName: pak.name,
                md5: pak.hash,
                fileSize: pak.sizeInBytes,
                localPath: SeasunManifestUpdatePlan.joinedPath(gameDirectory, pak.name),
                repairURL: SeasunManifestUpdatePlan.remoteResourceURL(
                    dlcBaseURL: dlcBaseURL,
                    pathOffset: manifest.pathOffset,
                    hash: pak.hash
                )
            )
        }

        return SeasunManifestIntegrityPlan(entries: entries)
    }
}
