import Foundation
import Observation

@MainActor
@Observable
final class LauncherViewModel {
    let clients: [GameClientDescriptor]
    let configuration: LauncherConfiguration

    var selectedClientID: String {
        didSet {
            defaults.set(selectedClientID, forKey: Keys.selectedClientID)
            restoreClientState()
        }
    }

    var installState: InstallState = .notInstalled
    var installDirectory = ""
    var currentVersion = "0.0.0"
    var statusText = "Ready"
    var progress: Double?
    var taskStatus: TaskStatus = .idle
    var showPredownloadPrompt = false
    var taskHistory: [TaskHistoryItem] = []
    var alertMessage: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private let store: ChannelClientStore
    @ObservationIgnored private let taskQueue: LauncherTaskQueue
    @ObservationIgnored private let channelClients: [String: any GameChannelClient]
    @ObservationIgnored private let defaultChannelClient: any GameChannelClient
    @ObservationIgnored private var dismissedPredownloadPromptClientIDs = Set<String>()

    init(
        defaults: UserDefaults = .standard,
        channelClients: [any GameChannelClient] = GameChannelClientFactory.makeDefaultClients()
    ) {
        let resolvedClients = channelClients.isEmpty ? GameChannelClientFactory.makeDefaultClients() : channelClients
        guard let defaultChannelClient = resolvedClients.first else {
            fatalError("YAAGL iOS requires at least one game channel client.")
        }

        self.defaults = defaults
        self.channelClients = Dictionary(uniqueKeysWithValues: resolvedClients.map { ($0.descriptor.id, $0) })
        self.defaultChannelClient = defaultChannelClient
        clients = resolvedClients.map(\.descriptor)
        configuration = LauncherConfiguration(defaults: defaults)
        store = ChannelClientStore(defaults: defaults)
        taskQueue = LauncherTaskQueue()
        if let savedClientID = defaults.string(forKey: Keys.selectedClientID),
           resolvedClients.contains(where: { $0.descriptor.id == savedClientID }) {
            selectedClientID = savedClientID
        } else {
            selectedClientID = defaultChannelClient.descriptor.id
        }
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
        await run(.predownload)
    }

    func checkIntegrity() async {
        await run(.checkIntegrity)
    }

    func checkLauncherUpdate() async {
        await run(.checkLauncherUpdate)
    }

    func dismissPredownload() {
        dismissedPredownloadPromptClientIDs.insert(selectedClient.id)
        showPredownloadPrompt = false
    }

    func resetVirtualInstall() {
        store.clear(for: selectedClient.id)
        restoreClientState()
        appendHistory(.initEnvironment, "Virtual install record cleared")
    }

    private func run(_ action: LauncherAction) async {
        let channelClient = selectedChannelClient
        let stateBeforeRun = currentState
        let context = GameChannelClientContext(
            configuration: configuration.snapshot,
            installDirectory: stateBeforeRun.installDirectory.isEmpty
                ? channelClient.virtualInstallDirectory()
                : stateBeforeRun.installDirectory
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
                handle(command, action: action)
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

    private func handle(_ command: ProgressCommand, action: LauncherAction) {
        switch command {
        case .setProgress(let value):
            progress = value
        case .setUndeterminedProgress:
            progress = nil
        case .setStateText(let text):
            statusText = text
        case .appendLog(let message):
            appendHistory(action, message)
        }
    }

    private func complete(
        _ action: LauncherAction,
        channelClient: any GameChannelClient,
        stateBeforeRun: ChannelClientState,
        context: GameChannelClientContext
    ) {
        let nextState = channelClient.state(after: action, currentState: stateBeforeRun, context: context)
        store.save(nextState, for: channelClient.descriptor.id)

        if selectedClientID == channelClient.descriptor.id {
            apply(nextState, for: channelClient)
        }

        progress = 1
        taskStatus = .completed(action)
        appendHistory(action, "\(action.title) completed")
    }

    private func restoreClientState() {
        apply(store.load(for: selectedClient.id), for: selectedChannelClient)
        statusText = "Ready"
        progress = nil
        taskStatus = .idle
    }

    private var currentState: ChannelClientState {
        ChannelClientState(
            installState: installState,
            installDirectory: installDirectory,
            currentVersion: currentVersion,
            predownloadedAll: store.load(for: selectedClient.id).predownloadedAll
        )
    }

    private func apply(_ state: ChannelClientState, for channelClient: any GameChannelClient) {
        installState = state.installState
        installDirectory = state.installDirectory
        currentVersion = state.currentVersion
        showPredownloadPrompt = !dismissedPredownloadPromptClientIDs.contains(channelClient.descriptor.id)
            && channelClient.showPredownloadPrompt(in: state)
    }

    private func appendHistory(_ action: LauncherAction, _ message: String) {
        taskHistory.insert(TaskHistoryItem(action: action, message: message), at: 0)
        if taskHistory.count > 80 {
            taskHistory.removeLast(taskHistory.count - 80)
        }
    }
}

extension LauncherViewModel {
    static var preview: LauncherViewModel {
        let suiteName = "LauncherViewModel.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: 0)
        )
    }
}

private enum Keys {
    static let selectedClientID = "selected_client_id"
}
