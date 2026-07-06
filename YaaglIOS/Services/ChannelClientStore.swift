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
            predownloadedAll: defaults.bool(forKey: predownloadedAllKey(for: clientID)),
            requiresPatchRevert: defaults.bool(forKey: requiresPatchRevertKey(for: clientID)),
            virtualInstallMetadata: virtualInstallMetadata(for: clientID),
            predownloadedArchiveKeys: predownloadedArchiveKeys(for: clientID)
        )
    }

    func save(_ state: ChannelClientState, for clientID: String) {
        defaults.set(state.installState.rawValue, forKey: installStateKey(for: clientID))
        defaults.set(state.installDirectory, forKey: installDirectoryKey(for: clientID))
        defaults.set(state.currentVersion, forKey: currentVersionKey(for: clientID))
        defaults.set(state.predownloadedAll, forKey: predownloadedAllKey(for: clientID))
        defaults.set(state.requiresPatchRevert, forKey: requiresPatchRevertKey(for: clientID))
        saveVirtualInstallMetadata(state.virtualInstallMetadata, for: clientID)
        savePredownloadedArchiveKeys(state.predownloadedArchiveKeys, for: clientID)
    }

    func clear(for clientID: String) {
        defaults.removeObject(forKey: installStateKey(for: clientID))
        defaults.removeObject(forKey: installDirectoryKey(for: clientID))
        defaults.removeObject(forKey: currentVersionKey(for: clientID))
        defaults.removeObject(forKey: predownloadedAllKey(for: clientID))
        defaults.removeObject(forKey: requiresPatchRevertKey(for: clientID))
        removeVirtualInstallMetadata(for: clientID)
        removePredownloadedArchiveKeys(for: clientID)
    }

    private func predownloadedArchiveKeys(for clientID: String) -> [String] {
        let keys = defaults.stringArray(forKey: predownloadedArchiveIndexKey(for: clientID)) ?? []

        return keys.filter { key in
            defaults.bool(forKey: predownloadedArchiveFlagKey(key, for: clientID))
        }
    }

    private func savePredownloadedArchiveKeys(_ keys: [String], for clientID: String) {
        removePredownloadedArchiveKeys(for: clientID)

        let normalizedKeys = normalizedPredownloadedArchiveKeys(keys)
        guard !normalizedKeys.isEmpty else {
            return
        }

        defaults.set(normalizedKeys, forKey: predownloadedArchiveIndexKey(for: clientID))
        for key in normalizedKeys {
            defaults.set(true, forKey: predownloadedArchiveFlagKey(key, for: clientID))
        }
    }

    private func removePredownloadedArchiveKeys(for clientID: String) {
        let keys = defaults.stringArray(forKey: predownloadedArchiveIndexKey(for: clientID)) ?? []
        for key in keys {
            defaults.removeObject(forKey: predownloadedArchiveFlagKey(key, for: clientID))
        }
        defaults.removeObject(forKey: predownloadedArchiveIndexKey(for: clientID))
    }

    private func normalizedPredownloadedArchiveKeys(_ keys: [String]) -> [String] {
        var seen = Set<String>()

        return keys
            .filter { !$0.isEmpty && seen.insert($0).inserted }
            .sorted()
    }

    private func virtualInstallMetadata(for clientID: String) -> VirtualInstallMetadata? {
        guard let gameVersion = defaults.string(forKey: configGameVersionKey(for: clientID)),
              let sourceServerID = defaults.string(forKey: configSourceServerIDKey(for: clientID)),
              defaults.object(forKey: configChannelIDKey(for: clientID)) != nil,
              defaults.object(forKey: configSubchannelIDKey(for: clientID)) != nil,
              defaults.object(forKey: configCPSReferenceKey(for: clientID)) != nil
        else {
            return nil
        }

        return VirtualInstallMetadata(
            gameVersion: gameVersion,
            channelID: defaults.integer(forKey: configChannelIDKey(for: clientID)),
            subchannelID: defaults.integer(forKey: configSubchannelIDKey(for: clientID)),
            cpsReference: defaults.string(forKey: configCPSReferenceKey(for: clientID)) ?? "",
            sourceServerID: sourceServerID
        )
    }

    private func saveVirtualInstallMetadata(_ metadata: VirtualInstallMetadata?, for clientID: String) {
        guard let metadata else {
            removeVirtualInstallMetadata(for: clientID)
            return
        }

        defaults.set(metadata.gameVersion, forKey: configGameVersionKey(for: clientID))
        defaults.set(metadata.channelID, forKey: configChannelIDKey(for: clientID))
        defaults.set(metadata.subchannelID, forKey: configSubchannelIDKey(for: clientID))
        defaults.set(metadata.cpsReference, forKey: configCPSReferenceKey(for: clientID))
        defaults.set(metadata.sourceServerID, forKey: configSourceServerIDKey(for: clientID))
    }

    private func removeVirtualInstallMetadata(for clientID: String) {
        defaults.removeObject(forKey: configGameVersionKey(for: clientID))
        defaults.removeObject(forKey: configChannelIDKey(for: clientID))
        defaults.removeObject(forKey: configSubchannelIDKey(for: clientID))
        defaults.removeObject(forKey: configCPSReferenceKey(for: clientID))
        defaults.removeObject(forKey: configSourceServerIDKey(for: clientID))
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

    private func predownloadedArchiveIndexKey(for clientID: String) -> String {
        "client.\(clientID).predownload_archive_keys"
    }

    private func predownloadedArchiveFlagKey(_ archiveKey: String, for clientID: String) -> String {
        "client.\(clientID).\(archiveKey)"
    }

    private func requiresPatchRevertKey(for clientID: String) -> String {
        "client.\(clientID).patched"
    }

    private func configGameVersionKey(for clientID: String) -> String {
        "client.\(clientID).config.game_version"
    }

    private func configChannelIDKey(for clientID: String) -> String {
        "client.\(clientID).config.channel"
    }

    private func configSubchannelIDKey(for clientID: String) -> String {
        "client.\(clientID).config.sub_channel"
    }

    private func configCPSReferenceKey(for clientID: String) -> String {
        "client.\(clientID).config.cps"
    }

    private func configSourceServerIDKey(for clientID: String) -> String {
        "client.\(clientID).config.source_server"
    }
}
