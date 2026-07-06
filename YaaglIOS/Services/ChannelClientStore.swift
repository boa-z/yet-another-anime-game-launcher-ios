import Foundation

@MainActor
struct ChannelClientStore {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func load(for clientID: String) -> ChannelClientState {
        ChannelClientState(
            installState: defaults.string(forKey: installStateKey(for: clientID)).flatMap(InstallState.init(rawValue:)) ?? .notInstalled,
            installDirectory: defaults.string(forKey: installDirectoryKey(for: clientID)) ?? "",
            currentVersion: defaults.string(forKey: currentVersionKey(for: clientID)) ?? "0.0.0",
            predownloadedAll: defaults.bool(forKey: predownloadedAllKey(for: clientID))
        )
    }

    func save(_ state: ChannelClientState, for clientID: String) {
        defaults.set(state.installState.rawValue, forKey: installStateKey(for: clientID))
        defaults.set(state.installDirectory, forKey: installDirectoryKey(for: clientID))
        defaults.set(state.currentVersion, forKey: currentVersionKey(for: clientID))
        defaults.set(state.predownloadedAll, forKey: predownloadedAllKey(for: clientID))
    }

    func clear(for clientID: String) {
        defaults.removeObject(forKey: installStateKey(for: clientID))
        defaults.removeObject(forKey: installDirectoryKey(for: clientID))
        defaults.removeObject(forKey: currentVersionKey(for: clientID))
        defaults.removeObject(forKey: predownloadedAllKey(for: clientID))
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

    private func predownloadedAllKey(for clientID: String) -> String {
        "client.\(clientID).predownloaded_all"
    }
}
