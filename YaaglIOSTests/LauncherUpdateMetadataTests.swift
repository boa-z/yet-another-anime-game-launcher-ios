import XCTest
@testable import YaaglIOS

final class LauncherUpdateMetadataTests: XCTestCase {
    func testResourceAssetNameMatchesDesktopPattern() {
        XCTAssertEqual(LauncherUpdateMetadata.resourceAssetName(for: "hk4ecn"), "resources_hk4ecn.neu")
        XCTAssertEqual(LauncherUpdateMetadata.resourceAssetName(for: "napos"), "resources_napos.neu")
        XCTAssertEqual(LauncherUpdateMetadata.resourceAssetName(for: "cbjq"), "resources_cbjq.neu")
        XCTAssertEqual(LauncherUpdateMetadata.resourceAssetName(for: "cbjqcn"), "resources_cbjqcn.neu")
    }

    func testSidecarAssetNamesMatchDesktopUpdaterSwitch() {
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "hk4ecn"), "Yaagl.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "hk4eos"), "Yaagl.OS.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "bh3glb"), "Yaagl.Honkai.Global.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "hkrpgcn"), "Yaagl.HSR.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "hkrpgos"), "Yaagl.HSR.OS.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "napcn"), "Yaagl.ZZZ.app.tar.gz")
        XCTAssertEqual(LauncherUpdateMetadata.sidecarAssetName(for: "napos"), "Yaagl.ZZZ.OS.app.tar.gz")
        XCTAssertNil(LauncherUpdateMetadata.sidecarAssetName(for: "cbjq"))
        XCTAssertNil(LauncherUpdateMetadata.sidecarAssetName(for: "cbjqcn"))
        XCTAssertNil(LauncherUpdateMetadata.sidecarAssetName(for: "unknown"))
    }
}
