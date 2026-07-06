import Foundation

struct LauncherSimulationService: Sendable {
    let stepDurationMilliseconds: Int

    init(stepDurationMilliseconds: Int = 320) {
        self.stepDurationMilliseconds = stepDurationMilliseconds
    }

    func makeProgram(
        action: LauncherAction,
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String,
        state: ChannelClientState,
        importProbeResult: VirtualInstallProbeResult? = nil
    ) -> CommonUpdateProgram {
        let steps = steps(
            for: action,
            client: client,
            configuration: configuration,
            installDirectory: installDirectory,
            state: state,
            importProbeResult: importProbeResult
        )

        return CommonUpdateProgram { continuation in
            Task {
                for step in steps {
                    continuation.yield(.setStateText(step.message))
                    if let progress = step.progress {
                        continuation.yield(.setProgress(progress))
                    } else {
                        continuation.yield(.setUndeterminedProgress)
                    }
                    if let log = step.log {
                        continuation.yield(.appendLog(log))
                    }
                    if let virtualPatchState = step.virtualPatchState {
                        continuation.yield(.setVirtualPatchState(virtualPatchState))
                    }
                    try? await Task.sleep(for: .milliseconds(stepDurationMilliseconds))
                }
                continuation.finish()
            }
        }
    }

    private func steps(
        for action: LauncherAction,
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String,
        state: ChannelClientState,
        importProbeResult: VirtualInstallProbeResult?
    ) -> [SimulationStep] {
        switch action {
        case .install:
            [
                SimulationStep("Allocating files on disk", progress: nil),
                SimulationStep("Blocked game resource download for \(client.shortTitle)", progress: 0.18, log: "install: real Sophon download is disabled on iOS"),
                SimulationStep("Creating virtual installation record", progress: 0.54),
                SimulationStep("Saving current version \(client.latestVersion)", progress: 0.86),
                SimulationStep("Install simulation complete", progress: 1.0)
            ]
        case .importExisting:
            importExistingSteps(client: client, installDirectory: installDirectory, probeResult: importProbeResult)
        case .update:
            updateSteps(client: client, state: state)
        case .launch:
            launchSteps(client: client, configuration: configuration, installDirectory: installDirectory)
        case .predownload:
            [
                SimulationStep("Allocating files on disk", progress: nil),
                SimulationStep("Blocked pre-download payload", progress: 0.35, log: "predownload: no game archive or manifest was requested"),
                SimulationStep("Saving pre-download marker", progress: 0.78),
                SimulationStep("Pre-download simulation complete", progress: 1.0)
            ]
        case .checkIntegrity:
            [
                SimulationStep("Checking game file integrity. Completed files 0/6", progress: 0.0),
                SimulationStep("Checking game file integrity. Completed files 2/6", progress: 0.33),
                SimulationStep("Checking game file integrity. Completed files 4/6", progress: 0.66),
                SimulationStep(
                    "Blocked file repair download",
                    progress: 0.84,
                    log: "integrity: local files were not read or repaired",
                    virtualPatchState: false
                ),
                SimulationStep("Integrity simulation complete", progress: 1.0)
            ]
        case .initEnvironment:
            initEnvironmentSteps(requiresPatchRevert: state.requiresPatchRevert)
        case .checkLauncherUpdate:
            [
                SimulationStep("Checking YAAGL Updates", progress: nil),
                SimulationStep("Launcher update simulation complete", progress: 1.0, log: "launcher update: network update check is currently local-only")
            ]
        }
    }

