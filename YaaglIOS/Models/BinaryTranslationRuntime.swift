import Foundation

struct BinaryTranslationRuntime: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let sourceArchitecture: String
    let hostArchitecture: String
    let referenceURL: String
    let strategy: String
    let safetyNote: String

    var settingsSummary: String {
        "\(sourceArchitecture) -> \(hostArchitecture)"
    }

    var launchLog: String {
        "launch: \(displayName) reference models \(settingsSummary) via \(strategy); \(safetyNote)"
    }

    static let box64Reference = BinaryTranslationRuntime(
        id: "box64-reference",
        displayName: "Box64-style translation",
        sourceArchitecture: "x86_64",
        hostArchitecture: "ARM64",
        referenceURL: "https://github.com/ptitSeb/box64",
        strategy: "userspace emulation, DynaRec, and native library bridge concepts",
        safetyNote: "no emulator binary, JIT, or translated process is bundled or executed on iOS"
    )
}
