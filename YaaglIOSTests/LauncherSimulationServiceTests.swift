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
        XCTAssertTrue(logs.contains {
            $0.contains("launch: desktop DXMT copy plan") &&
                $0.contains("./wine/lib/wine/x86_64-windows") &&
                $0.contains("winemetal.dll to x86_64-windows and system32") &&
                $0.contains("winemetal.so to x86_64-unix") &&
                $0.contains("not copied on iOS")
        })
        XCTAssertTrue(logs.contains("launch: WINEESYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(logs.contains("launch: desktop protonextras copy plan maps steam64.exe -> system32/steam.exe, steam32.exe -> syswow64/steam.exe, lsteamclient64.dll -> system32/lsteamclient.dll, lsteamclient32.dll -> syswow64/lsteamclient.dll (not copied on iOS)"))
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
        XCTAssertTrue(logs.contains("launch: desktop Wine loader candidates ./wine/bin/wine64 -> ./wine/bin/wine; desktop probes wine64 first and falls back to wine for newer WoW64 layouts; candidates are x86_64 targets for the Box64-style reference plan; no loader was probed on iOS"))
        XCTAssertTrue(logs.contains("launch command preview candidates: ./wine/bin/wine64 C:\\\\windows\\\\system32\\\\steam.exe YuanShen.exe OR ./wine/bin/wine C:\\\\windows\\\\system32\\\\steam.exe YuanShen.exe; desktop uses the first existing loader (not probed or executed on iOS)"))
        let reshadeBlockLog = "dependency: ReShade 5.8.0 metadata mirrors installed_reshade; " +
            "ReShade_Setup_5.8.0_Addon.exe, install.exe, install.zip, d3dcompiler_47.dll, ReShade64.dll, dxgi.dll, ReShade.ini were not downloaded, extracted, copied, or written"
        XCTAssertTrue(logs.contains(reshadeBlockLog))
        XCTAssertTrue(logs.contains("launch: desktop ReShade copy plan maps ./reshade/dxgi.dll -> game dir dxgi.dll and ./reshade/d3dcompiler_47.dll -> game dir d3dcompiler_47.dll (not copied on iOS)"))
        XCTAssertTrue(logs.contains("launch: HK4E HDR registry revert WINDOWS_HDR_ON_h3132281285=- is simulated"))
        XCTAssertTrue(logs.contains("launch: HK4E resolution registry revert Screenmanager Is Fullscreen mode_h3981298716, Screenmanager Resolution Width_h182942802, Screenmanager Resolution Height_h2627697771 is simulated"))
        XCTAssertTrue(logs.contains("launch: desktop DXMT revert plan restores d3d10core.dll, d3d11.dll, dxgi.dll from .bak in ./wine/lib/wine/x86_64-windows; winemetal, nvngx, and protonextras copies are not reverted by desktop patchRevertProgram (not restored on iOS)"))
        XCTAssertTrue(logs.contains("launch: desktop ReShade revert plan removes game dir dxgi.dll and d3dcompiler_47.dll (not removed on iOS)"))
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
        XCTAssertTrue(bh3Logs.contains("install: Aria2 game.7z download to .ariatmp and extract7z are simulated; desktop does not write config.ini on fresh BH3 install"))
        XCTAssertTrue(bh3Logs.contains("install: desktop BH3 install does not write config.ini; server metadata game_version=8.4.0 channel=0 sub_channel=0 cps= is retained only for update simulation"))
        XCTAssertTrue(bh3Logs.contains("install: BH3 virtual record tracks version only; config.ini metadata remains absent until update or explicit import"))
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
        XCTAssertTrue(hk4eLogs.contains {
            $0.contains("update: HK4E target 5.3.0 is >= 3.6.0") &&
                $0.contains("iOS Sandbox/VirtualGameData/hk4e_cn/YuanShen_Data/StreamingAssets/Audio/GeneratedSoundBanks/Windows") &&
                $0.contains("/bin/cp -R -f") &&
                $0.contains("iOS Sandbox/VirtualGameData/hk4e_cn/YuanShen_Data/StreamingAssets/AudioAssets") &&
                $0.contains("no files were read or changed on iOS")
        })
        let migrationIndex = try XCTUnwrap(hk4eLogs.firstIndex { $0.contains("HK4E target 5.3.0 is >= 3.6.0") })
        let sophonIndex = try XCTUnwrap(hk4eLogs.firstIndex { $0.contains("Sophon startUpdate") })
        XCTAssertLessThan(migrationIndex, sophonIndex)
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
        XCTAssertFalse(hkrpgLogs.contains { $0.contains("legacy audio migration") })
    }

    @MainActor
    func testHK4ELegacyAudioMigrationOnlyAppliesToTargetsAtLeastThreeSix() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let hk4e = GameLibrary.defaultClients[0].applying(
            runtimeMetadata: GameClientRuntimeMetadata(
                latestVersion: "3.5.0",
                updatableVersions: ["3.4.0"]
            )
        )
        let directory = "iOS Sandbox/VirtualGameData/hk4e_cn"

        let logs = try await logs(
            service.makeProgram(
                action: .update,
                client: hk4e,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: installedState(for: hk4e, at: directory, currentVersion: "3.4.0")
            )
        )

        XCTAssertTrue(logs.contains("update: 3.4.0 -> 3.5.0"))
        XCTAssertFalse(logs.contains { $0.contains("legacy audio migration") })
        XCTAssertFalse(logs.contains { $0.contains("GeneratedSoundBanks/Windows") })
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
        XCTAssertEqual(napIntegrityLogs, [])
        XCTAssertTrue(hk4eIntegrityLogs.contains("integrity: Sophon startRepair game_type=hk4e repair_mode=reliable is simulated"))
        XCTAssertTrue(hk4eIntegrityLogs.contains("sidecar: Sophon server metadata mirrors ./sidecar/sophon_server/sophon-server; HK4E install, HK4E update, HK4E pre-download, HK4E integrity repair are not bundled or executed on iOS"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: GitHub latest release lookup for bh3glb is simulated"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: resources_bh3glb.neu and Yaagl.Honkai.Global.app.tar.gz were not downloaded"))
        XCTAssertTrue(launcherUpdateLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(launcherUpdateLogs.contains("launcher update: resources.neu was not replaced"))
    }

    @MainActor
    func testBH3LaunchGuardAndResidualPatchOffTraceMatchDesktop() async throws {
        let service = LauncherSimulationService(stepDurationMilliseconds: 0)
        let client = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let blockedCommands = try await collect(
            service.makeProgram(
                action: .launch,
                client: client,
                configuration: launchSnapshot(
                    patchOff: true,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                state: installedState(for: client, at: "iOS Sandbox/VirtualGameData/bh3_global")
            )
        )
        let blockedStateTexts = blockedCommands.compactMap(\.stateText)
        let blockedLogs = blockedCommands.compactMap(\.log)

        XCTAssertTrue(blockedStateTexts.contains("Unsupported game version 8.4.0"))
        XCTAssertTrue(blockedLogs.contains("launch: BH3 version 8.4.0 is above desktop supported 7.5.0; desktop would show unsupported-version alert and skip launch; patchOff is unavailable for this desktop channel"))
        XCTAssertFalse(blockedLogs.contains { $0.contains("dependency: Jadeite") })
        XCTAssertFalse(blockedLogs.contains { $0.contains("launch command preview") })

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
                    currentVersion: client.currentSupportedVersion,
                    predownloadedAll: false,
                    requiresPatchRevert: false
                )
            )
        )
        let stateTexts = commands.compactMap(\.stateText)
        let logs = commands.compactMap(\.log)

        XCTAssertTrue(logs.contains("launch: full patch payload set is simulated"))
        XCTAssertFalse(logs.contains("launch: game AC patch is disabled"))
        XCTAssertFalse(logs.contains("launch: patchOff requested no game file patch"))
        XCTAssertTrue(logs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(logs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(logs.contains {
            $0.contains("launch: desktop DXMT copy plan") &&
                $0.contains("./wine/lib/wine/x86_64-windows") &&
                $0.contains("winemetal.dll to x86_64-windows and system32") &&
                $0.contains("not copied on iOS")
        })
        XCTAssertTrue(logs.contains("launch: jadeite.exe wraps BH3.exe"))
        XCTAssertTrue(logs.contains("launch: desktop protonextras copy plan maps steam64.exe -> system32/steam.exe, steam32.exe -> syswow64/steam.exe, lsteamclient64.dll -> system32/lsteamclient.dll, lsteamclient32.dll -> syswow64/lsteamclient.dll (not copied on iOS)"))
        XCTAssertTrue(logs.contains("launch: desktop ReShade copy plan maps ./reshade/dxgi.dll -> game dir dxgi.dll and ./reshade/d3dcompiler_47.dll -> game dir d3dcompiler_47.dll (not copied on iOS)"))
        XCTAssertTrue(logs.contains("launch: MVK_ALLOW_METAL_FENCES=1"))
        XCTAssertTrue(logs.contains("launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"))
        XCTAssertTrue(logs.contains("launch: WINEMSYNC=1; DXMT_LOG_PATH=./; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(logs.contains("launch: desktop DXMT revert plan restores d3d10core.dll, d3d11.dll, dxgi.dll from .bak in ./wine/lib/wine/x86_64-windows; winemetal, nvngx, and protonextras copies are not reverted by desktop patchRevertProgram (not restored on iOS)"))
        XCTAssertTrue(logs.contains("launch: desktop ReShade revert plan removes game dir dxgi.dll and d3dcompiler_47.dll (not removed on iOS)"))
        XCTAssertTrue(logs.contains("launch: desktop removed-file patch plan moves BH3_Data/Plugins/crashreport.exe, BH3_Data/Plugins/vulkan-1.dll to .bak and restores them after exit"))
        XCTAssertFalse(logs.contains("launch: workaround3 skips tagged patch payloads"))
        XCTAssertFalse(logs.contains("launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        XCTAssertFalse(logs.contains("launch: would execute C:\\windows\\system32\\steam.exe with BH3.exe"))
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
        XCTAssertTrue(batchLogs.contains("launch: desktop removed-file patch plan moves ZenlessZoneZero_Data/Plugins/x86_64/vulkan-1.dll to .bak and restores them after exit"))
        XCTAssertTrue(batchLogs.contains("launch: desktop protonextras copy plan maps steam64.exe -> system32/steam.exe, steam32.exe -> syswow64/steam.exe, lsteamclient64.dll -> system32/lsteamclient.dll, lsteamclient32.dll -> syswow64/lsteamclient.dll (not copied on iOS)"))
        XCTAssertTrue(batchLogs.contains {
            $0.contains("launch: desktop DXMT copy plan") &&
                $0.contains("./wine/lib/wine/x86_64-windows") &&
                $0.contains("winemetal.so to x86_64-unix")
        })
        XCTAssertTrue(batchLogs.contains("launch: NAP args -screen-width 1280 -screen-height 720 -screen-fullscreen 0"))
        XCTAssertTrue(batchLogs.contains("launch: WINEMSYNC=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(batchLogs.contains("launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 globaldp-prod-os01.zenlesszonezero.com for 20s"))
        XCTAssertTrue(batchLogs.contains("launch: would execute cmd /c config.bat for ZenlessZoneZero.exe"))
        XCTAssertTrue(batchLogs.contains("launch command preview candidates: ./wine/bin/wine64 cmd /c config.bat OR ./wine/bin/wine cmd /c config.bat for ZenlessZoneZero.exe; desktop uses the first existing loader (not probed or executed on iOS)"))
        XCTAssertTrue(batchLogs.contains("launch: NAP Screenmanager registry cleanup is simulated"))
        XCTAssertTrue(batchLogs.contains("launch: desktop DXMT revert plan restores d3d10core.dll, d3d11.dll, dxgi.dll from .bak in ./wine/lib/wine/x86_64-windows; winemetal, nvngx, and protonextras copies are not reverted by desktop patchRevertProgram (not restored on iOS)"))
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
        XCTAssertTrue(steamLogs.contains("launch command preview candidates: ./wine/bin/wine64 C:\\\\windows\\\\system32\\\\steam.exe ZenlessZoneZero.exe OR ./wine/bin/wine C:\\\\windows\\\\system32\\\\steam.exe ZenlessZoneZero.exe; desktop uses the first existing loader (not probed or executed on iOS)"))
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
        XCTAssertTrue(logs.contains("launch: desktop removed-file patch plan moves StarRail_Data/Plugins/x86_64/crashreport.exe, StarRail_Data/Plugins/x86_64/vulkan-1.dll to .bak and restores them after exit"))
        XCTAssertTrue(logs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(logs.contains("launch: jadeite.exe wraps StarRail.exe -- -disable-gpu-skinning"))
        XCTAssertTrue(logs.contains("launch: HKRPG NVIDIA extension registry writes are simulated"))
        XCTAssertTrue(logs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(logs.contains {
            $0.contains("launch: desktop DXMT copy plan") &&
                $0.contains("nvngx.dll to x86_64-windows and system32") &&
                $0.contains("not copied on iOS")
        })
        XCTAssertTrue(logs.contains("launch: WINEMSYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60;dxgi.customVendorId=10de;dxgi.customDeviceId=2684; DXMT_ENABLE_NVEXT=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(logs.contains("launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 globaldp-prod-os01.starrails.com for 15s"))
        XCTAssertTrue(logs.contains("launch: HTTP_PROXY=127.0.0.1:8080; HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch env preview: HTTP_PROXY=127.0.0.1:8080 HTTPS_PROXY=127.0.0.1:8080"))
        XCTAssertTrue(logs.contains("launch: would execute cmd /c config.bat for StarRail.exe"))
        XCTAssertTrue(logs.contains("launch command preview candidates: ./wine/bin/wine64 cmd /c config.bat OR ./wine/bin/wine cmd /c config.bat for StarRail.exe; desktop uses the first existing loader (not probed or executed on iOS)"))
        XCTAssertTrue(logs.contains("launch: desktop DXMT revert plan restores d3d10core.dll, d3d11.dll, dxgi.dll from .bak in ./wine/lib/wine/x86_64-windows; winemetal and nvngx copies are not reverted by desktop patchRevertProgram (not restored on iOS)"))
        XCTAssertFalse(logs.contains { $0.contains("protonextras") })
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

        var localManifestState = installedState(for: cbjq, at: directory, currentVersion: "2.0.0")
        localManifestState.virtualManifestMetadata = seasunManifest(
            version: "2.0.0.50",
            projectVersion: "2.0.0",
            paks: [
                seasunPak(name: "renamed-local.pak", hash: "same-hash"),
                seasunPak(name: "same-name-old.pak", hash: "old-hash"),
                seasunPak(name: "local-only.pak", hash: "local-hash")
            ]
        )
        let cbjqWithRemoteManifest = cbjq.applying(
            runtimeMetadata: GameClientRuntimeMetadata(
                seasunManifestMetadata: seasunManifest(
                    version: "2.1.0.83",
                    projectVersion: "2.1.0",
                    paks: [
                        seasunPak(name: "renamed-remote.pak", hash: "same-hash"),
                        seasunPak(name: "same-name-old.pak", hash: "new-hash"),
                        seasunPak(name: "remote-only.pak", hash: "remote-hash")
                    ]
                )
            )
        )

        let updateCommands = try await collect(
            service.makeProgram(
                action: .update,
                client: cbjqWithRemoteManifest,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: localManifestState
            )
        )
        let updateLogs = updateCommands.compactMap(\.log)
        XCTAssertTrue(updateLogs.contains("update: Seasun manifest diff compares local manifest.json paks by hash, removes stale paks, and downloads missing paks via Aria2"))
        XCTAssertTrue(updateLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertFalse(updateLogs.contains { $0.contains("hpatchz") })
        XCTAssertTrue(updateLogs.contains("update: Seasun pak downloads and manifest.json writes are disabled"))
        XCTAssertTrue(updateLogs.contains {
            $0.contains("update: Seasun manifest hash diff remove=2 add=2") &&
                $0.contains("first_remove=same-name-old.pak") &&
                $0.contains("first_add=same-name-old.pak") &&
                $0.contains("hash=new-hash") &&
                $0.contains("url=https://snowbreak-dl.amazingseasuncdn.com/6e5452634164107ee3c3cfd6efcdf55f/PC/updates/assets/new-hash") &&
                !$0.contains("renamed-remote.pak")
        })
        XCTAssertTrue(updateLogs.contains("update: stale pak removal, manifest.json rewrite, and patched marker clear are simulated"))
        XCTAssertEqual(updateCommands.compactMap(\.virtualPatchState), [false])

        var missingLocalManifestState = localManifestState
        missingLocalManifestState.virtualManifestMetadata = nil
        let missingLocalManifestLogs = try await logs(
            service.makeProgram(
                action: .update,
                client: cbjqWithRemoteManifest,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: missingLocalManifestState
            )
        )
        XCTAssertTrue(missingLocalManifestLogs.contains {
            $0.contains("local manifest.json metadata is unavailable, so desktop empty-pak fallback applies") &&
                $0.contains("Seasun manifest hash diff remove=0 add=3") &&
                $0.contains("first_add=renamed-remote.pak") &&
                $0.contains("hash=same-hash")
        })

        let summaryOnlyUpdateLogs = try await logs(
            service.makeProgram(
                action: .update,
                client: cbjq,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: localManifestState
            )
        )
        XCTAssertTrue(summaryOnlyUpdateLogs.contains("update: Seasun manifest summary local_paks=3 remote_paks=1473 is represented; remote full pak hash list is unavailable"))
        XCTAssertFalse(summaryOnlyUpdateLogs.contains { $0.contains("Seasun manifest hash diff remove=") })

        let integrityCommands = try await collect(
            service.makeProgram(
                action: .checkIntegrity,
                client: cbjqWithRemoteManifest,
                configuration: launchSnapshot(),
                installDirectory: directory,
                state: localManifestState
            )
        )
        let integrityLogs = integrityCommands.compactMap(\.log)
        XCTAssertTrue(integrityLogs.contains("integrity: Seasun manifest paks size/md5 scan and Aria2 repair downloads are simulated"))
        XCTAssertTrue(integrityLogs.contains("sidecar: aria2 metadata mirrors ./sidecar/aria2/aria2c; install archives, pre-download archives, patch archives, launcher assets, dependency assets are not bundled or executed on iOS"))
        XCTAssertTrue(integrityLogs.contains {
            $0.contains("integrity: Seasun manifest scan entries=3") &&
                $0.contains("first=renamed-remote.pak") &&
                $0.contains("md5=same-hash") &&
                $0.contains("size=1") &&
                $0.contains("repair_url=https://snowbreak-dl.amazingseasuncdn.com/6e5452634164107ee3c3cfd6efcdf55f/PC/updates/assets/same-hash")
        })
        XCTAssertTrue(integrityLogs.contains("integrity: local files were not read or repaired"))
        XCTAssertFalse(integrityLogs.contains { $0.contains("hpatchz") })
        XCTAssertFalse(integrityLogs.contains { $0.contains("Sophon") })
        XCTAssertEqual(integrityCommands.compactMap(\.virtualPatchState), [false])

        let blockedLaunchCommands = try await collect(
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
        let blockedLaunchStateTexts = blockedLaunchCommands.compactMap(\.stateText)
        let blockedLaunchLogs = blockedLaunchCommands.compactMap(\.log)

        XCTAssertTrue(blockedLaunchStateTexts.contains("Unsupported game version 2.1.0"))
        XCTAssertTrue(blockedLaunchLogs.contains("launch: CBJQ version 2.1.0 is above desktop supported 2.0.0; desktop would show unsupported-version alert and skip launch; patchOff is unavailable for this desktop channel"))
        XCTAssertFalse(blockedLaunchStateTexts.contains("Game is running (simulation)"))
        XCTAssertFalse(blockedLaunchLogs.contains { $0.contains("dependency: Jadeite") })
        XCTAssertFalse(blockedLaunchLogs.contains { $0.contains("launch command preview") })

        let stalePatchOffLaunchCommands = try await collect(
            service.makeProgram(
                action: .launch,
                client: cbjq,
                configuration: launchSnapshot(
                    reshade: true,
                    patchOff: true,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: cbjq, at: directory)
            )
        )
        let stalePatchOffStateTexts = stalePatchOffLaunchCommands.compactMap(\.stateText)
        let stalePatchOffLogs = stalePatchOffLaunchCommands.compactMap(\.log)

        XCTAssertTrue(stalePatchOffStateTexts.contains("Unsupported game version 2.1.0"))
        XCTAssertTrue(stalePatchOffLogs.contains("launch: CBJQ version 2.1.0 is above desktop supported 2.0.0; desktop would show unsupported-version alert and skip launch; patchOff is unavailable for this desktop channel"))
        XCTAssertFalse(stalePatchOffStateTexts.contains("Game is running (simulation)"))
        XCTAssertFalse(stalePatchOffLogs.contains { $0.contains("dependency: Jadeite") })
        XCTAssertFalse(stalePatchOffLogs.contains { $0.contains("launch command preview") })

        let launchLogs = try await logs(
            service.makeProgram(
                action: .launch,
                client: cbjq,
                configuration: launchSnapshot(
                    reshade: true,
                    patchOff: true,
                    wineDistro: "11.0-dxmt-signed-with-patches"
                ),
                installDirectory: directory,
                state: installedState(for: cbjq, at: directory, currentVersion: "2.0.0")
            )
        )
        XCTAssertFalse(launchLogs.contains { $0.contains("unsupported-version alert") })
        XCTAssertTrue(launchLogs.contains("dependency: Jadeite 4.1.0 metadata mirrors installed_jadeite_version; v4.1.0.zip were not downloaded"))
        XCTAssertTrue(launchLogs.contains {
            $0.contains("dependency: Media Foundation mf-install metadata has no desktop installed-version key") &&
                $0.contains("mfplat.dll") &&
                $0.contains("wmf.reg")
        })
        XCTAssertTrue(launchLogs.contains("launch: CBJQ config.bat runs Game/Binaries/Win64/Game.exe -FeatureLevelES31 -ChannelID=seasun"))
        XCTAssertTrue(launchLogs.contains("dependency: DXMT 0.80.0 metadata mirrors installed_dxmt_version; dxmt-v0.80-builtin.tar.gz, d3d10core.dll, d3d11.dll, dxgi.dll, winemetal.dll, winemetal.so, nvngx.dll were not downloaded"))
        XCTAssertTrue(launchLogs.contains {
            $0.contains("launch: desktop CBJQ DXMT copy plan") &&
                $0.contains("Wine prefix system32 only") &&
                $0.contains("protonextras are not used") &&
                $0.contains("not copied on iOS")
        })
        XCTAssertTrue(launchLogs.contains("launch: desktop ReShade copy plan maps ./reshade/dxgi.dll -> game dir dxgi.dll and ./reshade/d3dcompiler_47.dll -> game dir d3dcompiler_47.dll (not copied on iOS)"))
        XCTAssertTrue(launchLogs.contains("launch: WINEMSYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"))
        XCTAssertTrue(launchLogs.contains("launch: MVK_ALLOW_METAL_FENCES=1"))
        XCTAssertTrue(launchLogs.contains("launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"))
        XCTAssertTrue(launchLogs.contains("launch: would execute cmd /c config.bat for Game/Binaries/Win64/Game.exe"))
        XCTAssertTrue(launchLogs.contains("launch command preview candidates: ./wine/bin/wine64 cmd /c config.bat OR ./wine/bin/wine cmd /c config.bat for Game/Binaries/Win64/Game.exe; desktop uses the first existing loader (not probed or executed on iOS)"))
        XCTAssertTrue(launchLogs.contains("launch: desktop CBJQ DXMT revert plan restores d3d10core.dll, d3d11.dll, dxgi.dll from .bak in Wine prefix system32 only (not restored on iOS)"))
        XCTAssertTrue(launchLogs.contains("launch: desktop ReShade revert plan removes game dir dxgi.dll and d3dcompiler_47.dll (not removed on iOS)"))

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
    private func seasunManifest(
        version: String,
        projectVersion: String,
        paks: [VirtualInstallManifestMetadata.Pak]
    ) -> VirtualInstallManifestMetadata {
        VirtualInstallManifestMetadata(
            manifestVersion: version,
            projectVersion: projectVersion,
            pathOffset: "assets",
            paks: paks,
            sourceServerID: "CBJQ",
            channel: "seasun"
        )
    }

    @MainActor
    private func seasunPak(
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
