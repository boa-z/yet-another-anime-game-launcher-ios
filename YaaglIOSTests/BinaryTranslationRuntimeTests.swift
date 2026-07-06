import XCTest
@testable import YaaglIOS

final class BinaryTranslationRuntimeTests: XCTestCase {
    @MainActor
    func testBox64ReferenceModelsX86ToARMWithoutBundlingRuntime() {
        let runtime = BinaryTranslationRuntime.box64Reference

        XCTAssertEqual(runtime.id, "box64-reference")
        XCTAssertEqual(runtime.referenceURL, "https://github.com/ptitSeb/box64")
        XCTAssertEqual(runtime.settingsSummary, "x86_64 -> ARM64")
        XCTAssertEqual(runtime.stages.map(\.id), [
            "elf-loader",
            "x64-decoder",
            "dynablock-planner",
            "arm64-emitter",
            "wrapped-libraries",
            "signals-syscalls"
        ])
        XCTAssertEqual(runtime.stages.map(\.sourcePath), [
            "src/elfs",
            "src/emu",
            "src/dynarec",
            "src/dynarec/arm64",
            "src/wrapped + src/librarian",
            "src/os + src/emu/x64syscall.c"
        ])
        XCTAssertTrue(runtime.nativeBridgeTargets.contains("SDL/OpenGL/Vulkan wrapper concept"))
        XCTAssertTrue(runtime.nativeBridgeTargets.contains("Wine WOW64 boundary"))
        XCTAssertEqual(runtime.dynarecControls, [
            "BOX64_DYNAREC",
            "BOX64_DYNAREC_BIGBLOCK",
            "BOX64_DYNAREC_WAIT",
            "BOX64_DYNAREC_NOARCH",
            "BOX64_NODYNAREC",
            "BOX64_DYNACACHE"
        ])
        XCTAssertTrue(runtime.disabledCapabilities.contains("binfmt registration"))
        XCTAssertTrue(runtime.disabledCapabilities.contains("executable memory/JIT"))
        XCTAssertTrue(runtime.disabledCapabilities.contains("DynaCache writes"))
        XCTAssertTrue(runtime.disabledCapabilities.contains("native wrapped library injection"))
        XCTAssertTrue(runtime.disabledCapabilities.contains("signal/syscall trapping"))
        XCTAssertTrue(runtime.stageSummary.contains("ARM64 dynarec emitter"))
        XCTAssertTrue(runtime.sourcePathSummary.contains("src/dynarec/arm64"))
        XCTAssertTrue(runtime.nativeBridgeSummary.contains("dlopen"))
        XCTAssertTrue(runtime.dynarecControlsSummary.contains("BOX64_DYNAREC_BIGBLOCK"))
        XCTAssertTrue(runtime.disabledCapabilitiesSummary.contains("executable memory/JIT"))
        XCTAssertTrue(runtime.launchLog.contains("DynaRec"))
        XCTAssertTrue(runtime.launchLog.contains("stage plan: ELF loader -> x64 decoder -> DynaBlock planner -> ARM64 dynarec emitter -> wrapped library bridge -> signal/syscall boundary"))
        XCTAssertTrue(runtime.launchLog.contains("source map: ELF loader=src/elfs"))
        XCTAssertTrue(runtime.launchLog.contains("native bridge: libc, libm, pthread, dlopen"))
        XCTAssertTrue(runtime.launchLog.contains("dynarec controls modeled: BOX64_DYNAREC, BOX64_DYNAREC_BIGBLOCK"))
        XCTAssertTrue(runtime.launchLog.contains("disabled: runtime download, binfmt registration, ELF process loading, executable memory/JIT"))
        XCTAssertTrue(runtime.launchLog.contains("no emulator binary"))
    }
}
