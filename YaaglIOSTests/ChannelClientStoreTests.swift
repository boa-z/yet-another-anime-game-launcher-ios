import XCTest
@testable import YaaglIOS

final class ChannelClientStoreTests: XCTestCase {
    @MainActor
    func testPersistsStatesPerClient() {
        let store = ChannelClientStore(defaults: makeDefaults())
        let firstState = ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
            currentVersion: "5.3.0",
            predownloadedAll: true,
            requiresPatchRevert: true,
            virtualInstallMetadata: VirtualInstallMetadata(
                gameVersion: "5.3.0",
                channelID: 1,
                subchannelID: 1,
                cpsReference: "CN_CPS",
                sourceServerID: "hk4e_cn"
            ),
            predownloadedArchiveKeys: [
                "predownloaded_game",
                "predownloaded_voice"
            ]
        )
        let secondState = ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/hkrpg_cn",
            currentVersion: "4.3.0",
            predownloadedAll: false,
            requiresPatchRevert: false
        )

        store.save(firstState, for: "hk4e_cn")
        store.save(secondState, for: "hkrpg_cn")

        XCTAssertEqual(store.load(for: "hk4e_cn"), firstState)
        XCTAssertEqual(store.load(for: "hkrpg_cn"), secondState)
        XCTAssertTrue(store.load(for: "hk4e_cn").predownloadedArchiveKeys.contains("predownloaded_game"))
        XCTAssertTrue(store.load(for: "hk4e_cn").predownloadedArchiveKeys.contains("predownloaded_voice"))
    }

    @MainActor
    func testLegacyStateWithoutVirtualMetadataStillLoads() {
        let defaults = makeDefaults()
        defaults.set(InstallState.installed.rawValue, forKey: "client.hk4e_cn.install_state")
        defaults.set("iOS Sandbox/VirtualGameData/hk4e_cn", forKey: "client.hk4e_cn.install_dir")
        defaults.set("5.3.0", forKey: "client.hk4e_cn.current_version")

        let state = ChannelClientStore(defaults: defaults).load(for: "hk4e_cn")

        XCTAssertEqual(state.installState, .installed)
        XCTAssertEqual(state.installDirectory, "iOS Sandbox/VirtualGameData/hk4e_cn")
        XCTAssertEqual(state.currentVersion, "5.3.0")
        XCTAssertNil(state.virtualInstallMetadata)
        XCTAssertNil(state.virtualManifestMetadata)
        XCTAssertEqual(state.predownloadedArchiveKeys, [])
    }

    @MainActor
    func testPersistsSeasunManifestMetadata() {
        let store = ChannelClientStore(defaults: makeDefaults())
        let manifestMetadata = VirtualInstallManifestMetadata(
            manifestVersion: "2.1.0.83",
            projectVersion: "2.1.0",
            pathOffset: "assets",
            paks: [
                VirtualInstallManifestMetadata.Pak(
                    name: "game_a.pak",
                    hash: "hash-a",
                    sizeInBytes: 100,
                    bPrimary: true,
                    base: "base-a",
                    diff: "diff-a",
                    diffSizeBytes: "10"
                )
            ],
            sourceServerID: "cbjq_global",
            channel: "os",
            expectedPakCount: 1,
            expectedPayloadBytes: 100
        )
        let savedState = ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/cbjq_global",
            currentVersion: "2.1.0",
            predownloadedAll: false,
            requiresPatchRevert: false,
            virtualManifestMetadata: manifestMetadata
        )

        store.save(savedState, for: "cbjq_global")

        XCTAssertEqual(store.load(for: "cbjq_global"), savedState)
        store.clear(for: "cbjq_global")
        XCTAssertNil(store.load(for: "cbjq_global").virtualManifestMetadata)
    }

    @MainActor
    func testClearRemovesOnlySelectedClient() {
        let store = ChannelClientStore(defaults: makeDefaults())
        let savedState = ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
            currentVersion: "5.3.0",
            predownloadedAll: true,
            requiresPatchRevert: true,
            predownloadedArchiveKeys: ["predownloaded_game"]
        )

        store.save(savedState, for: "hk4e_cn")
        store.save(savedState, for: "hkrpg_cn")
        store.clear(for: "hk4e_cn")

        XCTAssertEqual(store.load(for: "hk4e_cn"), .empty)
        XCTAssertEqual(store.load(for: "hkrpg_cn"), savedState)
        XCTAssertFalse(store.load(for: "hk4e_cn").predownloadedArchiveKeys.contains("predownloaded_game"))
    }

    @MainActor
    private func makeDefaults() -> UserDefaults {
        let suiteName = "ChannelClientStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
