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
        state: ChannelClientState
    ) -> CommonUpdateProgram {
        let steps = steps(
            for: action,
            client: client,
            configuration: configuration,
            installDirectory: installDirectory,
            state: state
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
        state: ChannelClientState
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

    private func launchSteps(
        client: GameClientDescriptor,
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String
    ) -> [SimulationStep] {
        var steps = [
            SimulationStep(
                "Patching game files",
                progress: nil,
                log: patchPlanLog(configuration),
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
                log: "launch: Wine distro \(configuration.wineDistro) is simulated only"
            )
        ]

        if configuration.patchOff {
            steps.append(SimulationStep("Skipping game patch", progress: 0.22, log: "launch: patchOff requested no game file patch"))
        }

        if configuration.metalHud {
            steps.append(SimulationStep("Applying Metal HUD", progress: 0.24, log: "launch: MTL_HUD_ENABLED=1"))
        }

        if configuration.hk4eEnableHDR {
            steps.append(SimulationStep("Simulating HDR registry write", progress: 0.26))
        }

        if configuration.resolutionCustom {
            steps.append(
                SimulationStep(
                    "Applying \(configuration.resolutionWidth)x\(configuration.resolutionHeight)",
                    progress: 0.34
                )
            )
        }

        if configuration.reshade {
            steps.append(SimulationStep("Blocked ReShade dependency download", progress: 0.44, log: "launch: ReShade download is disabled"))
        }

        if configuration.proxyEnabled {
            steps.append(SimulationStep("Applying proxy \(configuration.proxyHost)", progress: 0.52))
        }

        if configuration.timeoutFix {
            steps.append(SimulationStep("Applying timeout fix", progress: 0.56, log: "launch: WINE_ENABLE_TIMEOUT_FIX=1"))
        }

        if configuration.blockNet {
            steps.append(SimulationStep("Blocked hosts file modification", progress: 0.62, log: "launch: hosts edit is disabled on iOS"))
        }

        if configuration.steamPatch {
            steps.append(SimulationStep("Preparing Steam launch path", progress: 0.68, log: "launch: steam.exe path is simulated"))
        }

        steps.append(contentsOf: [
            SimulationStep("Game is running (simulation)", progress: 0.78, log: "launch: \(client.executable) was not executed"),
            SimulationStep("Reverting patches", progress: 0.92, virtualPatchState: false),
            SimulationStep("Launch simulation complete", progress: 1.0)
        ])

        return steps
    }

    private func patchPlanLog(_ configuration: LauncherConfigurationSnapshot) -> String {
        if configuration.patchOff {
            "launch: game AC patch is disabled"
        } else if configuration.workaround3 {
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
