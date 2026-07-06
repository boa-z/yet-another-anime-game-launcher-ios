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
            nextState.virtualInstallMetadata = VirtualInstallMetadata(client: descriptor, gameVersion: descriptor.latestVersion)
        case .importExisting:
            nextState = stateAfterImport(currentState: currentState, context: context)
        case .update:
            if descriptor.updatableVersions.contains(currentState.currentVersion) {
                nextState.currentVersion = descriptor.latestVersion
                nextState.predownloadedAll = false
                nextState.predownloadedArchiveKeys = []
                nextState.requiresPatchRevert = false
                nextState.virtualInstallMetadata = VirtualInstallMetadata(client: descriptor, gameVersion: descriptor.latestVersion)
            } else {
                nextState = .empty
            }
        case .predownload:
            nextState.predownloadedAll = true
            nextState.predownloadedArchiveKeys = PredownloadArchiveMarker.markers(for: descriptor).map(\.key).sorted()
        case .launch, .checkIntegrity, .initEnvironment:
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
                virtualInstallMetadata: VirtualInstallMetadata(client: descriptor, gameVersion: descriptor.latestVersion),
                predownloadedArchiveKeys: []
            )
        case .unreadable:
            return currentState
        case .existing(let version, let metadata):
            let detectedVersion = SemanticVersion(version)
            let latestVersion = SemanticVersion(descriptor.latestVersion)
            guard detectedVersion >= latestVersion || descriptor.updatableVersions.contains(version) else {
                return currentState
            }

            return ChannelClientState(
                installState: .installed,
                installDirectory: context.installDirectory.isEmpty ? virtualInstallDirectory() : context.installDirectory,
                currentVersion: version,
                predownloadedAll: false,
                requiresPatchRevert: false,
                virtualInstallMetadata: metadata ?? VirtualInstallMetadata(client: descriptor, gameVersion: version),
                predownloadedArchiveKeys: []
            )
        }
    }
}
