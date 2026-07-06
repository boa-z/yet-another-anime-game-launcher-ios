import Foundation

nonisolated struct BinaryTranslationRuntime: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let sourceArchitecture: String
    let hostArchitecture: String
    let referenceURL: String
    let strategy: String
    let stages: [BinaryTranslationStage]
    let nativeBridgeTargets: [String]
    let disabledCapabilities: [String]
    let safetyNote: String

    var settingsSummary: String {
        "\(sourceArchitecture) -> \(hostArchitecture)"
    }

    var stageSummary: String {
        stages.map(\.title).joined(separator: " -> ")
    }

    var nativeBridgeSummary: String {
        nativeBridgeTargets.joined(separator: ", ")
    }

    var disabledCapabilitiesSummary: String {
        disabledCapabilities.joined(separator: ", ")
    }

    var launchLog: String {
        "launch: \(displayName) reference models \(settingsSummary) via \(strategy); stage plan: \(stageSummary); native bridge: \(nativeBridgeSummary); disabled: \(disabledCapabilitiesSummary); \(safetyNote)"
    }

    static let box64Reference = BinaryTranslationRuntime(
        id: "box64-reference",
        displayName: "Box64-style translation",
        sourceArchitecture: "x86_64",
        hostArchitecture: "ARM64",
        referenceURL: "https://github.com/ptitSeb/box64",
        strategy: "userspace emulation, DynaRec, and native library bridge concepts",
        stages: [
            BinaryTranslationStage(
                id: "loader",
                title: "guest loader",
                summary: "model x86_64 process metadata before Wine launch"
            ),
            BinaryTranslationStage(
                id: "decoder",
                title: "instruction decoder",
                summary: "classify x86_64 blocks without compiling them"
            ),
            BinaryTranslationStage(
                id: "dispatcher",
                title: "interpreter-or-dynarec dispatcher",
                summary: "record Box64 execution choices while JIT remains disabled"
            ),
            BinaryTranslationStage(
                id: "bridge",
                title: "native library bridge",
                summary: "map bridgeable host services as metadata only"
            )
        ],
        nativeBridgeTargets: [
            "libc",
            "pthread",
            "dlopen",
            "Metal/Wine driver boundary"
        ],
        disabledCapabilities: [
            "runtime download",
            "JIT memory",
            "translated process launch"
        ],
        safetyNote: "no emulator binary, JIT, or translated process is bundled or executed on iOS"
    )
}
