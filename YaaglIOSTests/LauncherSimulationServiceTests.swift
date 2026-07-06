import XCTest
@testable import YaaglIOS

final class LauncherSimulationServiceTests: XCTestCase {
    @MainActor
    func testLaunchProgramEmitsPatchRunRevertTraceAndConfigurationLogs() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = GameLibrary.defaultClients[0]
        let commands = try await collect(
            service.makeProgram(
                action: .launch,
                client: client,
                configuration: LauncherConfigurationSnapshot(
                    metalHud: true,
                    retina: false,
                    leftCmd: false,
                    proxyEnabled: true,
                    proxyHost: "127.0.0.1:8080",
                    fpsUnlock: .disabled,
                    reshade: true,
                    patchOff: false,
                    workaround3: true,
                    steamPatch: true,
                    blockNet: true,
                    timeoutFix: true,
                    resolutionCustom: true,
                    resolutionWidth: 2560,
                    resolutionHeight: 1440,
                    hk4eEnableHDR: true,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: ChannelClientState(
                    installState: .installed,
                    installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                    currentVersion: client.latestVersion,
                    predownloadedAll: false,
                    requiresPatchRevert: false
                )
            )
        )
        let stateTexts = commands.compactMap(\.stateText)
        let logs = commands.compactMap(\.log)
        let patchStates = commands.compactMap(\.virtualPatchState)

        XCTAssertLessThan(index(of: "Patching game files", in: stateTexts), index(of: "Game is running (simulation)", in: stateTexts))
        XCTAssertLessThan(index(of: "Game is running (simulation)", in: stateTexts), index(of: "Reverting patches", in: stateTexts))
        XCTAssertTrue(logs.contains("launch dir: iOS Sandbox/VirtualGameData/hk4e_cn"))
        XCTAssertTrue(logs.contains("launch: workaround3 skips tagged patch payloads"))
        XCTAssertTrue(logs.contains("launch: Wine distro 11.0-dxmt-signed-with-patches is simulated only"))
        XCTAssertTrue(logs.contains("launch: MTL_HUD_ENABLED=1"))
        XCTAssertTrue(logs.contains("launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertTrue(logs.contains("launch: steam.exe path is simulated"))
        XCTAssertTrue(logs.contains("launch: ReShade download is disabled"))
        XCTAssertTrue(logs.contains("launch: hosts edit is disabled on iOS"))
        XCTAssertEqual(patchStates, [true, false])
    }

    @MainActor
    func testUnsupportedUpdateSkipsPatchDownloadTrace() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = GameLibrary.defaultClients[0]
        let commands = try await collect(
            service.makeProgram(
                action: .update,
                client: client,
                configuration: LauncherConfigurationSnapshot(
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
                ),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: ChannelClientState(
                    installState: .installed,
                    installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                    currentVersion: "4.9.0",
                    predownloadedAll: false,
                    requiresPatchRevert: true
                )
            )
        )
        let stateTexts = commands.compactMap(\.stateText)
        let logs = commands.compactMap(\.log)
        let patchStates = commands.compactMap(\.virtualPatchState)

        XCTAssertTrue(stateTexts.contains("Unsupported game version 4.9.0"))
        XCTAssertFalse(stateTexts.contains("Update simulation complete"))
        XCTAssertFalse(logs.contains("update: xdelta/hpatchz and game package writes are disabled"))
        XCTAssertEqual(patchStates, [false])
    }

    private func collect(_ program: CommonUpdateProgram) async throws -> [CapturedCommand] {
        var commands = [CapturedCommand]()
        for try await command in program {
            commands.append(CapturedCommand(command))
        }
        return commands
    }

    private func index(of value: String, in values: [String]) -> Int {
        guard let index = values.firstIndex(of: value) else {
            XCTFail("Missing \(value)")
            return Int.max
        }
        return index
    }
}

private struct CapturedCommand {
    let stateText: String?
    let log: String?
    let virtualPatchState: Bool?

    init(_ command: ProgressCommand) {
        switch command {
        case .setStateText(let stateText):
            self.stateText = stateText
            log = nil
            virtualPatchState = nil
        case .appendLog(let log):
            stateText = nil
            self.log = log
            virtualPatchState = nil
        case .setVirtualPatchState(let virtualPatchState):
            stateText = nil
            log = nil
            self.virtualPatchState = virtualPatchState
        case .setProgress, .setUndeterminedProgress:
            stateText = nil
            log = nil
            virtualPatchState = nil
        }
    }
}
