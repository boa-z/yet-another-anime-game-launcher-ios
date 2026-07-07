import Foundation

struct SeasunManifestUpdatePlan: Equatable, Sendable {
    struct AddedPak: Equatable, Sendable {
        var remoteName: String
        var hash: String
        var localPath: String
        var remoteURL: String
    }

    struct RemovedPak: Equatable, Sendable {
        var localName: String
        var localPath: String
    }

    var addedPaks: [AddedPak]
    var removedPaks: [RemovedPak]

    static func make(
        local: VirtualInstallManifestMetadata,
        remote: VirtualInstallManifestMetadata,
        gameDirectory: String,
        dlcBaseURL: String
    ) -> SeasunManifestUpdatePlan {
        let localPaks = normalizedPaks(local.paks)
        let remotePaks = normalizedPaks(remote.paks)
        let localHashes = Set(localPaks.map(\.hash))
        let remoteHashes = Set(remotePaks.map(\.hash))

        let removedPaks = localPaks
            .filter { !remoteHashes.contains($0.hash) }
            .map { localPak in
                RemovedPak(
                    localName: localPak.pak.name,
                    localPath: joinedPath(gameDirectory, localPak.pak.name)
                )
            }
        let addedPaks = remotePaks
            .filter { !localHashes.contains($0.hash) }
            .map { remotePak in
                AddedPak(
                    remoteName: remotePak.pak.name,
                    hash: remotePak.hash,
                    localPath: joinedPath(gameDirectory, remotePak.pak.name),
                    remoteURL: remoteResourceURL(
                        dlcBaseURL: dlcBaseURL,
                        pathOffset: remote.pathOffset,
                        hash: remotePak.hash
                    )
                )
            }

        return SeasunManifestUpdatePlan(
            addedPaks: addedPaks,
            removedPaks: removedPaks
        )
    }

    private static func normalizedPaks(
        _ paks: [VirtualInstallManifestMetadata.Pak]
    ) -> [(hash: String, pak: VirtualInstallManifestMetadata.Pak)] {
        var orderedHashes = [String]()
        var paksByHash = [String: VirtualInstallManifestMetadata.Pak]()
        for pak in paks {
            if paksByHash[pak.hash] == nil {
                orderedHashes.append(pak.hash)
            }
            paksByHash[pak.hash] = pak
        }

        return orderedHashes.compactMap { hash in
            paksByHash[hash].map { (hash, $0) }
        }
    }

    static func joinedPath(_ base: String, _ component: String) -> String {
        let trimmedBase = base.trimmingTrailingSlashes()
        let trimmedComponent = component.trimmingSlashes()
        guard !trimmedBase.isEmpty else {
            return trimmedComponent
        }
        guard !trimmedComponent.isEmpty else {
            return trimmedBase
        }
        return "\(trimmedBase)/\(trimmedComponent)"
    }

    static func remoteResourceURL(
        dlcBaseURL: String,
        pathOffset: String,
        hash: String
    ) -> String {
        let base = dlcBaseURL.trimmingTrailingSlashes()
        let offset = pathOffset.trimmingSlashes()
        let resourceHash = hash.trimmingSlashes()
        if offset.isEmpty {
            return "\(base)/\(resourceHash)"
        }
        return "\(base)/\(offset)/\(resourceHash)"
    }
}

private extension String {
    func trimmingSlashes() -> String {
        trimmingCharacters(in: CharacterSet(charactersIn: "/"))
    }

    func trimmingTrailingSlashes() -> String {
        var value = self
        while value.hasSuffix("/") {
            value.removeLast()
        }
        return value
    }
}
