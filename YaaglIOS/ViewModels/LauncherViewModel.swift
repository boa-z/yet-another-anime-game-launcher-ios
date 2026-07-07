import Foundation
import Observation

@MainActor
@Observable
final class LauncherViewModel {
    let clients: [GameClientDescriptor]
    let configuration: LauncherConfiguration

    var selectedClientID: String {
        didSet {
            guard !isRevertingClientSelection else {
                return
            }

            guard oldValue != selectedClientID else {
                return
            }

            if isBusy || isBackgroundBusy {
                isRevertingClientSelection = true
                selectedClientID = oldValue
                isRevertingClientSelection = false
                alertMessage = "Finish the current task before switching clients."
                return
            }

            defaults.set(selectedClientID, forKey: Keys.selectedClientID)
            configuration.useDefaultWineDistribution(id: selectedClient.server.desktopDefaultWineDistributionID)
            configuration.useDefaultWorkaround3(selectedClient.desktopDefaultWorkaround3)
            restoreClientState()
        }
    }

    var installState: InstallState = .notInstalled
    var installDirectory = ""
    var currentVersion = "0.0.0"
    var statusText = "Ready"
    var progress: Double?
    var backgroundStatusText = ""
    var backgroundProgress: Double?
    var backgroundTaskStatus: TaskStatus = .idle
    var taskStatus: TaskStatus = .idle
    var showPredownloadPrompt = false
    var taskHistory: [TaskHistoryItem] = []
    var alertMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store: ChannelClientStore
    @ObservationIgnored private let taskQueue: LauncherTaskQueue
    @ObservationIgnored private let backgroundTaskQueue: LauncherTaskQueue
    @ObservationIgnored private let channelClients: [String: any GameChannelClient]
    @ObservationIgnored private let defaultChannelClient: any GameChannelClient
    @ObservationIgnored private let installProbe: VirtualInstallProbe
    @ObservationIgnored private let launcherUpdateService: LauncherUpdateMetadataService
    @ObservationIgnored private var dismissedPredownloadPromptClientIDs = Set<String>()
    @ObservationIgnored private var didInitializeEnvironment = false
    @ObservationIgnored private var isRevertingClientSelection = false

    init(
        defaults: UserDefaults = .standard,
        channelClients: [any GameChannelClient] = GameChannelClientFactory.makeDefaultClients(),
        installProbe: VirtualInstallProbe = .trustingPersistedRecord,
        launcherUpdateService: LauncherUpdateMetadataService = .live
    ) {
        let resolvedClients = channelClients.isEmpty ? GameChannelClientFactory.makeDefaultClients() : channelClients
        guard let defaultChannelClient = resolvedClients.first else {
            fatalError("YAAGL iOS requires at least one game channel client.")
        }

        self.defaults = defaults
        self.channelClients = Dictionary(uniqueKeysWithValues: resolvedClients.map { ($0.descriptor.id, $0) })
        self.defaultChannelClient = defaultChannelClient
        self.installProbe = installProbe
        self.launcherUpdateService = launcherUpdateService
        clients = resolvedClients.map(\.descriptor)
        let initialClientID: String
        if let savedClientID = defaults.string(forKey: Keys.selectedClientID),
           resolvedClients.contains(where: { $0.descriptor.id == savedClientID }) {
            initialClientID = savedClientID
        } else {
            initialClientID = defaultChannelClient.descriptor.id
        }
        let initialClient = self.channelClients[initialClientID] ?? defaultChannelClient
        configuration = LauncherConfiguration(
            defaults: defaults,
            defaultWineDistro: initialClient.descriptor.server.desktopDefaultWineDistributionID,
            defaultWorkaround3: initialClient.descriptor.desktopDefaultWorkaround3
        )
        store = ChannelClientStore(defaults: defaults)
        taskQueue = LauncherTaskQueue()
        backgroundTaskQueue = LauncherTaskQueue()
        selectedClientID = initialClientID
        restoreClientState()
    }

    var selectedClient: GameClientDescriptor {
        selectedChannelClient.descriptor
    }

    private var selectedChannelClient: any GameChannelClient {
        channelClients[selectedClientID] ?? defaultChannelClient
    }

    var isBusy: Bool {
        if case .running = taskStatus {
            true
        } else {
            false
        }
    }

