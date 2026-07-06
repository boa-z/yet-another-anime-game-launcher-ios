import Foundation
import Observation

@MainActor
@Observable
final class LauncherViewModel {
    let clients = GameLibrary.defaultClients
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
    @ObservationIgnored private let service = LauncherSimulationService()

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        configuration = LauncherConfiguration(defaults: defaults)
        selectedClientID = defaults.string(forKey: Keys.selectedClientID) ?? GameLibrary.defaultClients[0].id
        restoreClientState()
    }

    var selectedClient: GameClientDescriptor {
        clients.first { $0.id == selectedClientID } ?? clients[0]
    }

    var isBusy: Bool {
        if case .running = taskStatus {
            true
        } else {
            false
        }
    }

    var updateRequired: Bool {
        installState == .installed && SemanticVersion(currentVersion) < SemanticVersion(selectedClient.latestVersion)
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
        if let version = selectedClient.predownloadVersion {
            "Pre-download \(version)"
        } else {
            "Pre-download"
        }
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
        showPredownloadPrompt = false
        defaults.set(true, forKey: predownloadDismissedKey(for: selectedClient.id))
    }

    func resetVirtualInstall() {
        defaults.removeObject(forKey: installStateKey(for: selectedClient.id))
        defaults.removeObject(forKey: installDirectoryKey(for: selectedClient.id))
        defaults.removeObject(forKey: currentVersionKey(for: selectedClient.id))
        defaults.removeObject(forKey: predownloadDismissedKey(for: selectedClient.id))
        restoreClientState()
        appendHistory(.initEnvironment, "Virtual install record cleared")
    }

    private func run(_ action: LauncherAction) async {
        guard !isBusy else { return }

        taskStatus = .running(action)
        statusText = action.title
        progress = nil

        let client = selectedClient
        let stream = service.makeProgram(
            action: action,
            client: client,
            configuration: configuration.snapshot,
            installDirectory: installDirectory.isEmpty ? virtualDirectory(for: client) : installDirectory
        )

        for await command in stream {
            handle(command, action: action)
        }

        complete(action, client: client)
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

    private func complete(_ action: LauncherAction, client: GameClientDescriptor) {
        switch action {
        case .install:
            installState = .installed
            installDirectory = virtualDirectory(for: client)
            currentVersion = client.latestVersion
            persistClientState(client)
            showPredownloadPrompt = shouldShowPredownload(for: client)
        case .update:
            currentVersion = client.latestVersion
            defaults.set(false, forKey: predownloadDismissedKey(for: client.id))
            persistClientState(client)
            showPredownloadPrompt = shouldShowPredownload(for: client)
        case .predownload:
            showPredownloadPrompt = false
            defaults.set(true, forKey: predownloadDismissedKey(for: client.id))
        case .launch, .checkIntegrity, .initEnvironment, .checkLauncherUpdate:
            break
        }

        progress = 1
        taskStatus = .completed(action)
        appendHistory(action, "\(action.title) completed")
    }

    private func restoreClientState() {
        let client = selectedClient
        installState = defaults.string(forKey: installStateKey(for: client.id)).flatMap(InstallState.init(rawValue:)) ?? .notInstalled
        installDirectory = defaults.string(forKey: installDirectoryKey(for: client.id)) ?? ""
        currentVersion = defaults.string(forKey: currentVersionKey(for: client.id)) ?? "0.0.0"
        statusText = "Ready"
        progress = nil
        taskStatus = .idle
        showPredownloadPrompt = shouldShowPredownload(for: client)
    }

    private func persistClientState(_ client: GameClientDescriptor) {
        defaults.set(installState.rawValue, forKey: installStateKey(for: client.id))
        defaults.set(installDirectory, forKey: installDirectoryKey(for: client.id))
        defaults.set(currentVersion, forKey: currentVersionKey(for: client.id))
    }

    private func shouldShowPredownload(for client: GameClientDescriptor) -> Bool {
        guard installState == .installed,
              client.predownloadAvailable,
              let version = client.predownloadVersion
        else {
            return false
        }

        let dismissed = defaults.bool(forKey: predownloadDismissedKey(for: client.id))
        return !dismissed && SemanticVersion(version) > SemanticVersion(currentVersion)
    }

    private func virtualDirectory(for client: GameClientDescriptor) -> String {
        "iOS Sandbox/VirtualGameData/\(client.id)"
    }

    private func appendHistory(_ action: LauncherAction, _ message: String) {
        taskHistory.insert(TaskHistoryItem(action: action, message: message), at: 0)
        if taskHistory.count > 80 {
            taskHistory.removeLast(taskHistory.count - 80)
        }
    }

    private func installStateKey(for clientID: String) -> String {
        "client.\(clientID).install_state"
    }

    private func installDirectoryKey(for clientID: String) -> String {
        "client.\(clientID).install_dir"
    }

    private func currentVersionKey(for clientID: String) -> String {
        "client.\(clientID).current_version"
    }

    private func predownloadDismissedKey(for clientID: String) -> String {
        "client.\(clientID).predownloaded_all"
    }
}

extension LauncherViewModel {
    static var preview: LauncherViewModel {
        let suiteName = "LauncherViewModel.preview.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        return LauncherViewModel(defaults: defaults)
    }
}

private enum Keys {
    static let selectedClientID = "selected_client_id"
}

