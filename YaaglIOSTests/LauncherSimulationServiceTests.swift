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
        XCTAssertTrue(logs.contains("launch: desktop removed-file patch plan moves YuanShen_Data/upload_crash.exe, YuanShen_Data/Plugins/crashreport.exe, YuanShen_Data/Plugins/vulkan-1.dll to .bak and restores them after exit"))
        XCTAssertTrue(logs.contains("launch: Wine distro Wine 11.0 DXMT (signed, with patches) (11.0-dxmt-signed-with-patches) is simulated only"))
        XCTAssertTrue(logs.contains {
            $0.contains("launch: Box64-style translation reference models x86_64 -> ARM64") &&
                $0.contains("stage plan: ELF loader -> x64 decoder -> DynaBlock planner -> ARM64 dynarec emitter -> wrapped library bridge -> signal/syscall boundary") &&
                $0.contains("source map: ELF loader=src/elfs") &&
                $0.contains("dynarec controls modeled: BOX64_DYNAREC, BOX64_DYNAREC_BIGBLOCK") &&
                $0.contains("disabled: runtime download, binfmt registration, ELF process loading, executable memory/JIT")
        })
        XCTAssertTrue(logs.contains("launch: wine_netbiosname=DESKTOP-IOS0000 is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E Steam path bypasses config.bat cloud flags"))
        let dxmtBlockLog = "dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; " +
            "dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"
        XCTAssertTrue(logs.contains(dxmtBlockLog))
        XCTAssertTrue(logs.contains("launch: WINEESYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(logs.contains("launch: MTL_HUD_ENABLED=1"))
        XCTAssertTrue(logs.contains("launch env preview: MTL_HUD_ENABLED=1"))
        XCTAssertTrue(logs.contains("launch: Wine Mac Driver RetinaMode=y is simulated"))
        XCTAssertTrue(logs.contains("launch: Wine Mac Driver LeftCommandIsCtrl=y is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E HDR registry HKEY_CURRENT_USER\\SOFTWARE\\miHoYo\\原神 WINDOWS_HDR_ON_h3132281285=dword:00000001 is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E resolution registry HKEY_CURRENT_USER\\SOFTWARE\\miHoYo\\原神 Screenmanager Is Fullscreen mode_h3981298716=dword:00000000 Screenmanager Resolution Width_h182942802=dword:00000a00 Screenmanager Resolution Height_h2627697771=dword:000005a0 is simulated"))
        XCTAssertTrue(logs.contains("launch: HTTP_PROXY=127.0.0.1:8080; HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch env preview: HTTP_PROXY=127.0.0.1:8080 HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertTrue(logs.contains("launch env preview: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertTrue(logs.contains("launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 dispatchcnglobal.yuanshen.com for 10s"))
        XCTAssertTrue(logs.contains("launch: would execute C:\\windows\\system32\\steam.exe with YuanShen.exe"))
        XCTAssertTrue(logs.contains("launch command preview: ./wine/bin/wine64 C:\\\\windows\\\\system32\\\\steam.exe YuanShen.exe (not executed)"))
        let reshadeBlockLog = "dependency: ReShade 5.8.0 metadata mirrors installed_reshade; " +
            "ReShade_Setup_5.8.0_Addon.exe, d3dcompiler_47.dll, ReShade64.dll, ReShade.ini were not downloaded"
        XCTAssertTrue(logs.contains(reshadeBlockLog))
        XCTAssertTrue(logs.contains("launch: HK4E HDR registry revert WINDOWS_HDR_ON_h3132281285=- is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E resolution registry revert Screenmanager Is Fullscreen mode_h3981298716, Screenmanager Resolution Width_h182942802, Screenmanager Resolution Height_h2627697771 is simulated"))
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
        XCTAssertTrue(logs.contains("update: 4.9.0 has no desktop patch target; virtual install record will be reset"))
        XCTAssertFalse(logs.contains("update: xdelta/hpatchz and game package writes are disabled"))
        XCTAssertEqual(patchStates, [false])
    }

    @MainActor
    func testInstallProgramEmitsDesktopPipelineTraceWithoutDownloads() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let hk4e = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_cn" })
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let hkrpg = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })

        let hk4eLogs = try await logs(
            service.makeProgram(
                action: .install,
                client: hk4e,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: .empty
            )
        )
        let napLogs = try await logs(
            service.makeProgram(
                action: .install,
                client: nap,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/nap_global",
                state: .empty
            )
        )
        let hkrpgLogs = try await logs(
            service.makeProgram(
                action: .install,
                client: hkrpg,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hkrpg_global",
                state: .empty
            )
        )
        let bh3Logs = try await logs(
            service.makeProgram(
                action: .install,
                client: bh3,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                state: .empty
            )
        )

        XCTAssertTrue(hk4eLogs.contains("install: Sophon startInstallation game_type=hk4e install_reltype=cn is simulated"))
        XCTAssertTrue(hk4eLogs.contains("sidecar: Sophon server metadata mirrors ./sidecar/sophon_server/sophon-server; HK4E install, HK4E update, HK4E pre-download, HK4E integrity repair are not bundled or executed on iOS"))
        XCTAssertTrue(hk4eLogs.contains("install: real Sophon download is disabled on iOS"))
        XCTAssertTrue(hk4eLogs.contains("install: desktop server metadata game_version=5.3.0 channel=1 sub_channel=1 cps=<CN_CPS> is represented without running Sophon side effects"))
        XCTAssertTrue(napLogs.contains("install: Aria2 segmented ZIP download to .ariatmp, concatenation, doStreamUnzip, cleanup, and config.ini write are simulated"))
        XCTAssertTrue(napLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(napLogs.contains("install: config.ini [General] game_version=3.0.0 channel=1 sub_channel=0 cps=<NAP_CPS> is simulated"))
        XCTAssertTrue(hkrpgLogs.contains("install: Aria2 segmented 7z download to .ariatmp, doStreamUn7z, cleanup, and config.ini write are simulated"))
        XCTAssertTrue(bh3Logs.contains("install: Aria2 game.7z download to .ariatmp, extract7z, and config.ini write are simulated"))
        XCTAssertTrue(bh3Logs.contains("install: desktop server metadata game_version=8.4.0 channel=0 sub_channel=0 cps= is retained; BH3 config.ini rewrite is simulated on update"))
        XCTAssertTrue(bh3Logs.contains("install: real Aria2 game archive download is disabled on iOS"))
    }

    @MainActor
    func testSupportedUpdateProgramEmitsDesktopPatchPipelineTrace() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let hk4e = GameLibrary.defaultClients[0]
        let hkrpg = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })

        let hk4eCommands = try await collect(
            service.makeProgram(
                action: .update,
                client: hk4e,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: installedState(for: hk4e, at: "iOS Sandbox/VirtualGameData/hk4e_cn", currentVersion: "5.2.0")
            )
        )
        let hkrpgCommands = try await collect(
            service.makeProgram(
                action: .update,
                client: hkrpg,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hkrpg_global",
                state: installedState(for: hkrpg, at: "iOS Sandbox/VirtualGameData/hkrpg_global", currentVersion: "4.2.0")
            )
        )
        let hk4eLogs = hk4eCommands.compactMap(\.log)
        let hkrpgLogs = hkrpgCommands.compactMap(\.log)

        XCTAssertTrue(hk4eLogs.contains("update: 5.2.0 -> 5.3.0"))
        XCTAssertTrue(hk4eLogs.contains("update: Sophon startUpdate game_type=hk4e tempdir=.tmp predownload=false is simulated"))
        XCTAssertTrue(hk4eLogs.contains("sidecar: Sophon server metadata mirrors ./sidecar/sophon_server/sophon-server; HK4E install, HK4E update, HK4E pre-download, HK4E integrity repair are not bundled or executed on iOS"))
        XCTAssertTrue(hk4eLogs.contains("update: Sophon diff/chunk downloads and game package writes are disabled"))
        XCTAssertTrue(hk4eLogs.contains("update: Sophon delete_file, ldiff_download_complete, chunk_progress, and delete_ldiff_file events are simulated"))
        XCTAssertTrue(hk4eLogs.contains("update: desktop server metadata game_version=5.3.0 channel=1 sub_channel=1 cps=<CN_CPS> is represented without running Sophon side effects"))
        XCTAssertEqual(hk4eCommands.compactMap(\.virtualPatchState), [false])

        XCTAssertTrue(hkrpgLogs.contains("update: 4.2.0 -> 4.3.0"))
        XCTAssertTrue(hkrpgLogs.contains("update: Aria2 patch archive download to .ariatmp, extract7z, deletefiles.txt, hdiffmap.json, hpatchz, and audio package patches are simulated"))
        XCTAssertTrue(hkrpgLogs.contains {
            $0.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c") &&
                $0.contains("sidecar: hpatchz metadata mirrors ./sidecar/hpatchz/hpatchz")
        })
        XCTAssertTrue(hkrpgLogs.contains("update: Aria2 patch archive downloads and game package writes are disabled"))
        XCTAssertTrue(hkrpgLogs.contains("update: extract7z output, deletefiles.txt cleanup, and hdiffmap.json patch map are simulated"))
        XCTAssertTrue(hkrpgLogs.contains("update: config.ini [General] game_version=4.3.0 channel=1 sub_channel=1 cps=<HKRPG_OS_CPS> is simulated"))
        XCTAssertTrue(hkrpgLogs.contains("update: predownloaded_all and per-archive predownload markers would be cleared"))
    }

    @MainActor
    func testPredownloadIntegrityAndLauncherUpdateTracesMatchDesktopPipelines() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let hk4e = GameLibrary.defaultClients[0]
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })

        let hk4ePredownloadLogs = try await logs(
            service.makeProgram(
                action: .predownload,
                client: hk4e,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: installedState(for: hk4e, at: "iOS Sandbox/VirtualGameData/hk4e_cn")
            )
        )
        let napIntegrityLogs = try await logs(
            service.makeProgram(
                action: .checkIntegrity,
                client: nap,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/nap_global",
                state: installedState(for: nap, at: "iOS Sandbox/VirtualGameData/nap_global")
            )
        )
        let hk4eIntegrityLogs = try await logs(
            service.makeProgram(
                action: .checkIntegrity,
                client: hk4e,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                state: installedState(for: hk4e, at: "iOS Sandbox/VirtualGameData/hk4e_cn")
            )
        )
        let launcherUpdateLogs = try await logs(
            service.makeProgram(
                action: .checkLauncherUpdate,
                client: bh3,
                configuration: launchSnapshot(),
                installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                state: installedState(for: bh3, at: "iOS Sandbox/VirtualGameData/bh3_global")
            )
        )

        XCTAssertTrue(hk4ePredownloadLogs.contains("predownload: Sophon startUpdate game_type=hk4e tempdir=.tmp predownload=true is simulated"))
        XCTAssertTrue(hk4ePredownloadLogs.contains("sidecar: Sophon server metadata mirrors ./sidecar/sophon_server/sophon-server; HK4E install, HK4E update, HK4E pre-download, HK4E integrity repair are not bundled or executed on iOS"))
        XCTAssertTrue(hk4ePredownloadLogs.contains("predownload: no game archive, diff, voice pack, or Sophon manifest was requested"))
        XCTAssertTrue(hk4ePredownloadLogs.contains("predownload: hk4e pipeline does not use per-archive marker keys"))
        XCTAssertTrue(hk4ePredownloadLogs.contains("predownload: predownloaded_all marker is simulated"))
        XCTAssertTrue(napIntegrityLogs.contains("integrity: pkg_version scan with size/md5 checks and Aria2 repair downloads is simulated"))
        XCTAssertTrue(napIntegrityLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(hk4eIntegrityLogs.contains("integrity: Sophon startRepair game_type=hk4e repair_mode=reliable is simulated"))
        XCTAssertTrue(hk4eIntegrityLogs.contains("sidecar: Sophon server metadata mirrors ./sidecar/sophon_server/sophon-server; HK4E install, HK4E update, HK4E pre-download, HK4E integrity repair are not bundled or executed on iOS"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: GitHub latest release lookup for bh3glb is simulated"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: resources_bh3glb.neu and Yaagl.Honkai.Global.app.tar.gz were not downloaded"))
        XCTAssertTrue(launcherUpdateLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: resources.neu was not replaced"))
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
        XCTAssertTrue(logs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(logs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(logs.contains("launch: jadeite.exe wraps BH3.exe"))
        XCTAssertTrue(logs.contains("launch: desktop removed-file patch plan moves BH3_Data/Plugins/crashreport.exe, BH3_Data/Plugins/vulkan-1.dll to .bak and restores them after exit"))
        XCTAssertTrue(logs.contains("launch: MVK_ALLOW_METAL_FENCES=1"))
        XCTAssertTrue(logs.contains("launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"))
        XCTAssertTrue(logs.contains("launch: WINEESYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertFalse(logs.contains("launch: game AC patch is disabled"))
        XCTAssertFalse(logs.contains("launch: workaround3 skips tagged patch payloads"))
        XCTAssertFalse(logs.contains("launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertFalse(logs.contains { $0.contains("steam.exe") })
        XCTAssertFalse(logs.contains { $0.contains("hosts edit disabled on iOS") })
        XCTAssertFalse(stateTexts.contains("Simulating HDR registry write"))
        XCTAssertFalse(stateTexts.contains("Applying 2560x1440"))
    }

    @MainActor
    func testNAPResolutionTraceMatchesSteamAndBatchLaunchPaths() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        let directory = "iOS Sandbox/VirtualGameData/nap_global"

        let batchCommands = try await collect(
            service.makeProgram(
                action: .launch,
                client: client,
                configuration: launchSnapshot(
                    steamPatch: false,
                    blockNet: true,
                    resolutionCustom: true,
                    resolutionWidth: 1280,
                    resolutionHeight: 720,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: client, at: directory)
            )
        )
        let batchLogs = batchCommands.compactMap(\.log)

        XCTAssertTrue(batchLogs.contains("launch: NAP WebView cleanup HKEY_CURRENT_USER\\Software\\miHoYo\\ZenlessZoneZero removes MIHOYOSDK_WEBVIEW_RENDER_METHOD_h1573598267 and HOYO_WEBVIEW_RENDER_METHOD_ABTEST_*"))
        XCTAssertTrue(batchLogs.contains("launch: NAP args -screen-width 1280 -screen-height 720 -screen-fullscreen 0"))
        XCTAssertTrue(batchLogs.contains("launch: WINEMSYNC=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(batchLogs.contains("launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 globaldp-prod-os01.zenlesszonezero.com for 20s"))
        XCTAssertTrue(batchLogs.contains("launch: would execute cmd /c config.bat for ZenlessZoneZero.exe"))
        XCTAssertTrue(batchLogs.contains("launch command preview: ./wine/bin/wine64 cmd /c config.bat for ZenlessZoneZero.exe (not executed)"))
        XCTAssertTrue(batchLogs.contains("launch: NAP Screenmanager registry cleanup is simulated"))
        XCTAssertFalse(batchLogs.contains { $0.contains("Steam path bypasses resolution args") })

        let steamCommands = try await collect(
            service.makeProgram(
                action: .launch,
                client: client,
                configuration: launchSnapshot(
                    steamPatch: true,
                    resolutionCustom: true,
                    resolutionWidth: 1280,
                    resolutionHeight: 720,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: client, at: directory)
            )
        )
        let steamLogs = steamCommands.compactMap(\.log)

        XCTAssertTrue(steamLogs.contains("launch: NAP Steam path bypasses resolution args -screen-width 1280 -screen-height 720 -screen-fullscreen 0"))
        XCTAssertTrue(steamLogs.contains("launch: would execute C:\\windows\\system32\\steam.exe with ZenlessZoneZero.exe"))
        XCTAssertTrue(steamLogs.contains("launch command preview: ./wine/bin/wine64 C:\\\\windows\\\\system32\\\\steam.exe ZenlessZoneZero.exe (not executed)"))
        XCTAssertFalse(steamLogs.contains("launch: NAP args -screen-width 1280 -screen-height 720 -screen-fullscreen 0"))
    }

    @MainActor
    func testHKRPGLaunchTraceIncludesJadeiteNVEXTAndHostsPlan() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hkrpg_global" })
        let directory = "iOS Sandbox/VirtualGameData/hkrpg_global"
        let commands = try await collect(
            service.makeProgram(
                action: .launch,
                client: client,
                configuration: launchSnapshot(
                    proxyEnabled: true,
                    proxyHost: "127.0.0.1:8080",
                    blockNet: true,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: client, at: directory)
            )
        )
        let logs = commands.compactMap(\.log)

        XCTAssertTrue(logs.contains("launch: HKRPG WebView cleanup HKEY_CURRENT_USER\\Software\\Cognosphere\\Star Rail removes MIHOYOSDK_WEBVIEW_RENDER_METHOD_h1573598267 and HOYO_WEBVIEW_RENDER_METHOD_ABTEST_*"))
        XCTAssertTrue(logs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(logs.contains("launch: jadeite.exe wraps StarRail.exe -- -disable-gpu-skinning"))
        XCTAssertTrue(logs.contains("launch: HKRPG NVIDIA extension registry writes are simulated"))
        XCTAssertTrue(logs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(logs.contains("launch: WINEMSYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60;dxgi.customVendorId=10de;dxgi.customDeviceId=2684; DXMT_ENABLE_NVEXT=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(logs.contains("launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 globaldp-prod-os01.starrails.com for 15s"))
        XCTAssertTrue(logs.contains("launch: HTTP_PROXY=127.0.0.1:8080; HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch env preview: HTTP_PROXY=127.0.0.1:8080 HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch: would execute cmd /c config.bat for StarRail.exe"))
        XCTAssertTrue(logs.contains("launch command preview: ./wine/bin/wine64 cmd /c config.bat for StarRail.exe (not executed)"))
        XCTAssertFalse(logs.contains { $0.contains("steam.exe") })
        XCTAssertFalse(logs.contains { $0.contains("resolution registry") })
        XCTAssertFalse(logs.contains { $0.contains("HDR registry") })
    }

    @MainActor
    func testCBJQTracesMatchSeasunManifestPipelines() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let cbjq = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_global" })
        let cbjqCN = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_cn" })
        let directory = "iOS Sandbox/VirtualGameData/cbjq_global"

        let installLogs = try await logs(
            service.makeProgram(
                action: .install,
                client: cbjq,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: .empty
            )
        )
        XCTAssertTrue(installLogs.contains("install: Seasun manifest pak download from dlc/pathOffset/hash into manifest-defined files is simulated"))
        XCTAssertTrue(installLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(installLogs.contains("install: real Seasun pak downloads are disabled on iOS"))
        XCTAssertTrue(installLogs.contains {
            $0.contains("install: Seasun manifest metadata") &&
                $0.contains("projectVersion=2.1.0") &&
                $0.contains("version=2.1.0.83") &&
                $0.contains("pathOffset=assets") &&
                $0.contains("paks=1473") &&
                $0.contains("channel=seasun")
        })

        let updateLogs = try await logs(
            service.makeProgram(
                action: .update,
                client: cbjq,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: installedState(for: cbjq, at: directory, currentVersion: "2.0.0")
            )
        )
        XCTAssertTrue(updateLogs.contains("update: Seasun manifest diff compares local manifest.json paks by hash, removes stale paks, and downloads missing paks via Aria2"))
        XCTAssertTrue(updateLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertFalse(updateLogs.contains { $0.contains("hpatchz") })
        XCTAssertTrue(updateLogs.contains("update: Seasun pak downloads and manifest.json writes are disabled"))
        XCTAssertTrue(updateLogs.contains("update: stale pak removal, manifest.json rewrite, and patched marker clear are simulated"))

        let launchLogs = try await logs(
            service.makeProgram(
                action: .launch,
                client: cbjq,
                configuration: launchSnapshot(
                    reshade: true,
                    patchOff: false,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: cbjq, at: directory)
            )
        )
        XCTAssertTrue(launchLogs.contains("launch: CBJQ version 2.1.0 is above desktop supported 2.0.0; desktop would show unsupported-version alert unless patchOff is enabled"))
        XCTAssertTrue(launchLogs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(launchLogs.contains {
            $0.contains("dependency: Media Foundation mf-install metadata has no desktop installed-version key") &&
                $0.contains("mfplat.dll") &&
                $0.contains("wmf.reg")
        })
        XCTAssertTrue(launchLogs.contains("launch: CBJQ config.bat runs Game/Binaries/Win64/Game.exe -FeatureLevelES31 -ChannelID=seasun"))
        XCTAssertTrue(launchLogs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(launchLogs.contains("launch: WINEMSYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(launchLogs.contains("launch: MVK_ALLOW_METAL_FENCES=1"))
        XCTAssertTrue(launchLogs.contains("launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"))
        XCTAssertTrue(launchLogs.contains("launch: would execute cmd /c config.bat for Game/Binaries/Win64/Game.exe"))
        XCTAssertTrue(launchLogs.contains("launch command preview: ./wine/bin/wine64 cmd /c config.bat for Game/Binaries/Win64/Game.exe (not executed)"))

        let cnLaunchLogs = try await logs(
            service.makeProgram(
                action: .launch,
                client: cbjqCN,
                configuration: launchSnapshot(patchOff: true, wineDistro: "v9.2-mingw"),
                installDirectory: "iOS Sandbox/VirtualGameData/cbjq_cn",
                state: installedState(for: cbjqCN, at: "iOS Sandbox/VirtualGameData/cbjq_cn")
            )
        )
        XCTAssertTrue(cnLaunchLogs.contains("launch: CBJQ config.bat runs Game/Binaries/Win64/Game.exe -FeatureLevelES31 -ChannelID=jinshan"))
        XCTAssertTrue(cnLaunchLogs.contains("launch: desktop source marks this channel as broken due to AntiCheat"))
        XCTAssertFalse(cnLaunchLogs.contains { $0.contains("DXMT_CONFIG") })
    }

    private func collect(_ program: CommonUpdateProgram) async throws -> [CapturedCommand] {
        var commands = [CapturedCommand]()
        for try await command in program {
            commands.append(CapturedCommand(command))
        }
        return commands
    }

    private func logs(_ program: CommonUpdateProgram) async throws -> [String] {
        try await collect(program).compactMap(\.log)
    }

    private func index(of value: String, in values: [String]) -> Int {
        guard let index = values.firstIndex(of: value) else {
            XCTFail("Missing \(value)")
            return Int.max
        }
        return index
    }

    @MainActor
    private func installedState(
        for client: GameClientDescriptor,
        at directory: String,
        currentVersion: String? = nil
    ) -> ChannelClientState {
        ChannelClientState(
            installState: .installed,
            installDirectory: directory,
            currentVersion: currentVersion ?? client.latestVersion,
            predownloadedAll: false,
            requiresPatchRevert: false
        )
    }

    @MainActor
    private func launchSnapshot(
        metalHud: Bool = false,
        retina: Bool = false,
        leftCmd: Bool = false,
        proxyEnabled: Bool = false,
        proxyHost: String = "127.0.0.1:8080",
        fpsUnlock: FPSUnlockOption = .disabled,
        reshade: Bool = false,
        patchOff: Bool = false,
        workaround3: Bool = true,
        steamPatch: Bool = false,
        blockNet: Bool = false,
        timeoutFix: Bool = false,
        resolutionCustom: Bool = false,
        resolutionWidth: Int = 1920,
        resolutionHeight: Int = 1920,
        hk4eEnableHDR: Bool = false,
        wineDistro: String = "11.0-dxmt-signed-with-patches"
    ) -> LauncherConfigurationSnapshot {
        LauncherConfigurationSnapshot(
            metalHud: metalHud,
            retina: retina,
            leftCmd: leftCmd,
            proxyEnabled: proxyEnabled,
            proxyHost: proxyHost,
            fpsUnlock: fpsUnlock,
            reshade: reshade,
            patchOff: patchOff,
            workaround3: workaround3,
            steamPatch: steamPatch,
            blockNet: blockNet,
            timeoutFix: timeoutFix,
            resolutionCustom: resolutionCustom,
            resolutionWidth: resolutionWidth,
            resolutionHeight: resolutionHeight,
            hk4eEnableHDR: hk4eEnableHDR,
            wineDistro: wineDistro
        )
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
