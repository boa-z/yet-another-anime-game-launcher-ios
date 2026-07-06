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
                "9.9-dxmt"
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
}
