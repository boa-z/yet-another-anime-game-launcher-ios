import XCTest
@testable import YaaglIOS

@MainActor
final class VirtualImportFormStateTests: XCTestCase {
    private let parser = VirtualInstallSnippetParser()

    func testManualPathAndVersionDoNotPermitExistingImport() throws {
        let client = try hk4eClient()
        var state = VirtualImportFormState()
        state.reset(for: client)

        state.importPath = "/virtual/Genshin Impact"
        state.detectedVersion = "5.3.0"

        XCTAssertFalse(state.canImportExisting(client: client, isBusy: false))
        XCTAssertNil(state.existingImportRequest(client: client))
    }

    func testSuccessfulDesktopProbeBindsImportEvidenceAndMetadata() throws {
        let client = try hk4eClient()
        let contract = try XCTUnwrap(client.virtualInstallDesktopProbeContract)
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = """
        {
          "desktopProbe": {
            "installPath": "\(state.importPath)",
            "clientID": "\(client.id)",
            "serverID": "\(client.serverID)",
            "markerPath": "\(contract.markerPath)",
            "markerPresent": true,
            "versionPath": "\(contract.versionPath)",
            "versionReadable": true,
            "auxiliaryPaths": \(jsonArray(contract.auxiliaryPaths)),
            "auxiliaryReadable": true,
            "versionStrategy": "\(contract.versionStrategy)",
            "version": "5.3.0"
          }
        }
        """

        state.apply(
            parser.parse(state.probeSnippet, for: client, installPath: state.importPath),
            client: client
        )

        XCTAssertEqual(state.detectedVersion, "5.3.0")
        XCTAssertTrue(state.canImportExisting(client: client, isBusy: false))
        guard case .existing(let version, let metadata, _)? = state.existingImportRequest(client: client)?.probeResult else {
            return XCTFail("Expected validated existing-install evidence")
        }
        XCTAssertEqual(version, "5.3.0")
        XCTAssertEqual(metadata, VirtualInstallMetadata(client: client, gameVersion: "5.3.0"))
    }

    func testSuccessfulHKRPGSnippetEnablesExistingImport() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let contract = try XCTUnwrap(client.virtualInstallDesktopProbeContract)
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Star Rail"
        state.probeSnippet = """
        {
          "desktopProbe": {
            "installPath": "\(state.importPath)",
            "clientID": "\(client.id)",
            "serverID": "\(client.serverID)",
            "markerPath": "\(contract.markerPath)",
            "markerPresent": true,
            "versionPath": "\(contract.versionPath)",
            "versionReadable": true,
            "auxiliaryPaths": \(jsonArray(contract.auxiliaryPaths)),
            "auxiliaryReadable": true,
            "versionStrategy": "\(contract.versionStrategy)",
            "version": "4.3.0"
          }
        }
        """

        state.apply(
            parser.parse(state.probeSnippet, for: client, installPath: state.importPath),
            client: client
        )

        XCTAssertEqual(state.detectedVersion, "4.3.0")
        XCTAssertTrue(state.canImportExisting(client: client, isBusy: false))
        XCTAssertFalse(state.canImportExisting(client: client, isBusy: true))
    }

    func testChangingEvidenceInputsInvalidatesExistingImport() throws {
        let client = try hk4eClient()
        let otherClient = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_global" })

        for mutation in Mutation.allCases {
            var state = probedState(for: client)
            switch mutation {
            case .path:
                state.importPath += "/other"
            case .version:
                state.detectedVersion = "5.4.0"
            case .snippet:
                state.probeSnippet += "\nchannel=2"
            }
            state.reconcileEvidence(client: client)

            XCTAssertFalse(
                state.canImportExisting(client: client, isBusy: false),
                "Expected \(mutation) mutation to invalidate probe evidence"
            )
        }

        let state = probedState(for: client)
        XCTAssertFalse(state.canImportExisting(client: otherClient, isBusy: false))
    }

    func testUnreadableSnippetClearsPreviousEvidence() throws {
        let client = try hk4eClient()
        var state = probedState(for: client)
        state.probeSnippet = "not game metadata"
        state.apply(parser.parse(state.probeSnippet, for: client), client: client)

        XCTAssertFalse(state.canImportExisting(client: client, isBusy: false))
        XCTAssertNil(state.existingImportRequest(client: client))
    }

    func testUnattributedOrCrossServerResultCannotBecomeEvidence() throws {
        let client = try hk4eClient()
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = "[General]\ngame_version=5.3.0"

        state.apply(
            VirtualInstallSnippetProbeResult(
                probeResult: .existing(version: "5.3.0"),
                source: nil,
                message: "Unattributed"
            ),
            client: client
        )
        XCTAssertNil(state.existingImportRequest(client: client))

        state.apply(
            VirtualInstallSnippetProbeResult(
                probeResult: .existing(
                    version: "5.3.0",
                    metadata: VirtualInstallMetadata(
                        gameVersion: "5.3.0",
                        channelID: 1,
                        subchannelID: 1,
                        cpsReference: "OTHER",
                        sourceServerID: "other_server"
                    )
                ),
                source: .configINI,
                message: "Wrong server"
            ),
            client: client
        )
        XCTAssertNil(state.existingImportRequest(client: client))
    }

    func testGenericMetadataSnippetCannotBecomeExistingInstallEvidence() throws {
        let client = try hk4eClient()
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = "[General]\ngame_version=5.3.0"

        state.apply(parser.parse(state.probeSnippet, for: client), client: client)

        XCTAssertNil(state.existingImportRequest(client: client))
    }

    private func probedState(for client: GameClientDescriptor) -> VirtualImportFormState {
        let contract = client.virtualInstallDesktopProbeContract!
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = """
        {
          "desktopProbe": {
            "installPath": "\(state.importPath)",
            "clientID": "\(client.id)",
            "serverID": "\(client.serverID)",
            "markerPath": "\(contract.markerPath)",
            "markerPresent": true,
            "versionPath": "\(contract.versionPath)",
            "versionReadable": true,
            "auxiliaryPaths": \(jsonArray(contract.auxiliaryPaths)),
            "auxiliaryReadable": true,
            "versionStrategy": "\(contract.versionStrategy)",
            "version": "5.3.0"
          }
        }
        """
        state.apply(
            parser.parse(state.probeSnippet, for: client, installPath: state.importPath),
            client: client
        )
        return state
    }

    private func hk4eClient() throws -> GameClientDescriptor {
        try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
    }

    private func jsonArray(_ values: [String]) -> String {
        let data = try! JSONSerialization.data(withJSONObject: values)
        return String(decoding: data, as: UTF8.self)
    }
}

private extension VirtualImportFormStateTests {
    enum Mutation: CaseIterable {
        case path
        case version
        case snippet
    }
}
