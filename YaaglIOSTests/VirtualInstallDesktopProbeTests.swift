import XCTest
@testable import YaaglIOS

@MainActor
final class VirtualInstallDesktopProbeTests: XCTestCase {
    private let parser = VirtualInstallSnippetParser()
    private let installPath = "/virtual/DesktopProbe"

    func testDesktopProbeContractsMatchDesktopFilesAndStrategies() throws {
        try assertContract(
            clientID: "hk4e_cn",
            markerPath: "pkg_version",
            versionSuffix: "/globalgamemanagers",
            strategy: "unity-globalgamemanagers-0xac-fallback-0x88",
            auxiliarySuffixes: [],
            source: .hk4eDesktopProbe
        )
        try assertContract(
            clientID: "hkrpg_global",
            markerPath: "GameAssembly.dll",
            versionSuffix: "/data.unity3d",
            strategy: "unity-data.unity3d-2019",
            auxiliarySuffixes: [],
            source: .hkrpgDesktopProbe
        )
        try assertContract(
            clientID: "nap_global",
            markerPath: "pkg_version",
            versionSuffix: "/globalgamemanagers",
            strategy: "unity-globalgamemanagers-0xc4-with-resources-md5-override",
            auxiliarySuffixes: ["/resources.assets"],
            source: .napDesktopProbe
        )
        try assertContract(
            clientID: "bh3_global",
            markerPath: "pkg_version",
            versionSuffix: "/globalgamemanagers",
            strategy: "unity-globalgamemanagers-0x88",
            auxiliarySuffixes: [],
            source: .bh3DesktopProbe
        )
    }

    func testMatchingReportsAreAcceptedForEveryUnityClientType() throws {
        for clientID in ["hk4e_cn", "hkrpg_global", "nap_global", "bh3_global"] {
            let client = try client(clientID)
            let contract = try XCTUnwrap(client.virtualInstallDesktopProbeContract)
            let result = parser.parse(
                report(client: client, contract: contract, version: "5.3.0"),
                for: client,
                installPath: installPath
            )

            XCTAssertEqual(result.source, contract.source)
            guard case .existing(let version, let metadata, _) = result.probeResult else {
                XCTFail("Expected matching report for \(clientID)")
                continue
            }
            XCTAssertEqual(version, "5.3.0")
            if client.gameType == "bh3" {
                XCTAssertNil(metadata)
            } else {
                XCTAssertEqual(metadata, VirtualInstallMetadata(client: client, gameVersion: version))
            }
        }
    }

    func testMissingMarkerUnreadableVersionAndWrongStrategyAreRejected() throws {
        let hk4e = try client("hk4e_cn")
        let contract = try XCTUnwrap(hk4e.virtualInstallDesktopProbeContract)

        XCTAssertEqual(
            parser.parse(
                report(client: hk4e, contract: contract, markerPresent: false),
                for: hk4e,
                installPath: installPath
            ).probeResult,
            .unreadable
        )
        XCTAssertEqual(
            parser.parse(
                report(client: hk4e, contract: contract, versionReadable: false),
                for: hk4e,
                installPath: installPath
            ).probeResult,
            .unreadable
        )
        let nap = try client("nap_global")
        let napContract = try XCTUnwrap(nap.virtualInstallDesktopProbeContract)
        XCTAssertEqual(
            parser.parse(
                report(client: nap, contract: napContract, auxiliaryReadable: false),
                for: nap,
                installPath: installPath
            ).probeResult,
            .unreadable
        )
        XCTAssertEqual(
            parser.parse(
                report(client: hk4e, contract: contract, strategy: "unity-globalgamemanagers-0x88"),
                for: hk4e,
                installPath: installPath
            ).probeResult,
            .unreadable
        )
    }

    func testReportForOneClientCannotBeReusedForAnotherGameType() throws {
        let hk4e = try client("hk4e_cn")
        let hkrpg = try client("hkrpg_global")
        let contract = try XCTUnwrap(hk4e.virtualInstallDesktopProbeContract)

        XCTAssertEqual(
            parser.parse(
                report(client: hk4e, contract: contract),
                for: hkrpg,
                installPath: installPath
            ).probeResult,
            .unreadable
        )
    }

    func testCBJQRequiresLocalManifestInsteadOfDesktopProbeReport() throws {
        let cbjq = try client("cbjq_global")
        let hk4e = try client("hk4e_cn")
        let contract = try XCTUnwrap(hk4e.virtualInstallDesktopProbeContract)
        let result = parser.parse(
            report(client: hk4e, contract: contract),
            for: cbjq,
            installPath: installPath
        )

        XCTAssertEqual(result.probeResult, .unreadable)
        XCTAssertNil(result.source)
    }

