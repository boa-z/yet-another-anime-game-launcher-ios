import XCTest
@testable import YaaglIOS

@MainActor
final class PredownloadArchiveMarkerTests: XCTestCase {
    func testDesktopMarkerKeyUsesSHA1PrefixOfArchiveBasename() {
        let marker = PredownloadArchiveMarker(basename: "game.zip")

        XCTAssertEqual(marker.key, "predownloaded_c115c36ddd26a653f8ab4a719d3f2357")
    }

    func testStaticCatalogDoesNotInventArchiveMarkers() throws {
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let hkrpg = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let hk4e = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let cbjq = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_global" })

        XCTAssertEqual(PredownloadArchiveMarker.markers(for: nap), [])
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: hkrpg), [])
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: bh3), [])
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: hk4e), [])
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: cbjq), [])
    }

    func testRuntimeMetadataArchiveBasenamesExposeDesktopMarkerKeys() throws {
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let client = nap.applying(runtimeMetadata: GameClientRuntimeMetadata(
            predownloadArchiveBasenames: [
                "nap_3.0.0_3.1.0_game.zip",
                "nap_3.0.0_3.1.0_audio_en-us.zip"
            ]
        ))

        XCTAssertEqual(PredownloadArchiveMarker.markers(for: client).map(\.basename), [
            "nap_3.0.0_3.1.0_game.zip",
            "nap_3.0.0_3.1.0_audio_en-us.zip"
        ])
        XCTAssertEqual(
            PredownloadArchiveMarker.markers(for: client).map(\.key),
            [
                "predownloaded_2883425c567832edca1147fa921ef8b3",
                "predownloaded_19b937a0f457becb5d77bccaca2ce18a"
            ]
        )
    }
}