    private func importExistingSteps(
        client: GameClientDescriptor,
        installDirectory: String,
        probeResult: VirtualInstallProbeResult?
    ) -> [SimulationStep] {
        guard let probeResult else {
            return [
                SimulationStep("Reading existing game version", progress: nil),
                SimulationStep(
                    "Could not read game version",
                    progress: 1.0,
                    log: "import: no simulated package version was provided"
                )
            ]
        }

        switch probeResult {
        case .newTarget:
            return [
                SimulationStep("Preparing new install target", progress: nil),
                SimulationStep("Blocked game resource download for \(client.shortTitle)", progress: 0.35, log: "install: real Sophon download is disabled on iOS"),
                SimulationStep("Creating virtual installation record", progress: 0.78),
                SimulationStep("Install simulation complete", progress: 1.0)
            ]
        case .unreadable:
            return [
                SimulationStep("Reading existing game version", progress: nil),
                SimulationStep(
                    "Could not read game version",
                    progress: 1.0,
                    log: "import: existing directory probe failed; virtual install record is unchanged"
                )
            ]
        case .existing(let version):
            let detectedVersion = SemanticVersion(version)
            let latestVersion = SemanticVersion(client.latestVersion)
            if detectedVersion < latestVersion && !client.updatableVersions.contains(version) {
                return [
                    SimulationStep("Reading existing game version", progress: nil),
                    SimulationStep(
                        "Unsupported game version \(version)",
                        progress: 1.0,
                        log: "import: \(version) is not in updatable versions; virtual install record is unchanged"
                    )
                ]
            }

            if detectedVersion < latestVersion {
                return [
                    SimulationStep("Reading existing game version", progress: nil),
                    SimulationStep(
                        "Importing updatable version \(version)",
                        progress: 0.72,
                        log: "import: existing package at \(installDirectory) requires update"
                    ),
                    SimulationStep("Import simulation complete", progress: 1.0)
                ]
            }

            return [
                SimulationStep("Reading existing game version", progress: nil),
                SimulationStep("Checking game file integrity. Completed files 0/6", progress: 0.18),
                SimulationStep("Checking game file integrity. Completed files 2/6", progress: 0.38),
                SimulationStep("Checking game file integrity. Completed files 4/6", progress: 0.62),
                SimulationStep(
                    "Blocked file repair download",
                    progress: 0.84,
                    log: "integrity: local files were not read or repaired"
                ),
                SimulationStep("Import simulation complete", progress: 1.0)
            ]
        }
    }

