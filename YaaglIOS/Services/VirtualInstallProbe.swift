import Foundation

struct VirtualInstallProbe: Sendable {
    let probe: @Sendable (String, GameClientDescriptor, ChannelClientState) -> VirtualInstallProbeResult

    func result(
        for installDirectory: String,
        client: GameClientDescriptor,
        persistedState: ChannelClientState
    ) -> VirtualInstallProbeResult {
        probe(installDirectory, client, persistedState)
    }

    static let trustingPersistedRecord = VirtualInstallProbe { installDirectory, _, persistedState in
        guard persistedState.installState == .installed, !installDirectory.isEmpty else {
            return .newTarget
        }

        return .existing(
            version: persistedState.currentVersion,
            metadata: persistedState.virtualInstallMetadata,
            manifestMetadata: persistedState.virtualManifestMetadata
        )
    }
}
