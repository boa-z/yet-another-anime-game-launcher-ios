import XCTest
@testable import YaaglIOS

@MainActor
final class SeasunManifestPlanTests: XCTestCase {
    func testUpdatePlanDiffsPaksByHash() {
        let local = manifest(
            paks: [
                pak(name: "renamed-local.pak", hash: "same-hash"),
                pak(name: "same-name-old.pak", hash: "old-hash"),
                pak(name: "local-only.pak", hash: "local-hash")
            ]
        )
        let remote = manifest(
            paks: [
                pak(name: "renamed-remote.pak", hash: "same-hash"),
                pak(name: "same-name-old.pak", hash: "new-hash"),
                pak(name: "remote-only.pak", hash: "remote-hash")
            ]
        )

        let plan = SeasunManifestUpdatePlan.make(
            local: local,
            remote: remote,
            gameDirectory: "GameDir",
            dlcBaseURL: "https://example.test/updates/"
        )

        XCTAssertEqual(plan.removedPaks.map(\.localName), ["same-name-old.pak", "local-only.pak"])
        XCTAssertEqual(plan.addedPaks.map(\.remoteName), ["same-name-old.pak", "remote-only.pak"])
        XCTAssertEqual(plan.addedPaks.map(\.hash), ["new-hash", "remote-hash"])
        XCTAssertFalse(plan.removedPaks.map(\.localName).contains("renamed-local.pak"))
        XCTAssertFalse(plan.addedPaks.map(\.remoteName).contains("renamed-remote.pak"))
    }

    func testUpdatePlanBuildsDesktopShapedURLsFromHash() {
        let remote = manifest(
            paks: [
                pak(name: "remote-only.pak", hash: "remote-hash")
            ]
        )

        let globalPlan = SeasunManifestUpdatePlan.make(
            local: manifest(paks: []),
            remote: remote,
            gameDirectory: "GameDir",
            dlcBaseURL: "https://snowbreak-dl.amazingseasuncdn.com/6e5452634164107ee3c3cfd6efcdf55f/PC/updates/"
        )
        let cnPlan = SeasunManifestUpdatePlan.make(
            local: manifest(paks: []),
            remote: remote,
            gameDirectory: "GameDir",
            dlcBaseURL: "https://cbjq.xoyocdn.com/DLC7/PC/updates"
        )

        XCTAssertEqual(
            globalPlan.addedPaks.first?.remoteURL,
            "https://snowbreak-dl.amazingseasuncdn.com/6e5452634164107ee3c3cfd6efcdf55f/PC/updates/assets/remote-hash"
        )
        XCTAssertEqual(
            cnPlan.addedPaks.first?.remoteURL,
            "https://cbjq.xoyocdn.com/DLC7/PC/updates/assets/remote-hash"
        )
        XCTAssertEqual(globalPlan.addedPaks.first?.localPath, "GameDir/remote-only.pak")
        XCTAssertFalse(try XCTUnwrap(globalPlan.addedPaks.first?.remoteURL).contains("https:/snowbreak"))
        XCTAssertFalse(try XCTUnwrap(globalPlan.addedPaks.first?.remoteURL).contains("remote-only.pak"))
    }

    func testIntegrityPlanUsesRemoteManifestEntriesOnly() {
        let plan = SeasunManifestIntegrityPlan.make(
            manifest: manifest(
                paks: [
                    pak(name: "base.pak", hash: "base-hash", sizeInBytes: 100),
                    pak(name: "patch.pak", hash: "patch-hash", sizeInBytes: 200)
                ]
            ),
            gameDirectory: "/GameDir",
            dlcBaseURL: "https://example.test/updates"
        )

        XCTAssertEqual(plan.entries.map(\.remoteName), ["base.pak", "patch.pak"])
        XCTAssertEqual(plan.entries.map(\.md5), ["base-hash", "patch-hash"])
        XCTAssertEqual(plan.entries.map(\.fileSize), [100, 200])
        XCTAssertEqual(plan.entries.first?.localPath, "/GameDir/base.pak")
        XCTAssertEqual(plan.entries.first?.repairURL, "https://example.test/updates/assets/base-hash")
    }

    private func manifest(paks: [VirtualInstallManifestMetadata.Pak]) -> VirtualInstallManifestMetadata {
        VirtualInstallManifestMetadata(
            manifestVersion: "2.1.0.83",
            projectVersion: "2.1.0",
            pathOffset: "assets",
            paks: paks,
            sourceServerID: "CBJQ",
            channel: "seasun"
        )
    }

    private func pak(
        name: String,
        hash: String,
        sizeInBytes: Int64 = 1
    ) -> VirtualInstallManifestMetadata.Pak {
        VirtualInstallManifestMetadata.Pak(
            name: name,
            hash: hash,
            sizeInBytes: sizeInBytes,
            bPrimary: false,
            base: "",
            diff: "",
            diffSizeBytes: "0"
        )
    }
}
