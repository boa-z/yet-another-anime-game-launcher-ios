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
            installSteps(client: client, installDirectory: installDirectory)
        case .importExisting:
            importExistingSteps(client: client, installDirectory: installDirectory, probeResult: importProbeResult)
        case .update:
            updateSteps(client: client, state: state)
        case .launch:
            launchSteps(client: client, configuration: configuration, installDirectory: installDirectory)
        case .predownload:
            predownloadSteps(client: client)
        case .checkIntegrity:
            checkIntegritySteps(client: client)
        case .initEnvironment:
            initEnvironmentSteps(requiresPatchRevert: state.requiresPatchRevert, configuration: configuration)
        case .checkLauncherUpdate:
            launcherUpdateSteps(client: client)
        }
    }

    private func installSteps(client: GameClientDescriptor, installDirectory: String) -> [SimulationStep] {
        [
            SimulationStep("Allocating files on disk", progress: nil, log: "install: target \(installDirectory)"),
            SimulationStep("Preparing desktop install pipeline", progress: 0.12, log: installPipelineLog(for: client)),
            SimulationStep("Blocked game resource download for \(client.shortTitle)", progress: 0.18, log: installDownloadBlockLog(for: client)),
            SimulationStep("Writing desktop metadata", progress: 0.42, log: desktopConfigMetadataLog(for: client, version: client.latestVersion, action: "install")),
            SimulationStep("Creating virtual installation record", progress: 0.62, log: "install: config.ini/package version writes are represented by UserDefaults only"),
            SimulationStep("Saving current version \(client.latestVersion)", progress: 0.86),
            SimulationStep("Install simulation complete", progress: 1.0)
        ]
    }

    private func predownloadSteps(client: GameClientDescriptor) -> [SimulationStep] {
        [
            SimulationStep("Allocating files on disk", progress: nil, log: predownloadPipelineLog(for: client)),
            SimulationStep("Blocked pre-download payload", progress: 0.35, log: "predownload: no game archive, diff, voice pack, or Sophon manifest was requested"),
            SimulationStep("Saving archive markers", progress: 0.62, log: predownloadArchiveMarkerLog(for: client)),
            SimulationStep("Saving pre-download marker", progress: 0.78, log: "predownload: predownloaded_all marker is simulated"),
            SimulationStep("Pre-download simulation complete", progress: 1.0)
        ]
    }

    private func checkIntegritySteps(client: GameClientDescriptor) -> [SimulationStep] {
        [
            SimulationStep("Checking game file integrity. Completed files 0/6", progress: 0.0, log: integrityPipelineLog(for: client)),
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
    }

    private func launcherUpdateSteps(client: GameClientDescriptor) -> [SimulationStep] {
        let resourceAssetName = LauncherUpdateMetadata.resourceAssetName(for: client.server.launcherUpdateResourceID)
        let sidecarAssetName = LauncherUpdateMetadata.sidecarAssetName(for: client.server.launcherUpdateResourceID)
        let blockedAssets = [resourceAssetName, sidecarAssetName].compactMap(\.self).joined(separator: " and ")

        return [
            SimulationStep(
                "Checking YAAGL Updates",
                progress: nil,
                log: "launcher update: GitHub latest release lookup for \(client.server.launcherUpdateResourceID) is simulated"
            ),
            SimulationStep(
                "Blocked launcher update download",
                progress: 0.58,
                log: "launcher update: \(blockedAssets) were not downloaded"
            ),
            SimulationStep(
                "Launcher update simulation complete",
                progress: 1.0,
                log: "launcher update: resources.neu was not replaced"
            )
        ]
    }

    private func installPipelineLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "install: Sophon startInstallation game_type=hk4e install_reltype=\(client.releaseType) is simulated"
        case "nap":
            "install: Aria2 segmented ZIP download to .ariatmp, concatenation, doStreamUnzip, cleanup, and config.ini write are simulated"
        case "hkrpg":
            "install: Aria2 segmented 7z download to .ariatmp, doStreamUn7z, cleanup, and config.ini write are simulated"
        case "bh3":
            "install: Aria2 game.7z download to .ariatmp, extract7z, and config.ini write are simulated"
        default:
            "install: desktop install pipeline is simulated"
        }
    }

    private func installDownloadBlockLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "install: real Sophon download is disabled on iOS"
        default:
            "install: real Aria2 game archive download is disabled on iOS"
        }
    }

    private func desktopConfigMetadataLog(
        for client: GameClientDescriptor,
        version: String,
        action: String
    ) -> String {
        let metadata = client.server
        let fields = [
            "game_version=\(version)",
            "channel=\(metadata.channelID)",
            "sub_channel=\(metadata.subchannelID)",
            "cps=\(metadata.cpsDisplayValue)"
        ].joined(separator: " ")

        switch client.gameType {
        case "hk4e":
            return "\(action): desktop server metadata \(fields) is represented without running Sophon side effects"
        case "bh3" where action == "install":
            return "\(action): desktop server metadata \(fields) is retained; BH3 config.ini rewrite is simulated on update"
        default:
            return "\(action): config.ini [General] \(fields) is simulated"
        }
    }

    private func predownloadPipelineLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "predownload: Sophon startUpdate game_type=hk4e tempdir=.tmp predownload=true is simulated"
        default:
            "predownload: Aria2 archives would download into .ariatmp and set per-archive predownload markers"
        }
    }

    private func predownloadArchiveMarkerLog(for client: GameClientDescriptor) -> String {
        let markerKeys = PredownloadArchiveMarker.markers(for: client).map(\.key)
        guard !markerKeys.isEmpty else {
            return "predownload: \(client.gameType) pipeline does not use per-archive marker keys"
        }

        return "predownload: per-archive marker keys \(markerKeys.joined(separator: ", ")) are simulated from archive basenames"
    }

    private func integrityPipelineLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "integrity: Sophon startRepair game_type=hk4e repair_mode=reliable is simulated"
        default:
            "integrity: pkg_version scan with size/md5 checks and Aria2 repair downloads is simulated"
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
                SimulationStep("Blocked game resource download for \(client.shortTitle)", progress: 0.35, log: installDownloadBlockLog(for: client)),
                SimulationStep("Writing desktop metadata", progress: 0.58, log: desktopConfigMetadataLog(for: client, version: client.latestVersion, action: "install")),
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
        case .existing(let version, let metadata):
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

            let metadataStep = metadata.map {
                SimulationStep(
                    "Representing imported desktop metadata",
                    progress: 0.9,
                    log: importedMetadataLog($0)
                )
            }

            if detectedVersion < latestVersion {
                var steps = [
                    SimulationStep("Reading existing game version", progress: nil),
                    SimulationStep(
                        "Importing updatable version \(version)",
                        progress: 0.72,
                        log: "import: existing package at \(installDirectory) requires update"
                    )
                ]
                if let metadataStep {
                    steps.append(metadataStep)
                }
                steps.append(SimulationStep("Import simulation complete", progress: 1.0))
                return steps
            }

            var steps = [
                SimulationStep("Reading existing game version", progress: nil),
                SimulationStep("Checking game file integrity. Completed files 0/6", progress: 0.18),
                SimulationStep("Checking game file integrity. Completed files 2/6", progress: 0.38),
                SimulationStep("Checking game file integrity. Completed files 4/6", progress: 0.62),
                SimulationStep(
                    "Blocked file repair download",
                    progress: 0.84,
                    log: "integrity: local files were not read or repaired"
                )
            ]
            if let metadataStep {
                steps.append(metadataStep)
            }
            steps.append(SimulationStep("Import simulation complete", progress: 1.0))
            return steps
        }
    }

    private func importedMetadataLog(_ metadata: VirtualInstallMetadata) -> String {
        let cpsDisplayValue = metadata.cpsReference.isEmpty ? "" : "<\(metadata.cpsReference)>"
        return "import: pasted metadata game_version=\(metadata.gameVersion) channel=\(metadata.channelID) sub_channel=\(metadata.subchannelID) cps=\(cpsDisplayValue) is represented without reading game files"
    }

    private func launchSteps(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String
    ) -> [SimulationStep] {
        let capabilities = client.gameSettingsCapabilities
        let wineDistribution = WineDistribution.distribution(id: configuration.wineDistro)
        let wineDistroLabel = wineDistribution.map { "\($0.displayName) (\($0.id))" } ?? configuration.wineDistro
        let translationRuntime = BinaryTranslationRuntime.box64Reference
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
            ),
            SimulationStep(
                "Planning architecture translation",
                progress: 0.2,
                log: translationRuntime.launchLog
            ),
            SimulationStep(
                "Applying Wine identity",
                progress: 0.2,
                log: "launch: wine_netbiosname=\(configuration.wineNetbiosName) is simulated"
            )
        ]

        if let removedFilesLog = removedFilesPatchPlanLog(for: client, configuration: configuration, capabilities: capabilities) {
            steps.append(SimulationStep(
                "Simulating removed-file patch plan",
                progress: 0.14,
                log: removedFilesLog
            ))
        }

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
        guard let host = client.server.blockNetHost,
              let durationSeconds = client.server.blockNetDurationSeconds
        else {
            return nil
        }

        return (host, durationSeconds)
    }

    private func registryDword(_ value: Int) -> String {
        let hex = String(value, radix: 16)
        guard hex.count < 8 else {
            return hex
        }

        return String(repeating: "0", count: 8 - hex.count) + hex
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

    private func removedFilesPatchPlanLog(
        for client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        capabilities: GameSettingsCapabilities
    ) -> String? {
        guard !(capabilities.patchOff && configuration.patchOff),
              !client.server.removedFiles.isEmpty
        else {
            return nil
        }

        return "launch: desktop removed-file patch plan moves \(client.server.removedFiles.joined(separator: ", ")) to .bak and restores them after exit"
    }

    private func updateSteps(client: GameClientDescriptor, state: ChannelClientState) -> [SimulationStep] {
        guard client.updatableVersions.contains(state.currentVersion) else {
            return [
                SimulationStep("Checking update compatibility", progress: nil),
                SimulationStep(
                    "Unsupported game version \(state.currentVersion)",
                    progress: 1.0,
                    log: "update: \(state.currentVersion) has no desktop patch target; virtual install record will be reset",
                    virtualPatchState: false
                )
            ]
        }

        return [
            SimulationStep("Updating", progress: nil, log: "update: \(state.currentVersion) -> \(client.latestVersion)"),
            SimulationStep("Preparing desktop update pipeline", progress: 0.12, log: updatePipelineLog(for: client)),
            SimulationStep("Blocked incremental patch download", progress: 0.22, log: updateDownloadBlockLog(for: client)),
            SimulationStep("Simulating patch application", progress: 0.58, log: updatePatchApplicationLog(for: client)),
            SimulationStep("Rewriting desktop metadata", progress: 0.72, log: desktopConfigMetadataLog(for: client, version: client.latestVersion, action: "update")),
            SimulationStep(
                "Clearing pre-download marker",
                progress: 0.84,
                log: updatePredownloadMarkerClearLog(for: state),
                virtualPatchState: false
            ),
            SimulationStep("Update simulation complete", progress: 1.0)
        ]
    }

    private func updatePredownloadMarkerClearLog(for state: ChannelClientState) -> String {
        guard !state.predownloadedArchiveKeys.isEmpty else {
            return "update: predownloaded_all and per-archive predownload markers would be cleared"
        }

        return "update: predownloaded_all and per-archive predownload markers would be cleared (\(state.predownloadedArchiveKeys.joined(separator: ", ")))"
    }

    private func updatePipelineLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "update: Sophon startUpdate game_type=hk4e tempdir=.tmp predownload=false is simulated"
        case "hkrpg":
            "update: Aria2 patch archive download to .ariatmp, extract7z, deletefiles.txt, hdiffmap.json, hpatchz, and audio package patches are simulated"
        case "nap":
            "update: Aria2 patch archive download to .ariatmp, doStreamUnzip, deletefiles.txt, hdifffiles.txt, hpatchz, and voice pack patches are simulated"
        case "bh3":
            "update: Aria2 patch archive download to .ariatmp, doStreamUnzip, deletefiles.txt, hdifffiles.txt, hpatchz, and voice pack patches are simulated"
        default:
            "update: desktop update pipeline is simulated"
        }
    }

    private func updateDownloadBlockLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "update: Sophon diff/chunk downloads and game package writes are disabled"
        default:
            "update: Aria2 patch archive downloads and game package writes are disabled"
        }
    }

    private func updatePatchApplicationLog(for client: GameClientDescriptor) -> String {
        switch client.gameType {
        case "hk4e":
            "update: Sophon delete_file, ldiff_download_complete, chunk_progress, and delete_ldiff_file events are simulated"
        case "hkrpg":
            "update: extract7z output, deletefiles.txt cleanup, and hdiffmap.json patch map are simulated"
        default:
            "update: unzip output, deletefiles.txt cleanup, and hdifffiles.txt patch map are simulated"
        }
    }

    private func initEnvironmentSteps(
        requiresPatchRevert: Bool,
        configuration: LauncherConfigurationSnapshot
    ) -> [SimulationStep] {
        var steps = [SimulationStep("Checking pending patch state", progress: nil)]
        let pendingWineUpdate = wineUpdatePlan(for: configuration)

        if let pendingWineUpdate {
            steps.append(contentsOf: [
                SimulationStep(
                    "Checking Wine distribution",
                    progress: 0.22,
                    log: "wine update: \(pendingWineUpdate.label) is pending installation"
                ),
                SimulationStep(
                    "Blocked Wine distribution download",
                    progress: 0.38,
                    log: "wine update: remote archive \(pendingWineUpdate.remoteURL) was not requested"
                ),
                SimulationStep(
                    "Skipping Wine install side effects",
                    progress: 0.56,
                    log: "wine update: extraction, wineboot, winecfg, hosts, certificates, and Media Foundation are disabled on iOS"
                ),
                SimulationStep(
                    "Marking Wine environment ready",
                    progress: 0.68,
                    log: "wine update: wine_state will be marked ready after simulation"
                )
            ])
        }

        if requiresPatchRevert {
            steps.append(contentsOf: [
                SimulationStep(
                    "Reverting patches",
                    progress: 0.72,
                    log: "init: virtual patched marker was cleared",
                    virtualPatchState: false
                ),
                SimulationStep("Initialize simulation complete", progress: 1.0)
            ])
            return steps
        }

        if pendingWineUpdate != nil {
            steps.append(SimulationStep("Initialize simulation complete", progress: 1.0))
            return steps
        }

        steps.append(
            SimulationStep("No Wine prefix or patch state exists on iOS", progress: 1.0, log: "init: patch revert is a no-op")
        )
        return steps
    }

    private func wineUpdatePlan(for configuration: LauncherConfigurationSnapshot) -> (label: String, remoteURL: String)? {
        guard configuration.wineState == .update else {
            return nil
        }

        let pendingID = configuration.wineUpdateTag.isEmpty ? configuration.wineDistro : configuration.wineUpdateTag
        if let distribution = WineDistribution.distribution(id: pendingID) {
            let remoteURL = configuration.wineUpdateURL.isEmpty ? distribution.remoteURL : configuration.wineUpdateURL
            return ("\(distribution.displayName) (\(distribution.id))", remoteURL)
        } else {
            let remoteURL = configuration.wineUpdateURL.isEmpty ? "unknown remote archive" : configuration.wineUpdateURL
            return ("unknown Wine distribution \(pendingID)", remoteURL)
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
