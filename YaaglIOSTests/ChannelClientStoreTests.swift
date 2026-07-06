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
            requiresPatchRevert: true
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
    }

    @MainActor
    func testClearRemovesOnlySelectedClient() {
        let store = ChannelClientStore(defaults: makeDefaults())
        let savedState = ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
            currentVersion: "5.3.0",
            predownloadedAll: true,
            requiresPatchRevert: true
        )

        store.save(savedState, for: "hk4e_cn")
        store.save(savedState, for: "hkrpg_cn")
        store.clear(for: "hk4e_cn")

        XCTAssertEqual(store.load(for: "hk4e_cn"), .empty)
        XCTAssertEqual(store.load(for: "hkrpg_cn"), savedState)
    }

    @MainActor
    private func makeDefaults() -> UserDefaults {
        let suiteName = "ChannelClientStoreTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
