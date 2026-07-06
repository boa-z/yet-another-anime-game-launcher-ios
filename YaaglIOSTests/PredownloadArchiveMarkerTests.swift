import XCTest
@testable import YaaglIOS

@MainActor
final class PredownloadArchiveMarkerTests: XCTestCase {
    func testDesktopMarkerKeyUsesSHA1PrefixOfArchiveBasename() {
        let marker = PredownloadArchiveMarker(basename: "game.zip")

        XCTAssertEqual(marker.key, "predownloaded_c115c36ddd26a653f8ab4a719d3f2357")
    }

    func testAria2ClientsExposeVirtualArchiveMarkers() throws {
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let hkrpg = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let hk4e = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let cbjq = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_global" })

        XCTAssertEqual(PredownloadArchiveMarker.markers(for: nap).count, 2)
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: hkrpg).count, 2)
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: bh3).count, 2)
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: hk4e), [])
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: cbjq), [])
    }
}