    var isBackgroundBusy: Bool {
        if case .running = backgroundTaskStatus {
            true
        } else {
            false
        }
    }

    var isShowingAlert: Bool {
        get {
            alertMessage != nil
        }
        set {
            if !newValue {
                alertMessage = nil
            }
        }
    }

    var updateRequired: Bool {
        selectedChannelClient.updateRequired(in: currentState)
    }

    var primaryAction: LauncherAction {
        if installState == .notInstalled {
            .install
        } else if updateRequired {
            .update
        } else {
            .launch
        }
    }

    var predownloadTitle: String {
        selectedChannelClient.predownloadTitle(in: currentState)
    }

    func runPrimaryAction() async {
        await run(primaryAction)
    }

    func predownload() async {
        await runBackground(.predownload)
    }

    func checkIntegrity() async {
        await run(.checkIntegrity)
    }

    func checkLauncherUpdate() async {
        let channelClient = selectedChannelClient
        await run(.checkLauncherUpdate)
        guard taskStatus == .completed(.checkLauncherUpdate) else {
            return
        }

        await refreshLauncherUpdateMetadata(for: channelClient.descriptor)
    }

    func importExistingVirtualInstall(
        path: String,
        probeResult: VirtualInstallProbeResult
    ) async {
        let installDirectory = path.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !installDirectory.isEmpty else {
            alertMessage = "Import path is empty"
            appendHistory(.importExisting, "Import skipped: empty virtual install path")
            return
        }

        switch probeResult {
        case .newTarget:
            await run(.install, installDirectoryOverride: installDirectory)
        case .existing, .unreadable:
            await run(
                .importExisting,
                installDirectoryOverride: installDirectory,
                importProbeResult: probeResult
            )
        }
    }

    func initializeEnvironment() async {
        guard !didInitializeEnvironment else {
            return
        }

        didInitializeEnvironment = true
        await run(.initEnvironment)
    }

    func dismissPredownload() {
        dismissedPredownloadPromptClientIDs.insert(selectedClient.id)
        showPredownloadPrompt = false
    }

    func dismissAlert() {
        alertMessage = nil
    }

    func resetVirtualInstall() {
        store.clear(for: selectedClient.id)
        restoreClientState()
        appendHistory(.initEnvironment, "Virtual install record cleared")
    }

    func openWineCommandLineTool() {
        alertMessage = "Wine command line is unavailable in the iOS build."
        appendHistory(.settingsQuickAction, "settings quick action: Wine command line request was recorded; no shell was launched")
    }

    func openGameInstallDirectory() {
        let path = installDirectory.isEmpty ? selectedChannelClient.virtualInstallDirectory() : installDirectory
        alertMessage = "Game install directory open request was recorded for \(path)."
        appendHistory(.settingsQuickAction, "settings quick action: game install directory open request for \(path) was recorded; no external file manager was launched")
    }

    func openYaaglDataDirectory() {
        alertMessage = "YAAGL data directory open request was recorded for the iOS sandbox."
        appendHistory(.settingsQuickAction, "settings quick action: YAAGL data directory open request for iOS sandbox was recorded; no external file manager was launched")
    }

    private func run(
        _ action: LauncherAction,
        installDirectoryOverride: String? = nil,
        importProbeResult: VirtualInstallProbeResult? = nil
    ) async {
        let channelClient = selectedChannelClient
        let stateBeforeRun = currentState
        let installDirectory = installDirectoryOverride
            ?? (stateBeforeRun.installDirectory.isEmpty
                ? channelClient.virtualInstallDirectory()
                : stateBeforeRun.installDirectory)
        let context = GameChannelClientContext(
            configuration: configuration.snapshot,
            installDirectory: installDirectory,
            state: stateBeforeRun,
            importProbeResult: importProbeResult
        )

        let result = await taskQueue.run(
            action: action,
            program: channelClient.program(for: action, context: context),
            onStart: {
                taskStatus = .running(action)
                statusText = action.title
                progress = nil
            },
            onCommand: { command in
                handle(command, action: action, channelClient: channelClient, isBackground: false)
            },
            onFailure: { message in
                taskStatus = .failed(message)
                statusText = message
                alertMessage = message
                appendHistory(action, "\(action.title) failed: \(message)")
            },
            onFinish: {
                progress = 1
            }
        )

        switch result {
        case .completed:
            complete(
                action,
                channelClient: channelClient,
                stateBeforeRun: stateBeforeRun,
                context: context
            )
        case .busy:
            appendHistory(action, "\(action.title) ignored because another task is running")
        case .failed:
            break
        }
    }

