import XCTest
@testable import YaaglIOS

final class DependencyResourceTests: XCTestCase {
    func testCatalogMatchesDesktopDownloadableResourceVersionsAndKeys() {
        let resources = Dictionary(uniqueKeysWithValues: DependencyResource.catalog.map { ($0.id, $0) })

        XCTAssertEqual(resources["moltenvk"]?.installedVersionKey, "installed_moltenvk_version")
        XCTAssertEqual(resources["moltenvk"]?.currentVersion, "1.2.2")
        XCTAssertEqual(resources["dxvk"]?.installedVersionKey, "installed_dxvk_version")
        XCTAssertEqual(resources["dxvk"]?.currentVersion, "1.10.4-alpha.20230402")
        XCTAssertEqual(resources["jadeite"]?.installedVersionKey, "installed_jadeite_version")
        XCTAssertEqual(resources["jadeite"]?.currentVersion, "4.1.0")
        XCTAssertEqual(resources["dxmt"]?.installedVersionKey, "installed_dxmt_version")
        XCTAssertEqual(resources["dxmt"]?.currentVersion, "0.80.0")
        XCTAssertEqual(resources["reshade"]?.installedVersionKey, "installed_reshade")
        XCTAssertEqual(resources["reshade"]?.currentVersion, "5.8.0")
    }

    func testCatalogKeepsRemoteURLsAsMetadataOnly() throws {
        let dxvk = try XCTUnwrap(DependencyResource.resource(id: "dxvk"))
        let dxmt = try XCTUnwrap(DependencyResource.resource(id: "dxmt"))
        let reshade = try XCTUnwrap(DependencyResource.resource(id: "reshade"))

        XCTAssertEqual(dxvk.remoteURLs.count, 4)
        XCTAssertTrue(dxvk.remoteURLs.contains("https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/d3d11.dll"))
        XCTAssertEqual(dxmt.remoteURLs, ["https://github.com/3Shain/dxmt/releases/download/v0.80/dxmt-v0.80-builtin.tar.gz"])
        XCTAssertEqual(
            reshade.remoteURLs,
            [
                "https://reshade.me/downloads/ReShade_Setup_5.8.0_Addon.exe",
                "https://lutris.net/files/tools/dll/d3dcompiler_47.dll"
            ]
        )
        XCTAssertTrue(reshade.downloadBlockLog.contains("installed_reshade"))
        XCTAssertTrue(reshade.downloadBlockLog.contains("were not downloaded"))
    }

    func testDXMTArtifactListIncludesDesktopUnixlibBridgeFiles() throws {
        let dxmt = try XCTUnwrap(DependencyResource.resource(id: "dxmt"))

        XCTAssertTrue(dxmt.artifactNames.contains("winemetal.dll"))
        XCTAssertTrue(dxmt.artifactNames.contains("winemetal.so"))
        XCTAssertTrue(dxmt.artifactNames.contains("nvngx.dll"))
    }
}
