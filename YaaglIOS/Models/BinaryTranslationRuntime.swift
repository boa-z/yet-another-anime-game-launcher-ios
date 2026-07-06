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
    let dynarecControls: [String]
    let disabledCapabilities: [String]
    let safetyNote: String

    var settingsSummary: String {
        "\(sourceArchitecture) -> \(hostArchitecture)"
    }

    var stageSummary: String {
        stages.map(\.title).joined(separator: " -> ")
    }

    var sourcePathSummary: String {
        stages.map { "\($0.title)=\($0.sourcePath)" }.joined(separator: "; ")
    }

    var nativeBridgeSummary: String {
        nativeBridgeTargets.joined(separator: ", ")
    }

    var dynarecControlsSummary: String {
        dynarecControls.joined(separator: ", ")
    }

    var disabledCapabilitiesSummary: String {
        disabledCapabilities.joined(separator: ", ")
    }

    var launchLog: String {
        "launch: \(displayName) reference models \(settingsSummary) via \(strategy); stage plan: \(stageSummary); source map: \(sourcePathSummary); native bridge: \(nativeBridgeSummary); dynarec controls modeled: \(dynarecControlsSummary); disabled: \(disabledCapabilitiesSummary); \(safetyNote)"
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
                id: "elf-loader",
                title: "ELF loader",
                sourcePath: "src/elfs",
                summary: "mirror ELF header, interpreter, relocation, and binfmt entry metadata before Wine launch"
            ),
            BinaryTranslationStage(
                id: "x64-decoder",
                title: "x64 decoder",
                sourcePath: "src/emu",
                summary: "classify x86_64 opcodes and syscalls without stepping instructions"
            ),
            BinaryTranslationStage(
                id: "dynablock-planner",
                title: "DynaBlock planner",
                sourcePath: "src/dynarec",
                summary: "record block and cache policy while executable pages remain disabled"
            ),
            BinaryTranslationStage(
                id: "arm64-emitter",
                title: "ARM64 dynarec emitter",
                sourcePath: "src/dynarec/arm64",
                summary: "reference ARM64 emitter passes without generating host code"
            ),
            BinaryTranslationStage(
                id: "wrapped-libraries",
                title: "wrapped library bridge",
                sourcePath: "src/wrapped + src/librarian",
                summary: "map bridgeable native library wrappers as metadata only"
            ),
            BinaryTranslationStage(
                id: "signals-syscalls",
                title: "signal/syscall boundary",
                sourcePath: "src/os + src/emu/x64syscall.c",
                summary: "represent Linux and Wine signal/syscall handling as blocked trace points"
            )
        ],
        nativeBridgeTargets: [
            "libc",
            "libm",
            "pthread",
            "dlopen",
            "SDL/OpenGL/Vulkan wrapper concept",
            "Wine WOW64 boundary",
            "Metal/DXMT driver boundary"
        ],
        dynarecControls: [
            "BOX64_DYNAREC",
            "BOX64_DYNAREC_BIGBLOCK",
            "BOX64_DYNAREC_WAIT",
            "BOX64_DYNAREC_NOARCH",
            "BOX64_NODYNAREC",
            "BOX64_DYNACACHE"
        ],
        disabledCapabilities: [
            "runtime download",
            "binfmt registration",
            "ELF process loading",
            "executable memory/JIT",
            "DynaCache writes",
            "native wrapped library injection",
            "signal/syscall trapping",
            "translated process launch"
        ],
        safetyNote: "no emulator binary, binfmt hook, JIT cache, wrapped host library, or translated process is bundled or executed on iOS"
    )
}