    private func runBackground(_ action: LauncherAction) async {
        let channelClient = selectedChannelClient
        let stateBeforeRun = currentState
        let context = GameChannelClientContext(
            configuration: configuration.snapshot,
            installDirectory: stateBeforeRun.installDirectory.isEmpty
                ? channelClient.virtualInstallDirectory()
                : stateBeforeRun.installDirectory,
            state: stateBeforeRun
        )

        let result = await backgroundTaskQueue.run(
            action: action,
            program: channelClient.program(for: action, context: context),
            onStart: {
                backgroundTaskStatus = .running(action)
                backgroundStatusText = action.title
                backgroundProgress = nil
            },
            onCommand: { command in
                handle(command, action: action, channelClient: channelClient, isBackground: true)
            },
            onFailure: { message in
                backgroundTaskStatus = .failed(message)
                backgroundStatusText = message
                alertMessage = message
                appendHistory(action, "\(action.title) failed: \(message)")
            },
            onFinish: {
                backgroundProgress = 1
            }
        )

        switch result {
        case .completed:
            complete(
                action,
                channelClient: channelClient,
                stateBeforeRun: stateBeforeRun,
                context: context,
                isBackground: true
            )
        case .busy:
            appendHistory(action, "\(action.title) ignored because another background task is running")
        case .failed:
            break
        }
    }

    private func handle(
        _ command: ProgressCommand,
        action: LauncherAction,
        channelClient: any GameChannelClient,
        isBackground: Bool
    ) {
        switch command {
        case .setProgress(let value):
            setProgress(value, isBackground: isBackground)
        case .setUndeterminedProgress:
            setProgress(nil, isBackground: isBackground)
        case .setStateText(let text):
            setStatusText(text, isBackground: isBackground)
        case .appendLog(let message):
            appendHistory(action, message)
        case .setVirtualPatchState(let requiresPatchRevert):
            setVirtualPatchState(requiresPatchRevert, for: channelClient)
        }
    }

    private func complete(
        _ action: LauncherAction,
        channelClient: any GameChannelClient,
        stateBeforeRun: ChannelClientState,
        context: GameChannelClientContext,
        isBackground: Bool = false
    ) {
        let nextState = channelClient.state(
            after: action,
            currentState: completionBaseState(for: channelClient, stateBeforeRun: stateBeforeRun),
            context: context
        )
        store.save(nextState, for: channelClient.descriptor.id)

        if selectedClientID == channelClient.descriptor.id {
            apply(nextState, for: channelClient)
        }

        if action == .initEnvironment {
            configuration.completePendingWineUpdateSimulation()
        }

        if isBackground {
            backgroundProgress = 1
            backgroundTaskStatus = .completed(action)
        } else {
            progress = 1
            taskStatus = .completed(action)
        }
        if action == .launch, launchWasSkippedForUnsupportedVersion {
            alertMessage = statusText
        }
        appendHistory(action, completionMessage(for: action, before: stateBeforeRun, after: nextState))
    }

    private func restoreClientState() {
        let storedState = store.load(for: selectedClient.id)
        let restoredState = probedState(from: storedState, for: selectedChannelClient)
        if restoredState != storedState {
            store.save(restoredState, for: selectedClient.id)
        }

        apply(restoredState, for: selectedChannelClient)
        statusText = "Ready"
        progress = nil
        taskStatus = .idle
        backgroundStatusText = ""
        backgroundProgress = nil
        backgroundTaskStatus = .idle
    }

    private var currentState: ChannelClientState {
        ChannelClientState(
            installState: installState,
            installDirectory: installDirectory,
            currentVersion: currentVersion,
            predownloadedAll: persistedState.predownloadedAll,
            requiresPatchRevert: persistedState.requiresPatchRevert,
            virtualInstallMetadata: persistedState.virtualInstallMetadata,
            predownloadedArchiveKeys: persistedState.predownloadedArchiveKeys
        )
    }

    private func apply(_ state: ChannelClientState, for channelClient: any GameChannelClient) {
        installState = state.installState
        installDirectory = state.installDirectory
        currentVersion = state.currentVersion
        showPredownloadPrompt = !dismissedPredownloadPromptClientIDs.contains(channelClient.descriptor.id)
            && channelClient.showPredownloadPrompt(in: state)
    }