    func testCBJQRejectsNestedLauncherVersionAsLocalManifestEvidence() throws {
        let cbjq = try client("cbjq_global")
        let result = parser.parse(
            """
            {"data":{"game":{"latest":{"version":"2.0.0"}}}}
            """,
            for: cbjq
        )

        XCTAssertEqual(result.probeResult, .unreadable)
        XCTAssertEqual(result.source, .manifestJSON)
    }

    func testMinimalCBJQManifestDoesNotSynthesizeRemoteMetadata() throws {
        let cbjq = try client("cbjq_global")
        let result = parser.parse("{\"projectVersion\":\"2.0.0\"}", for: cbjq)

        guard case .existing(let version, let metadata, let manifestMetadata) = result.probeResult else {
            return XCTFail("Expected top-level local projectVersion evidence")
        }
        XCTAssertEqual(version, "2.0.0")
        XCTAssertNil(metadata)
        XCTAssertNil(manifestMetadata)
    }

    func testProbeIdentityMustMatchPathClientAndServer() throws {
        let client = try client("hk4e_cn")
        let contract = try XCTUnwrap(client.virtualInstallDesktopProbeContract)
        let snippet = report(client: client, contract: contract)

        XCTAssertEqual(parser.parse(snippet, for: client).probeResult, .unreadable)
        XCTAssertEqual(
            parser.parse(snippet, for: client, installPath: "/virtual/Other").probeResult,
            .unreadable
        )
    }

    func testNAPKnownResourcesDigestOverridesUnityVersion() throws {
        let nap = try client("nap_global")
        let contract = try XCTUnwrap(nap.virtualInstallDesktopProbeContract)
        let result = parser.parse(
            report(
                client: nap,
                contract: contract,
                version: "2.0.0",
                resourcesAssetsMD5: "9210cde58b1d5df1a3224c3786139e01"
            ),
            for: nap,
            installPath: installPath
        )

        XCTAssertEqual(result.detectedVersion, "1.0.1")
    }

    private func assertContract(
        clientID: String,
        markerPath: String,
        versionSuffix: String,
        strategy: String,
        auxiliarySuffixes: [String],
        source: VirtualInstallSnippetSource
    ) throws {
        let contract = try XCTUnwrap(client(clientID).virtualInstallDesktopProbeContract)
        XCTAssertEqual(contract.markerPath, markerPath)
        XCTAssertTrue(contract.versionPath.hasSuffix(versionSuffix))
        XCTAssertEqual(contract.versionStrategy, strategy)
        XCTAssertEqual(contract.auxiliaryPaths.count, auxiliarySuffixes.count)
        for (path, suffix) in zip(contract.auxiliaryPaths, auxiliarySuffixes) {
            XCTAssertTrue(path.hasSuffix(suffix))
        }
        XCTAssertEqual(contract.source, source)
    }

    private func client(_ id: String) throws -> GameClientDescriptor {
        try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == id })
    }

    private func report(
        client: GameClientDescriptor,
        contract: VirtualInstallDesktopProbeContract,
        markerPresent: Bool = true,
        versionReadable: Bool = true,
        auxiliaryReadable: Bool = true,
        strategy: String? = nil,
        version: String = "5.3.0",
        resourcesAssetsMD5: String = "00000000000000000000000000000000"
    ) -> String {
        let versionFields = client.gameType == "nap"
            ? "\"unityVersion\": \"\(version)\",\n    \"resourcesAssetsMD5\": \"\(resourcesAssetsMD5)\""
            : "\"version\": \"\(version)\""
        return """
        {
          "desktopProbe": {
            "installPath": "\(installPath)",
            "clientID": "\(client.id)",
            "serverID": "\(client.serverID)",
            "markerPath": "\(contract.markerPath)",
            "markerPresent": \(markerPresent),
            "versionPath": "\(contract.versionPath)",
            "versionReadable": \(versionReadable),
            "auxiliaryPaths": \(jsonArray(contract.auxiliaryPaths)),
            "auxiliaryReadable": \(auxiliaryReadable),
            "versionStrategy": "\(strategy ?? contract.versionStrategy)",
            \(versionFields)
          }
        }
        """
    }

    private func jsonArray(_ values: [String]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: values)
        return String(decoding: data, as: UTF8.self)
    }
}
