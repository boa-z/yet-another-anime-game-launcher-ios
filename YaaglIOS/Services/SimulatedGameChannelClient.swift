import Foundation

struct SimulatedGameChannelClient: GameChannelClient {
    let descriptor: GameClientDescriptor

    private let simulationService: LauncherSimulationService

    init(
        descriptor: GameClientDescriptor,
        simulationService: LauncherSimulationService = LauncherSimulationService()
    ) {
        self.descriptor = descriptor
        self.simulationService = simulationService
    }

    func updateRequired(in state: ChannelClientState) -> Bool {
        state.installState == .installed && SemanticVersion(state.currentVersion) < SemanticVersion(descriptor.latestVersion)
    }

    func showPredownloadPrompt(in state: ChannelClientState) -> Bool {
        guard state.installState == .installed,
              descriptor.predownloadAvailable,
              let version = descriptor.predownloadVersion
        else {
            return false
        }

        return !state.predownloadedAll && SemanticVersion(version) > SemanticVersion(state.currentVersion)
    }

    func predownloadTitle(in state: ChannelClientState) -> String {
        if let version = descriptor.predownloadVersion, showPredownloadPrompt(in: state) {
            "Pre-download \(version)"
        } else {
            "Pre-download"
        }
    }

    func virtualInstallDirectory() -> String {
        "iOS Sandbox/VirtualGameData/\(descriptor.id)"
    }

    func program(for action: LauncherAction, context: GameChannelClientContext) -> CommonUpdateProgram {
        simulationService.makeProgram(
            action: action,
            client: descriptor,
            configuration: context.configuration,
            installDirectory: context.installDirectory,
            state: context.state,
            importProbeResult: context.importProbeResult
        )
    }

    func state(
        after action: LauncherAction,
        currentState: ChannelClientState,
        context: GameChannelClientContext
    ) -> ChannelClientState {
        var nextState = currentState

        switch action {
        case .install:
            nextState.installState = .installed
            nextState.installDirectory = context.installDirectory.isEmpty ? virtualInstallDirectory() : context.installDirectory
            nextState.currentVersion = descriptor.latestVersion
            nextState.predownloadedAll = false
            nextState.predownloadedArchiveKeys = []
            nextState.requiresPatchRevert = false
            applyVirtualMetadata(to: &nextState, version: descriptor.latestVersion, useDescriptorManifestFallback: true)
        case .importExisting:
            nextState = stateAfterImport(currentState: currentState, context: context)
        case .update:
            if canUpdate(from: currentState.currentVersion) {
                nextState.currentVersion = descriptor.latestVersion
                nextState.predownloadedAll = false
                nextState.predownloadedArchiveKeys = []
                nextState.requiresPatchRevert = false
                applyVirtualMetadata(to: &nextState, version: descriptor.latestVersion, useDescriptorManifestFallback: true)
            } else {
                nextState = .empty
            }
        case .predownload:
            nextState.predownloadedAll = true
            nextState.predownloadedArchiveKeys = PredownloadArchiveMarker.markers(for: descriptor).map(\.key).sorted()
        case .launch:
            guard !launchBlockedByUnsupportedVersion(state: currentState, configuration: context.configuration) else {
                break
            }
            nextState.requiresPatchRevert = false
        case .checkIntegrity, .initEnvironment:
            nextState.requiresPatchRevert = false
        case .checkLauncherUpdate, .settingsQuickAction:
            break
        }

        return nextState
    }

    private func stateAfterImport(
        currentState: ChannelClientState,
        context: GameChannelClientContext
    ) -> ChannelClientState {
        guard let importProbeResult = context.importProbeResult else {
            return currentState
        }

        switch importProbeResult {
        case .newTarget:
            return ChannelClientState(
                installState: .installed,
                installDirectory: context.installDirectory.isEmpty ? virtualInstallDirectory() : context.installDirectory,
                currentVersion: descriptor.latestVersion,
                predownloadedAll: false,
                requiresPatchRevert: false,
                virtualInstallMetadata: virtualConfigMetadata(version: descriptor.latestVersion),
                virtualManifestMetadata: virtualManifestMetadata(
                    version: descriptor.latestVersion,
                    useDescriptorFallback: true
                ),
                predownloadedArchiveKeys: []
            )
        case .unreadable:
            return currentState
        case .existing(let version, let metadata, let manifestMetadata):
            let detectedVersion = SemanticVersion(version)
            let latestVersion = SemanticVersion(descriptor.latestVersion)
            guard !descriptor.isAboveDesktopSupportedVersion(version) else {
                return currentState
            }
            guard detectedVersion >= latestVersion || canUpdate(from: version) else {
                return currentState
            }

            return ChannelClientState(
                installState: .installed,
                installDirectory: context.installDirectory.isEmpty ? virtualInstallDirectory() : context.installDirectory,
                currentVersion: version,
                predownloadedAll: false,
                requiresPatchRevert: false,
                virtualInstallMetadata: virtualConfigMetadata(version: version, metadata: metadata),
                virtualManifestMetadata: virtualManifestMetadata(
                    version: version,
                    manifestMetadata: manifestMetadata,
                    useDescriptorFallback: false
                ),
                predownloadedArchiveKeys: []
            )
        }
    }

    private func applyVirtualMetadata(
        to state: inout ChannelClientState,
        version: String,
        useDescriptorManifestFallback: Bool
    ) {
        state.virtualInstallMetadata = virtualConfigMetadata(version: version)
        state.virtualManifestMetadata = virtualManifestMetadata(
            version: version,
            useDescriptorFallback: useDescriptorManifestFallback
        )
    }

    private func virtualConfigMetadata(
        version: String,
        metadata: VirtualInstallMetadata? = nil
    ) -> VirtualInstallMetadata? {
        if descriptor.gameType == "cbjq" {
            return nil
        }
        return metadata ?? VirtualInstallMetadata(client: descriptor, gameVersion: version)
    }

    private func virtualManifestMetadata(
        version: String,
        manifestMetadata: VirtualInstallManifestMetadata? = nil,
        useDescriptorFallback: Bool
    ) -> VirtualInstallManifestMetadata? {
        guard descriptor.gameType == "cbjq" else {
            return nil
        }
        if let manifestMetadata {
            return manifestMetadata
        }
        if let manifestMetadata = descriptor.seasunManifestMetadata {
            return manifestMetadata
        }
        guard useDescriptorFallback else {
            return nil
        }
        return VirtualInstallManifestMetadata(client: descriptor, projectVersion: version)
    }

    private func canUpdate(from version: String) -> Bool {
        if descriptor.gameType == "cbjq" {
            SemanticVersion(version) <= SemanticVersion(descriptor.currentSupportedVersion)
        } else {
            descriptor.updatableVersions.contains(version)
        }
    }

    private func launchBlockedByUnsupportedVersion(
        state: ChannelClientState,
        configuration: LauncherConfigurationSnapshot
    ) -> Bool {
        let patchOffBypassesGuard = descriptor.gameSettingsCapabilities.patchOff && configuration.patchOff
        return descriptor.isAboveDesktopSupportedVersion(state.currentVersion)
            && !patchOffBypassesGuard
    }
}
