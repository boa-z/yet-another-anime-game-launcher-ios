import XCTest
@testable import YaaglIOS

final class GameSettingsCapabilitiesTests: XCTestCase {
    @MainActor
    func testGameSettingCapabilitiesMatchDesktopClients() {
        let clients = Dictionary(uniqueKeysWithValues: GameLibrary.defaultClients.map { ($0.id, $0) })

        XCTAssertEqual(clients["hk4e_cn"]?.gameSettingsCapabilities, .hk4e)
        XCTAssertEqual(clients["hk4e_global"]?.gameSettingsCapabilities, .hk4e)
        XCTAssertEqual(clients["nap_cn"]?.gameSettingsCapabilities, .nap)
        XCTAssertEqual(clients["nap_global"]?.gameSettingsCapabilities, .nap)
        XCTAssertEqual(clients["hkrpg_cn"]?.gameSettingsCapabilities, .hkrpg)
        XCTAssertEqual(clients["hkrpg_global"]?.gameSettingsCapabilities, .hkrpg)
        XCTAssertEqual(clients["bh3_global"]?.gameSettingsCapabilities, GameSettingsCapabilities.none)
        XCTAssertEqual(clients["cbjq_global"]?.gameSettingsCapabilities, .cbjq)
        XCTAssertEqual(clients["cbjq_cn"]?.gameSettingsCapabilities, .cbjq)
    }

    @MainActor
    func testCapabilityDetailsMatchDesktopGameSettings() {
        XCTAssertTrue(GameSettingsCapabilities.hk4e.workaround3)
        XCTAssertTrue(GameSettingsCapabilities.hk4e.hdr)

        XCTAssertTrue(GameSettingsCapabilities.nap.resolution)
        XCTAssertTrue(GameSettingsCapabilities.nap.timeoutFix)
        XCTAssertFalse(GameSettingsCapabilities.nap.workaround3)
        XCTAssertFalse(GameSettingsCapabilities.nap.hdr)

        XCTAssertTrue(GameSettingsCapabilities.hkrpg.patchOff)
        XCTAssertTrue(GameSettingsCapabilities.hkrpg.blockNet)
        XCTAssertFalse(GameSettingsCapabilities.hkrpg.steamPatch)
        XCTAssertFalse(GameSettingsCapabilities.hkrpg.resolution)

        XCTAssertFalse(GameSettingsCapabilities.none.patchOff)
        XCTAssertFalse(GameSettingsCapabilities.none.blockNet)

        XCTAssertTrue(GameSettingsCapabilities.cbjq.patchOff)
        XCTAssertFalse(GameSettingsCapabilities.cbjq.steamPatch)
        XCTAssertFalse(GameSettingsCapabilities.cbjq.blockNet)
        XCTAssertFalse(GameSettingsCapabilities.cbjq.resolution)
    }
}
