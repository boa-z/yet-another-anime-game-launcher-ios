import XCTest
@testable import YaaglIOS

final class BinaryTranslationRuntimeTests: XCTestCase {
    @MainActor
    func testBox64ReferenceModelsX86ToARMWithoutBundlingRuntime() {
        let runtime = BinaryTranslationRuntime.box64Reference

        XCTAssertEqual(runtime.id, "box64-reference")
        XCTAssertEqual(runtime.referenceURL, "https://github.com/ptitSeb/box64")
        XCTAssertEqual(runtime.settingsSummary, "x86_64 -> ARM64")
        XCTAssertEqual(runtime.stages.map(\.id), ["loader", "decoder", "dispatcher", "bridge"])
        XCTAssertEqual(runtime.nativeBridgeTargets, ["libc", "pthread", "dlopen", "Metal/Wine driver boundary"])
        XCTAssertEqual(runtime.disabledCapabilities, ["runtime download", "JIT memory", "translated process launch"])
        XCTAssertTrue(runtime.stageSummary.contains("interpreter-or-dynarec dispatcher"))
        XCTAssertTrue(runtime.nativeBridgeSummary.contains("dlopen"))
        XCTAssertTrue(runtime.disabledCapabilitiesSummary.contains("JIT memory"))
        XCTAssertTrue(runtime.launchLog.contains("DynaRec"))
        XCTAssertTrue(runtime.launchLog.contains("stage plan: guest loader -> instruction decoder -> interpreter-or-dynarec dispatcher -> native library bridge"))
        XCTAssertTrue(runtime.launchLog.contains("native bridge: libc, pthread, dlopen, Metal/Wine driver boundary"))
        XCTAssertTrue(runtime.launchLog.contains("disabled: runtime download, JIT memory, translated process launch"))
        XCTAssertTrue(runtime.launchLog.contains("no emulator binary"))
    }
}
