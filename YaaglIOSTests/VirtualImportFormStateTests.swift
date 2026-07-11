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

    func testSuccessfulSnippetBindsImportEvidenceAndMetadata() throws {
        let client = try hk4eClient()
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = """
        [General]
        game_version=5.3.0
        channel=9
        sub_channel=2
        cps=<CUSTOM_CPS>
        """

        state.apply(parser.parse(state.probeSnippet, for: client), client: client)

        XCTAssertEqual(state.detectedVersion, "5.3.0")
        XCTAssertTrue(state.canImportExisting(client: client, isBusy: false))
        guard case .existing(let version, let metadata, _)? = state.existingImportRequest(client: client)?.probeResult else {
            return XCTFail("Expected validated existing-install evidence")
        }
        XCTAssertEqual(version, "5.3.0")
        XCTAssertEqual(metadata?.channelID, 9)
        XCTAssertEqual(metadata?.subchannelID, 2)
        XCTAssertEqual(metadata?.cpsReference, "CUSTOM_CPS")
    }

    func testSuccessfulHKRPGSnippetEnablesExistingImport() throws {
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Star Rail"
        state.probeSnippet = """
        {
          "data": {
            "game": {
              "latest": {
                "version": "4.3.0"
              }
            }
          }
        }
        """

        state.apply(parser.parse(state.probeSnippet, for: client), client: client)

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

    private func probedState(for client: GameClientDescriptor) -> VirtualImportFormState {
        var state = VirtualImportFormState()
        state.reset(for: client)
        state.importPath = "/virtual/Genshin Impact"
        state.probeSnippet = "[General]\ngame_version=5.3.0"
        state.apply(parser.parse(state.probeSnippet, for: client), client: client)
        return state
    }

    private func hk4eClient() throws -> GameClientDescriptor {
        try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
    }
}

private extension VirtualImportFormStateTests {
    enum Mutation: CaseIterable {
        case path
        case version
        case snippet
    }
}
