import XCTest
@testable import YaaglIOS

@MainActor
final class GameClientRuntimeMetadataTests: XCTestCase {
    func testHK4ESophonMetadataOverridesVersionPredownloadAndInstallSize() throws {
        let hk4e = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let metadata = try GameClientRuntimeMetadataParser.parseHK4ESophonGameInfo(
            jsonData(
                """
                {
                  "version": "5.4.0",
                  "updatable_versions": ["5.2.0", "5.3.0"],
                  "pre_download": true,
                  "pre_download_version": "5.5.0",
                  "install_size": 12884901888
                }
                """
            )
        )
        let client = hk4e.applying(runtimeMetadata: metadata)
        let channel = SimulatedGameChannelClient(descriptor: client)
        let state = installedState(for: client, currentVersion: "5.3.0")

        XCTAssertEqual(client.latestVersion, "5.4.0")
        XCTAssertEqual(client.updatableVersions, ["5.2.0", "5.3.0"])
        XCTAssertEqual(client.predownloadVersion, "5.5.0")
        XCTAssertEqual(client.installSize, "12 GiB")
        XCTAssertTrue(channel.updateRequired(in: state))
        XCTAssertTrue(channel.showPredownloadPrompt(in: state))
        XCTAssertEqual(channel.predownloadTitle(in: state), "Pre-download 5.5.0")
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: client), [])
    }

    func testHoyoMetadataSelectsPatchAndInstalledVoiceArchiveBasenames() async throws {
        let hkrpg = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let metadata = try GameClientRuntimeMetadataParser.parseHoyoVersionInfo(
            jsonData(
                """
                {
                  "main": {
                    "major": {
                      "version": "4.4.0",
                      "game_pkgs": [
                        { "url": "https://example.invalid/full/StarRail_4.4.0.7z", "size": "7516192768" },
                        { "url": "https://example.invalid/full/StarRail_optional.7z", "size": "1073741824" }
                      ],
                      "res_list_url": "https://example.invalid/res"
                    },
                    "patches": [
                      { "version": "4.2.0" },
                      { "version": "4.3.5" }
                    ]
                  },
                  "pre_download": {
                    "major": { "version": "4.5.0" },
                    "patches": [
                      {
                        "version": "4.3.5",
                        "game_pkgs": [
                          { "url": "https://example.invalid/pre/StarRail_4.3.5_4.5.0_hdiff.7z" }
                        ],
                        "audio_pkgs": [
                          { "language": "en-us", "url": "https://example.invalid/pre/Audio_English_4.3.5_4.5.0_hdiff.7z" },
                          { "language": "ja-jp", "url": "https://example.invalid/pre/Audio_Japanese_4.3.5_4.5.0_hdiff.7z" }
                        ]
                      }
                    ]
                  }
                }
                """
            ),
            currentVersion: "4.3.5",
            installedVoiceLanguages: ["en-us"]
        )
        let client = hkrpg.applying(runtimeMetadata: metadata)
        let channel = SimulatedGameChannelClient(descriptor: client)
        let state = installedState(for: client, currentVersion: "4.3.5")
        let context = GameChannelClientContext(
            configuration: launchSnapshot(),
            installDirectory: state.installDirectory,
            state: state,
            importProbeResult: nil
        )
        let updatedState = channel.state(after: .update, currentState: state, context: context)
        let markerBasenames = PredownloadArchiveMarker.markers(for: client).map(\.basename)

        XCTAssertEqual(client.latestVersion, "4.4.0")
        XCTAssertEqual(client.updatableVersions, ["4.2.0", "4.3.5"])
        XCTAssertEqual(client.predownloadVersion, "4.5.0")
        XCTAssertEqual(client.installSize, "8 GiB")
        XCTAssertEqual(markerBasenames, [
            "StarRail_4.3.5_4.5.0_hdiff.7z",
            "Audio_English_4.3.5_4.5.0_hdiff.7z"
        ])
        XCTAssertFalse(markerBasenames.contains("Audio_Japanese_4.3.5_4.5.0_hdiff.7z"))
        XCTAssertTrue(channel.updateRequired(in: state))
        XCTAssertTrue(channel.showPredownloadPrompt(in: state))
        XCTAssertEqual(updatedState.currentVersion, "4.4.0")
        XCTAssertFalse(updatedState.predownloadedAll)
    }

    func testBH3LauncherMetadataUsesDiffPathAndInstalledVoicePacks() throws {
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let metadata = try GameClientRuntimeMetadataParser.parseBH3LauncherResource(
            jsonData(
                """
                {
                  "data": {
                    "game": {
                      "latest": {
                        "version": "8.5.0",
                        "path": "https://example.invalid/full/BH3_v8.5.0.7z",
                        "decompressed_path": "https://example.invalid/decompressed",
                        "size": "6442450944"
                      },
                      "diffs": [
                        { "version": "8.3.0" },
                        { "version": "8.4.0" }
                      ]
                    },
                    "pre_download_game": {
                      "latest": { "version": "8.6.0" },
                      "diffs": [
                        {
                          "version": "8.4.0",
                          "path": "https://example.invalid/pre/BH3_8.4.0_8.6.0.7z",
                          "voice_packs": [
                            { "language": "en-us", "path": "https://example.invalid/pre/BH3_Audio_English.7z" },
                            { "language": "ja-jp", "path": "https://example.invalid/pre/BH3_Audio_Japanese.7z" }
                          ]
                        }
                      ]
                    }
                  }
                }
                """
            ),
            currentVersion: "8.4.0",
            installedVoiceLanguages: ["ja-jp"]
        )
        let client = bh3.applying(runtimeMetadata: metadata)

        XCTAssertEqual(client.latestVersion, "8.5.0")
        XCTAssertEqual(client.updatableVersions, ["8.3.0", "8.4.0"])
        XCTAssertEqual(client.predownloadVersion, "8.6.0")
        XCTAssertEqual(client.installSize, "6 GiB")
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: client).map(\.basename), [
            "BH3_8.4.0_8.6.0.7z",
            "BH3_Audio_Japanese.7z"
        ])
    }

    func testCBJQManifestMetadataOverridesLatestVersionAndInstallSize() throws {
        let cbjq = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_global" })
        let metadata = try GameClientRuntimeMetadataParser.parseCBJQManifest(
            jsonData(
                """
                {
                  "version": "manifest-2026-07-07",
                  "projectVersion": "2.2.0",
                  "pathOffset": "assets",
                  "paks": [
                    { "name": "base.pak", "hash": "aaa", "sizeInBytes": 3221225472, "bPrimary": true, "base": "", "diff": "", "diffSizeBytes": "0" },
                    { "name": "patch.pak", "hash": "bbb", "sizeInBytes": 536870912, "bPrimary": false, "base": "", "diff": "", "diffSizeBytes": "0" }
                  ]
                }
                """
            )
        )
        let client = cbjq.applying(runtimeMetadata: metadata)
        let channel = SimulatedGameChannelClient(descriptor: client)

        XCTAssertEqual(client.latestVersion, "2.2.0")
        XCTAssertEqual(client.installSize, "3.5 GiB")
        XCTAssertFalse(client.predownloadAvailable)
        XCTAssertTrue(channel.updateRequired(in: installedState(for: client, currentVersion: "2.0.0")))
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: client), [])
    }

    func testFactoryAppliesFixtureRuntimeMetadataBeforeCreatingClients() throws {
        let clients = GameChannelClientFactory.makeTestingClients(
            stepDurationMilliseconds: 0,
            runtimeMetadataProvider: .fixture([
                "nap_global": GameClientRuntimeMetadata(
                    latestVersion: "3.1.0",
                    updatableVersions: ["3.0.0"],
                    predownloadVersion: "3.2.0",
                    predownloadAvailable: true,
                    installSize: "90 GiB",
                    predownloadArchiveBasenames: ["nap_3.0.0_3.2.0_game.zip"]
                )
            ])
        )
        let napClient = try XCTUnwrap(clients.first { $0.descriptor.id == "nap_global" })
        let state = installedState(for: napClient.descriptor, currentVersion: "3.0.0")

        XCTAssertEqual(napClient.descriptor.latestVersion, "3.1.0")
        XCTAssertEqual(napClient.descriptor.updatableVersions, ["3.0.0"])
        XCTAssertEqual(napClient.descriptor.predownloadVersion, "3.2.0")
        XCTAssertEqual(napClient.descriptor.installSize, "90 GiB")
        XCTAssertTrue(napClient.updateRequired(in: state))
        XCTAssertTrue(napClient.showPredownloadPrompt(in: state))
        XCTAssertEqual(PredownloadArchiveMarker.markers(for: napClient.descriptor).map(\.basename), [
            "nap_3.0.0_3.2.0_game.zip"
        ])
    }

    private func jsonData(_ json: String) -> Data {
        Data(json.utf8)
    }

    private func installedState(
        for client: GameClientDescriptor,
        currentVersion: String
    ) -> ChannelClientState {
        ChannelClientState(
            installState: .installed,
            installDirectory: "iOS Sandbox/VirtualGameData/\(client.id)",
            currentVersion: currentVersion,
            predownloadedAll: false,
            requiresPatchRevert: false
        )
    }

    private func launchSnapshot() -> LauncherConfigurationSnapshot {
        LauncherConfigurationSnapshot(
            metalHud: false,
            retina: false,
            leftCmd: false,
            proxyEnabled: false,
            proxyHost: "127.0.0.1:8080",
            fpsUnlock: .disabled,
            reshade: false,
            patchOff: false,
            workaround3: true,
            steamPatch: false,
            blockNet: false,
            timeoutFix: false,
            resolutionCustom: false,
            resolutionWidth: 1920,
            resolutionHeight: 1080,
            hk4eEnableHDR: false,
            wineDistro: "11.0-dxmt-signed-with-patches"
        )
    }
}
