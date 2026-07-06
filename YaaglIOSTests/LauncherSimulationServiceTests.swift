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
                    retina: true,
                    leftCmd: true,
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
        XCTAssertTrue(logs.contains("launch: Wine distro Wine 11.0 DXMT (signed, with patches) (11.0-dxmt-signed-with-patches) is simulated only"))
        XCTAssertTrue(logs.contains("launch: HK4E args -platform_type CLOUD_THIRD_PARTY_PC -is_cloud 1"))
        XCTAssertTrue(logs.contains("launch: DXMT_CONFIG d3d11.preferredMaxFrameRate=60 is simulated"))
        XCTAssertTrue(logs.contains("launch: MTL_HUD_ENABLED=1"))
        XCTAssertTrue(logs.contains("launch: Wine Mac Driver RetinaMode=y is simulated"))
        XCTAssertTrue(logs.contains("launch: Wine Mac Driver LeftCommandIsCtrl=y is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E HDR registry import is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E resolution registry 2560x1440 is simulated"))
        XCTAssertTrue(logs.contains("launch: HTTP_PROXY/HTTPS_PROXY=127.0.0.1:8080"))
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

    @MainActor
    func testLaunchProgramIgnoresUnsupportedGameSettingsForBH3() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
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
                    patchOff: true,
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
                installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                state: ChannelClientState(
                    installState: .installed,
                    installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                    currentVersion: client.latestVersion,
                    predownloadedAll: false,
                    requiresPatchRevert: false
                )
            )
        )
        let stateTexts = commands.compactMap(\.stateText)
        let logs = commands.compactMap(\.log)

        XCTAssertTrue(logs.contains("launch: full patch payload set is simulated"))
        XCTAssertTrue(logs.contains("launch: jadeite.exe wraps BH3.exe"))
        XCTAssertTrue(logs.contains("launch: MVK_ALLOW_METAL_FENCES=1"))
        XCTAssertTrue(logs.contains("launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"))
        XCTAssertTrue(logs.contains("launch: DXMT_CONFIG d3d11.preferredMaxFrameRate=60 is simulated"))
        XCTAssertFalse(logs.contains("launch: game AC patch is disabled"))
        XCTAssertFalse(logs.contains("launch: workaround3 skips tagged patch payloads"))
        XCTAssertFalse(logs.contains("launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertFalse(logs.contains("launch: steam.exe path is simulated"))
        XCTAssertFalse(logs.contains("launch: hosts edit is disabled on iOS"))
        XCTAssertFalse(stateTexts.contains("Simulating HDR registry write"))
        XCTAssertFalse(stateTexts.contains("Applying 2560x1440"))
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
