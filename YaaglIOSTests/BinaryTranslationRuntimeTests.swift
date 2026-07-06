import XCTest
@testable import YaaglIOS

final class BinaryTranslationRuntimeTests: XCTestCase {
    @MainActor
    func testBox64ReferenceModelsX86ToARMWithoutBundlingRuntime() {
        let runtime = BinaryTranslationRuntime.box64Reference

        XCTAssertEqual(runtime.id, "box64-reference")
        XCTAssertEqual(runtime.referenceURL, "https://github.com/ptitSeb/box64")
        XCTAssertEqual(runtime.settingsSummary, "x86_64 -> ARM64")
        XCTAssertTrue(runtime.launchLog.contains("DynaRec"))
        XCTAssertTrue(runtime.launchLog.contains("no emulator binary"))
    }
}
