import XCTest
@testable import YaaglIOS

final class DesktopSidecarToolTests: XCTestCase {
    func testCatalogMatchesDesktopSidecarExecutables() {
        let tools = Dictionary(uniqueKeysWithValues: DesktopSidecarTool.catalog.map { ($0.id, $0) })

        XCTAssertEqual(DesktopSidecarTool.catalog.map(\.id), ["aria2", "xdelta", "hpatchz", "sophon-server"])
        XCTAssertEqual(tools["aria2"]?.desktopExecutablePath, "./sidecar/aria2/aria2c")
        XCTAssertEqual(tools["xdelta"]?.desktopExecutablePath, "./sidecar/xdelta/xdelta3")
        XCTAssertEqual(tools["hpatchz"]?.desktopExecutablePath, "./sidecar/hpatchz/hpatchz")
        XCTAssertEqual(tools["sophon-server"]?.desktopExecutablePath, "./sidecar/sophon_server/sophon-server")
        XCTAssertEqual(tools["aria2"]?.role, "RPC download scheduler")
        XCTAssertEqual(tools["sophon-server"]?.role, "HoYoPlay manifest and chunk service")
    }

    func testBlockLogCombinesOnlyKnownSidecars() {
        let log = DesktopSidecarTool.blockLog(ids: ["aria2", "unknown", "hpatchz"])

        XCTAssertTrue(log.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c"))
        XCTAssertTrue(log.contains("launcher assets"))
        XCTAssertTrue(log.contains("sidecar: hpatchz metadata mirrors ./sidecar/hpatchz/hpatchz"))
        XCTAssertTrue(log.contains("hdiffmap.json patches"))
        XCTAssertTrue(log.contains("not bundled or executed on iOS"))
        XCTAssertFalse(log.contains("unknown"))
        XCTAssertEqual(
            DesktopSidecarTool.blockLog(ids: ["unknown"]),
            "sidecar: desktop sidecar execution is disabled on iOS"
        )
    }

    func testSidecarCatalogDoesNotInventInstalledVersionKeys() {
        let combinedMetadata = DesktopSidecarTool.catalog.map {
            "\($0.id) \($0.displayName) \($0.settingsSummary) \($0.flowSummary) \($0.iOSAvailabilityNote)"
        }.joined(separator: " ")

        XCTAssertFalse(combinedMetadata.contains("installed_"))
    }
}