    private func launchSteps(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String
    ) -> [SimulationStep] {
        let capabilities = client.gameSettingsCapabilities
        let wineDistribution = WineDistribution.distribution(id: configuration.wineDistro)
        let wineDistroLabel = wineDistribution.map { "\($0.displayName) (\($0.id))" } ?? configuration.wineDistro
        var steps = [
            SimulationStep(
                "Patching game files",
                progress: nil,
                log: patchPlanLog(configuration, capabilities: capabilities),
                virtualPatchState: true
            ),
            SimulationStep(
                "Applying launch configuration",
                progress: 0.16,
                log: "launch dir: \(installDirectory)"
            ),
            SimulationStep(
                "Applying Wine configuration",
                progress: 0.2,
                log: "launch: Wine distro \(wineDistroLabel) is simulated only"
            )
        ]

        steps.append(contentsOf: clientLaunchPlanSteps(
            client: client,
            configuration: configuration,
            capabilities: capabilities,
            wineDistribution: wineDistribution
        ))

        if capabilities.patchOff && configuration.patchOff {
            steps.append(SimulationStep("Skipping game patch", progress: 0.22, log: "launch: patchOff requested no game file patch"))
        }

        if configuration.metalHud {
            steps.append(SimulationStep("Applying Metal HUD", progress: 0.24, log: "launch: MTL_HUD_ENABLED=1"))
        }

        steps.append(SimulationStep(
            "Applying Retina mode",
            progress: 0.25,
            log: "launch: Wine Mac Driver RetinaMode=\(configuration.retina ? "y" : "n") is simulated"
        ))

        steps.append(SimulationStep(
            "Applying left CMD mapping",
            progress: 0.25,
            log: "launch: Wine Mac Driver LeftCommandIsCtrl=\(configuration.leftCmd ? "y" : "n") is simulated"
        ))

        if capabilities.hdr && configuration.hk4eEnableHDR {
            steps.append(SimulationStep("Simulating HDR registry write", progress: 0.26, log: hdrPlanLog(client: client)))
        }

        if capabilities.resolution && configuration.resolutionCustom {
            steps.append(
                SimulationStep(
                    "Applying \(configuration.resolutionWidth)x\(configuration.resolutionHeight)",
                    progress: 0.34,
                    log: resolutionPlanLog(client: client, configuration: configuration)
                )
            )
        }

        if configuration.reshade {
            steps.append(SimulationStep("Blocked ReShade dependency download", progress: 0.44, log: "launch: ReShade download is disabled"))
        }

        if configuration.proxyEnabled {
            steps.append(SimulationStep("Applying proxy \(configuration.proxyHost)", progress: 0.52, log: "launch: HTTP_PROXY=\(configuration.proxyHost); HTTPS_PROXY=\(configuration.proxyHost)"))
        }

        if capabilities.timeoutFix && configuration.timeoutFix {
            steps.append(SimulationStep("Applying timeout fix", progress: 0.56, log: "launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        }

        if capabilities.blockNet && configuration.blockNet {
            steps.append(SimulationStep("Blocked hosts file modification", progress: 0.62, log: hostsBlockPlanLog(for: client)))
        }

        steps.append(SimulationStep(
            "Preparing launch command",
            progress: 0.68,
            log: launchExecutionPlanLog(client: client, configuration: configuration, capabilities: capabilities)
        ))

        steps.append(SimulationStep("Game is running (simulation)", progress: 0.78, log: "launch: \(client.executable) was not executed"))
        steps.append(contentsOf: launchRevertPlanSteps(client: client, configuration: configuration, capabilities: capabilities))
        steps.append(contentsOf: [
            SimulationStep("Reverting patches", progress: 0.92, virtualPatchState: false),
            SimulationStep("Launch simulation complete", progress: 1.0)
        ])

        return steps
    }

    private func clientLaunchPlanSteps(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        capabilities: GameSettingsCapabilities,
        wineDistribution: WineDistribution?
    ) -> [SimulationStep] {
        var steps = [SimulationStep]()

        switch client.gameType {
        case "hk4e":
            if capabilities.steamPatch && configuration.steamPatch {
                steps.append(SimulationStep(
                    "Preparing HK4E Steam launch path",
                    progress: 0.21,
                    log: "launch: HK4E Steam path bypasses config.bat cloud flags"
                ))
            } else {
                steps.append(SimulationStep(
                    "Preparing HK4E command line",
                    progress: 0.21,
                    log: "launch: HK4E config.bat args -platform_type CLOUD_THIRD_PARTY_PC -is_cloud 1"
                ))
            }
        case "nap":
            steps.append(SimulationStep(
                "Simulating WebView registry cleanup",
                progress: 0.21,
                log: webviewCleanupPlanLog(for: client)
            ))
        case "hkrpg":
            steps.append(SimulationStep(
                "Simulating WebView registry cleanup",
                progress: 0.21,
                log: webviewCleanupPlanLog(for: client)
            ))
            steps.append(SimulationStep(
                "Preparing Jadeite launch wrapper",
                progress: 0.22,
                log: "launch: jadeite.exe wraps \(client.executable) -- -disable-gpu-skinning"
            ))
            if wineDistribution?.renderBackend == "dxmt" {
                steps.append(SimulationStep(
                    "Simulating NVIDIA extension registry",
                    progress: 0.22,
                    log: "launch: HKRPG NVIDIA extension registry writes are simulated"
                ))
            }
        case "bh3":
            steps.append(SimulationStep(
                "Preparing Jadeite launch wrapper",
                progress: 0.21,
                log: "launch: jadeite.exe wraps \(client.executable)"
            ))
            steps.append(SimulationStep(
                "Applying MoltenVK compatibility",
                progress: 0.22,
                log: "launch: MVK_ALLOW_METAL_FENCES=1"
            ))
            steps.append(SimulationStep(
                "Applying DLL overrides",
                progress: 0.23,
                log: "launch: WINEDLLOVERRIDES=d3d11,dxgi=n,b"
            ))
        default:
            break
        }

        if wineDistribution?.renderBackend == "dxmt" {
            steps.append(SimulationStep(
                "Applying DXMT environment",
                progress: 0.23,
                log: dxmtPlanLog(for: client)
            ))
        }

        return steps
    }

    private func resolutionPlanLog(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot
    ) -> String {
        switch client.gameType {
        case "hk4e":
            let key = gameRegistryKey(for: client) ?? "HK4E registry"
            return [
                "launch: HK4E resolution registry \(key)",
                "Screenmanager Is Fullscreen mode_h3981298716=dword:00000000",
                "Screenmanager Resolution Width_h182942802=dword:\(registryDword(configuration.resolutionWidth))",
                "Screenmanager Resolution Height_h2627697771=dword:\(registryDword(configuration.resolutionHeight))",
                "is simulated"
            ].joined(separator: " ")
        case "nap":
            if configuration.steamPatch {
                return "launch: NAP Steam path bypasses resolution args -screen-width \(configuration.resolutionWidth) -screen-height \(configuration.resolutionHeight) -screen-fullscreen 0"
            }
            return "launch: NAP args -screen-width \(configuration.resolutionWidth) -screen-height \(configuration.resolutionHeight) -screen-fullscreen 0"
        default:
            return "launch: custom resolution \(configuration.resolutionWidth)x\(configuration.resolutionHeight) is simulated"
        }
    }

    private func dxmtPlanLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hkrpg":
            "launch: WINEMSYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60;dxgi.customVendorId=10de;dxgi.customDeviceId=2684; DXMT_ENABLE_NVEXT=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"
        case "nap":
            "launch: WINEMSYNC=1; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"
        default:
            "launch: WINEESYNC=1; DXMT_CONFIG=d3d11.preferredMaxFrameRate=60; DXMT_CONFIG_FILE=dxmt.conf; GST_PLUGIN_FEATURE_RANK=atdec:MAX,avdec_h264:MAX"
        }
    }

    private func hdrPlanLog(client: GameClientDescriptor) -> String {
        let key = gameRegistryKey(for: client) ?? "HK4E registry"
        return "launch: HK4E HDR registry \(key) WINDOWS_HDR_ON_h3132281285=dword:00000001 is simulated"
    }

    private func webviewCleanupPlanLog(for client: GameClientDescriptor) -> String {
        let key = gameRegistryKey(for: client) ?? "\(client.shortTitle) registry"
        return "launch: \(client.gameType.uppercased()) WebView cleanup \(key) removes MIHOYOSDK_WEBVIEW_RENDER_METHOD_h1573598267 and HOYO_WEBVIEW_RENDER_METHOD_ABTEST_*"
    }

    private func hostsBlockPlanLog(for client: GameClientDescriptor) -> String {
        guard let plan = hostsBlockPlan(for: client) else {
            return "launch: hosts edit is disabled on iOS"
        }
        return "launch: hosts edit disabled on iOS; desktop would add 0.0.0.0 \(plan.host) for \(plan.durationSeconds)s"
    }

    private func launchExecutionPlanLog(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        capabilities: GameSettingsCapabilities
    ) -> String {
        if capabilities.steamPatch && configuration.steamPatch {
            return "launch: would execute C:\\windows\\system32\\steam.exe with \(client.executable)"
        }
        return "launch: would execute cmd /c config.bat for \(client.executable)"
    }

    private func launchRevertPlanSteps(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        capabilities: GameSettingsCapabilities
    ) -> [SimulationStep] {
        var steps = [SimulationStep]()

        if capabilities.hdr && configuration.hk4eEnableHDR {
            steps.append(SimulationStep(
                "Reverting HK4E HDR registry",
                progress: 0.84,
                log: "launch: HK4E HDR registry revert WINDOWS_HDR_ON_h3132281285=- is simulated"
            ))
        }

        if capabilities.resolution && configuration.resolutionCustom {
            switch client.gameType {
            case "hk4e":
                steps.append(SimulationStep(
                    "Reverting HK4E resolution registry",
                    progress: 0.86,
                    log: "launch: HK4E resolution registry revert Screenmanager Is Fullscreen mode_h3981298716, Screenmanager Resolution Width_h182942802, Screenmanager Resolution Height_h2627697771 is simulated"
                ))
            case "nap":
                steps.append(SimulationStep(
                    "Cleaning NAP Screenmanager registry",
                    progress: 0.86,
                    log: "launch: NAP Screenmanager registry cleanup is simulated"
                ))
            default:
                break
            }
        }

        return steps
    }

    private func gameRegistryKey(for client: GameClientDescriptor) -> String? {
        switch client.gameType {
        case "hk4e":
            return client.releaseType == "cn"
                ? "HKEY_CURRENT_USER\\SOFTWARE\\miHoYo\\原神"
                : "HKEY_CURRENT_USER\\SOFTWARE\\miHoYo\\Genshin Impact"
        case "nap":
            return client.releaseType == "cn"
                ? "HKEY_CURRENT_USER\\Software\\miHoYo\\绝区零"
                : "HKEY_CURRENT_USER\\Software\\miHoYo\\ZenlessZoneZero"
        case "hkrpg":
            return client.releaseType == "cn"
                ? "HKEY_CURRENT_USER\\Software\\miHoYo\\崩坏：星穹铁道"
                : "HKEY_CURRENT_USER\\Software\\Cognosphere\\Star Rail"
        default:
            return nil
        }
    }

    private func hostsBlockPlan(for client: GameClientDescriptor) -> (host: String, durationSeconds: Int)? {
        switch client.gameType {
        case "hk4e":
            let host = client.releaseType == "cn" ? "dispatchcnglobal.yuanshen.com" : "dispatchosglobal.yuanshen.com"
            return (host, 10)
        case "nap":
            let host = client.releaseType == "cn" ? "globaldp-prod-cn02.juequling.com" : "globaldp-prod-os01.zenlesszonezero.com"
            return (host, 20)
        case "hkrpg":
            let host = client.releaseType == "cn" ? "globaldp-prod-cn01.bhsr.com" : "globaldp-prod-os01.starrails.com"
            return (host, 15)
        default:
            return nil
        }
    }

    private func registryDword(_ value: Int) -> String {
        String(format: "%08x", value)
    }

    private func patchPlanLog(
        _ configuration: LauncherConfigurationSnapshot,
        capabilities: GameSettingsCapabilities
    ) -> String {
        if capabilities.patchOff && configuration.patchOff {
            "launch: game AC patch is disabled"
        } else if capabilities.workaround3 && configuration.workaround3 {
            "launch: workaround3 skips tagged patch payloads"
        } else {
            "launch: full patch payload set is simulated"
        }
    }

    private func updateSteps(client: GameClientDescriptor, state: ChannelClientState) -> [SimulationStep] {
        guard client.updatableVersions.contains(state.currentVersion) else {
            return [
                SimulationStep("Checking update compatibility", progress: nil),
                SimulationStep(
                    "Unsupported game version \(state.currentVersion)",
                    progress: 1.0,
                    log: "update: \(state.currentVersion) is not in updatable versions; virtual install record will be reset",
                    virtualPatchState: false
                )
            ]
        }

        return [
            SimulationStep("Updating", progress: nil),
            SimulationStep("Blocked incremental patch download", progress: 0.22, log: "update: xdelta/hpatchz and game package writes are disabled"),
            SimulationStep("Simulating patch application", progress: 0.58),
            SimulationStep("Clearing pre-download marker", progress: 0.82, virtualPatchState: false),
            SimulationStep("Update simulation complete", progress: 1.0)
        ]
    }

    private func initEnvironmentSteps(requiresPatchRevert: Bool) -> [SimulationStep] {
        if requiresPatchRevert {
            [
                SimulationStep("Checking pending patch state", progress: nil),
                SimulationStep(
                    "Reverting patches",
                    progress: 0.72,
                    log: "init: virtual patched marker was cleared",
                    virtualPatchState: false
                ),
                SimulationStep("Initialize simulation complete", progress: 1.0)
            ]
        } else {
            [
                SimulationStep("Checking pending patch state", progress: nil),
                SimulationStep("No Wine prefix or patch state exists on iOS", progress: 1.0, log: "init: patch revert is a no-op")
            ]
        }
    }
}

private struct SimulationStep: Sendable {
    let message: String
    let progress: Double?
    let log: String?
    let virtualPatchState: Bool?

    init(
        _ message: String,
        progress: Double?,
        log: String? = nil,
        virtualPatchState: Bool? = nil
    ) {
        self.message = message
        self.progress = progress
        self.log = log
        self.virtualPatchState = virtualPatchState
    }
}
