import XCTest
@testable import YaaglIOS

final class WineDistributionTests: XCTestCase {
    @MainActor
    func testBuiltinWineCatalogMatchesDesktopDistributionIDs() {
        let ids = WineDistribution.catalog.map(\.id)

        XCTAssertEqual(
            ids,
            [
                "11.0-1-crossover-signed-experimental",
                "11.0-dxmt-signed-with-patches",
                "11.8-dxmt-signed-experimental",
                "11.4-dxmt-signed",
                "11.0-dxmt-signed",
                "9.9-dxmt",
                "unstable-bh-wine-1.1",
                "unstable-bh-gptk-1.0",
                "v9.2-mingw"
            ]
        )
        XCTAssertEqual(WineDistribution.defaultDistribution.id, WineDistribution.defaultID)
    }

    @MainActor
    func testCatalogKeepsRemoteURLsAsMetadataOnly() throws {
        let distribution = try XCTUnwrap(WineDistribution.distribution(id: "9.9-dxmt"))

        XCTAssertEqual(distribution.renderBackend, "dxmt")
        XCTAssertEqual(distribution.remoteURL, "https://github.com/3Shain/wine/releases/download/v9.9-mingw/wine.tar.gz")
    }

    @MainActor
    func testCatalogIncludesDesktopDeclaredClientDefaultTags() throws {
        let bh3 = try XCTUnwrap(WineDistribution.distribution(id: "unstable-bh-wine-1.1"))
        let cbjqGlobal = try XCTUnwrap(WineDistribution.distribution(id: "unstable-bh-gptk-1.0"))
        let cbjqCN = try XCTUnwrap(WineDistribution.distribution(id: "v9.2-mingw"))

        XCTAssertEqual(bh3.remoteURL, "https://github.com/3Shain/winecx/releases/download/unstable-bh-wine-1.1/wine.tar.gz")
        XCTAssertEqual(cbjqGlobal.remoteURL, "https://github.com/3Shain/wine/releases/download/unstable-bh-gptk-1.0/wine.tar.gz")
        XCTAssertEqual(cbjqGlobal.renderBackend, "gptk")
        XCTAssertEqual(cbjqCN.remoteURL, "https://github.com/3Shain/wine/releases/download/v9.2-mingw/wine.tar.gz")
        XCTAssertEqual(cbjqCN.renderBackend, "wine")
    }
}