    private func probedState(
        from storedState: ChannelClientState,
        for channelClient: any GameChannelClient
    ) -> ChannelClientState {
        guard storedState.installState == .installed, !storedState.installDirectory.isEmpty else {
            return storedState
        }

        switch installProbe.result(
            for: storedState.installDirectory,
            client: channelClient.descriptor,
            persistedState: storedState
        ) {
        case .existing(let version, let metadata):
            var refreshedState = storedState
            refreshedState.currentVersion = version
            refreshedState.virtualInstallMetadata = metadata ?? VirtualInstallMetadata(
                client: channelClient.descriptor,
                gameVersion: version
            )
            return refreshedState
        case .newTarget, .unreadable:
            return .empty
        }
    }

    private var persistedState: ChannelClientState {
        store.load(for: selectedClient.id)
    }

    private func completionBaseState(
        for channelClient: any GameChannelClient,
        stateBeforeRun: ChannelClientState
    ) -> ChannelClientState {
        var baseState = store.load(for: channelClient.descriptor.id)
        baseState.installState = stateBeforeRun.installState
        baseState.installDirectory = stateBeforeRun.installDirectory
        baseState.currentVersion = stateBeforeRun.currentVersion
        return baseState
    }

    private func setStatusText(_ text: String, isBackground: Bool) {
        if isBackground {
            backgroundStatusText = text
        } else {
            statusText = text
        }
    }

    private func setProgress(_ value: Double?, isBackground: Bool) {
        let displayValue: Double? = if let value, value > 0 {
            value
        } else {
            nil
        }

        if isBackground {
            backgroundProgress = displayValue
        } else {
            progress = displayValue
        }
    }

    private func setVirtualPatchState(
        _ requiresPatchRevert: Bool,
        for channelClient: any GameChannelClient
    ) {
        var nextState = store.load(for: channelClient.descriptor.id)
        nextState.requiresPatchRevert = requiresPatchRevert
        store.save(nextState, for: channelClient.descriptor.id)
    }

    private func refreshLauncherUpdateMetadata(for client: GameClientDescriptor) async {
        let result = await launcherUpdateService.check(for: client)

        switch result {
        case .available(let metadata):
            configuration.recordLauncherUpdateMetadata(metadata)
            alertMessage = "YAAGL update \(metadata.version) metadata is available. Downloads stay disabled on iOS."
            appendHistory(.checkLauncherUpdate, "launcher update: metadata captured for \(metadata.displaySummary)")
        case .latest(let resourceID):
            configuration.clearLauncherUpdateMetadata()
            appendHistory(.checkLauncherUpdate, "launcher update: \(resourceID) is already latest")
        case .unavailable:
            alertMessage = "YAAGL update metadata is unavailable."
            appendHistory(.checkLauncherUpdate, "launcher update: GitHub metadata lookup failed")
        }
    }

    private func completionMessage(
        for action: LauncherAction,
        before: ChannelClientState,
        after: ChannelClientState
    ) -> String {
        if action == .update,
           before.installState == .installed,
           after.installState == .notInstalled {
            "Update skipped: unsupported version; virtual install record reset"
        } else if action == .launch,
                  launchWasSkippedForUnsupportedVersion {
            "Launch skipped: unsupported version"
        } else if action == .importExisting,
                  before == after,
                  after.installState == .notInstalled {
            "Import skipped: existing install could not be used"
        } else if action == .importExisting,
                  before == after {
            "Import skipped: existing virtual install record unchanged"
        } else {
            "\(action.title) completed"
        }
    }

    private func appendHistory(_ action: LauncherAction, _ message: String) {
        taskHistory.insert(TaskHistoryItem(action: action, message: message), at: 0)
        if taskHistory.count > 80 {
            taskHistory.removeLast(taskHistory.count - 80)
        }
    }

    private var launchWasSkippedForUnsupportedVersion: Bool {
        statusText.hasPrefix("Unsupported game version ")
    }
}

extension LauncherViewModel {
    static var preview: LauncherViewModel {
        let suiteName = "LauncherViewModel.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: 0),
            launcherUpdateService: .simulated
        )
    }
}

private enum Keys {
    static let selectedClientID = "selected_client_id"
}
