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
        installDirectory: String
    ) -> CommonUpdateProgram {
        let steps = steps(
            for: action,
            client: client,
            configuration: configuration,
            installDirectory: installDirectory
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
        installDirectory: String
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
            [
                SimulationStep("Updating", progress: nil),
                SimulationStep("Blocked incremental patch download", progress: 0.22, log: "update: xdelta/hpatchz and game package writes are disabled"),
                SimulationStep("Simulating patch application", progress: 0.58),
                SimulationStep("Clearing pre-download marker", progress: 0.82),
                SimulationStep("Update simulation complete", progress: 1.0)
            ]
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
                SimulationStep("Blocked file repair download", progress: 0.84, log: "integrity: local files were not read or repaired"),
                SimulationStep("Integrity simulation complete", progress: 1.0)
            ]
        case .initEnvironment:
            [
                SimulationStep("Checking pending patch state", progress: nil),
                SimulationStep("No Wine prefix or patch state exists on iOS", progress: 1.0, log: "init: patch revert is a no-op")
            ]
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
            SimulationStep("Patching game files", progress: nil),
            SimulationStep("Applying launch configuration", progress: 0.16, log: "launch dir: \(installDirectory)")
        ]

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

        if configuration.blockNet {
            steps.append(SimulationStep("Blocked hosts file modification", progress: 0.62, log: "launch: hosts edit is disabled on iOS"))
        }

        steps.append(contentsOf: [
            SimulationStep("Game is running (simulation)", progress: 0.78, log: "launch: \(client.executable) was not executed"),
            SimulationStep("Reverting patches", progress: 0.92),
            SimulationStep("Launch simulation complete", progress: 1.0)
        ])

        return steps
    }
}

private struct SimulationStep: Sendable {
    let message: String
    let progress: Double?
    let log: String?

    init(
        _ message: String,
        progress: Double?,
        log: String? = nil
    ) {
        self.message = message
        self.progress = progress
        self.log = log
    }
}
