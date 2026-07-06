import XCTest
@testable import YaaglIOS

@MainActor
final class VirtualInstallSnippetParserTests: XCTestCase {
    private let parser = VirtualInstallSnippetParser()

    @MainActor
    func testConfigINIParsesVersionAndDesktopMetadata() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let result = parser.parse(
            """
            [General]
            game_version=5.3.0
            channel=9
            sub_channel=2
            cps=<CUSTOM_CPS>
            """,
            for: client
        )

        XCTAssertEqual(result.source, .configINI)
        XCTAssertEqual(result.message, "Detected 5.3.0 from config.ini")

        guard case .existing(let version, let metadata) = result.probeResult else {
            return XCTFail("Expected an existing virtual install probe result")
        }

        XCTAssertEqual(version, "5.3.0")
        XCTAssertEqual(
            metadata,
            VirtualInstallMetadata(
                gameVersion: "5.3.0",
                channelID: 9,
                subchannelID: 2,
                cpsReference: "CUSTOM_CPS",
                sourceServerID: client.serverID
            )
        )
    }

    @MainActor
    func testPackageVersionParsesConservativeVersionFromJSONLines() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let result = parser.parse(
            """
            {"remoteName":"game_3.0.0.zip","fileSize":"1","version":"3.0.0"}
            {"remoteName":"voice_2.9.0.zip","fileSize":"1","version":"2.9.0"}
            """,
            for: client
        )

        XCTAssertEqual(result.source, .packageVersion)
        XCTAssertEqual(result.detectedVersion, "2.9.0")
    }

    func testPackageVersionWithoutVersionStaysUnreadable() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let result = parser.parse(
            """
            {"remoteName":"YuanShen.exe","md5":"abc","fileSize":12}
            """,
            for: client
        )

        XCTAssertEqual(result.source, .packageVersion)
        XCTAssertEqual(result.probeResult, .unreadable)
    }

    @MainActor
    func testManifestJSONParsesNestedGameVersion() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let result = parser.parse(
            """
            {
              "data": {
                "game": {
                  "latest": {
                    "version": "4.3.0"
                  }
                }
              }
            }
            """,
            for: client
        )

        XCTAssertEqual(result.source, .manifestJSON)
        XCTAssertEqual(result.detectedVersion, "4.3.0")
    }

    @MainActor
    func testLauncherUpdateManifestIsRejectedAsGameMetadata() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let result = parser.parse(
            """
            {
              "applicationId": "resources_bh3glb",
              "resourcesURL": "https://example.test/resources.neu"
            }
            """,
            for: client
        )

        XCTAssertEqual(result.source, .manifestJSON)
        XCTAssertEqual(result.probeResult, .unreadable)
        XCTAssertEqual(result.message, "Launcher update manifests are not game metadata")
    }

    func testOversizedSnippetIsRejectedBeforeParsing() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let result = parser.parse(
            String(repeating: "x", count: VirtualInstallSnippetParser.maximumSnippetBytes + 1),
            for: client
        )

        XCTAssertNil(result.source)
        XCTAssertEqual(result.probeResult, .unreadable)
    }
}
