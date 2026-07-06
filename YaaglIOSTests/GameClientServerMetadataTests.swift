import XCTest
@testable import YaaglIOS

final class GameClientServerMetadataTests: XCTestCase {
    @MainActor
    func testVisibleServerMetadataMatchesDesktopClientDefinitions() throws {
        let clients = Dictionary(uniqueKeysWithValues: GameLibrary.defaultClients.map { ($0.id, $0) })
        let hk4eCN = try XCTUnwrap(clients["hk4e_cn"]?.server)
        let napGlobal = try XCTUnwrap(clients["nap_global"]?.server)
        let hkrpgGlobal = try XCTUnwrap(clients["hkrpg_global"]?.server)
        let bh3Global = try XCTUnwrap(clients["bh3_global"]?.server)

        XCTAssertEqual(hk4eCN.channelID, 1)
        XCTAssertEqual(hk4eCN.subchannelID, 1)
        XCTAssertEqual(hk4eCN.cpsReference, "CN_CPS")
        XCTAssertEqual(hk4eCN.launcherUpdateResourceID, "hk4ecn")
        XCTAssertEqual(hk4eCN.desktopDefaultWineDistributionID, "11.0-dxmt-signed-with-patches")
        XCTAssertEqual(hk4eCN.blockNetHost, "dispatchcnglobal.yuanshen.com")
        XCTAssertEqual(hk4eCN.blockNetDurationSeconds, 10)
        XCTAssertEqual(
            hk4eCN.removedFiles,
            [
                "YuanShen_Data/upload_crash.exe",
                "YuanShen_Data/Plugins/crashreport.exe",
                "YuanShen_Data/Plugins/vulkan-1.dll"
            ]
        )

        XCTAssertEqual(napGlobal.channelID, 1)
        XCTAssertEqual(napGlobal.subchannelID, 0)
        XCTAssertEqual(napGlobal.cpsReference, "NAP_CPS")
        XCTAssertEqual(napGlobal.launcherUpdateResourceID, "napos")
        XCTAssertEqual(napGlobal.desktopDefaultWineDistributionID, "11.0-1-crossover-signed-experimental")
        XCTAssertEqual(napGlobal.blockNetHost, "globaldp-prod-os01.zenlesszonezero.com")
        XCTAssertEqual(napGlobal.blockNetDurationSeconds, 20)

        XCTAssertEqual(hkrpgGlobal.channelID, 1)
        XCTAssertEqual(hkrpgGlobal.subchannelID, 1)
        XCTAssertEqual(hkrpgGlobal.cpsReference, "HKRPG_OS_CPS")
        XCTAssertEqual(hkrpgGlobal.launcherUpdateResourceID, "hkrpgos")
        XCTAssertEqual(hkrpgGlobal.desktopDefaultWineDistributionID, "11.0-1-crossover-signed-experimental")
        XCTAssertEqual(hkrpgGlobal.blockNetHost, "globaldp-prod-os01.starrails.com")
        XCTAssertEqual(hkrpgGlobal.blockNetDurationSeconds, 15)

        XCTAssertEqual(bh3Global.channelID, 0)
        XCTAssertEqual(bh3Global.subchannelID, 0)
        XCTAssertEqual(bh3Global.cpsDisplayValue, "")
        XCTAssertEqual(bh3Global.launcherUpdateResourceID, "bh3glb")
        XCTAssertEqual(bh3Global.desktopDefaultWineDistributionID, "unstable-bh-wine-1.1")
        XCTAssertNil(bh3Global.blockNetHost)
        XCTAssertNil(bh3Global.blockNetDurationSeconds)
        XCTAssertEqual(
            bh3Global.removedFiles,
            [
                "BH3_Data/Plugins/crashreport.exe",
                "BH3_Data/Plugins/vulkan-1.dll"
            ]
        )
    }
}
