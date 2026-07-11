import XCTest
@testable import YaaglIOS

final class WineRuntimePlanTests: XCTestCase {
    @MainActor
    func testLoaderCandidatesMatchDesktopFallbackOrder() {
        let plan = WineRuntimePlan(distribution: nil)

        XCTAssertEqual(
            plan.loaderCandidates,
            ["./wine/bin/wine64", "./wine/bin/wine"]
        )
        XCTAssertEqual(
            plan.commandCandidates(arguments: ["cmd", "/c", "config.bat"]),
            [
                "./wine/bin/wine64 cmd /c config.bat",
                "./wine/bin/wine cmd /c config.bat"
            ]
        )
        XCTAssertTrue(plan.loaderSelectionLog.contains("probes wine64 first and falls back to wine"))
        XCTAssertTrue(plan.loaderSelectionLog.contains("x86_64 targets for the Box64-style reference plan"))
        XCTAssertTrue(plan.loaderSelectionLog.contains("no loader was probed on iOS"))
    }

    @MainActor
    func testArchiveSubpathsNormalizeToDesktopWineRoot() throws {
        let simple = try XCTUnwrap(WineDistribution.distribution(id: WineDistribution.defaultID))
        let appBundle = try XCTUnwrap(WineDistribution.distribution(id: "11.0-dxmt-signed"))
        let archiveRoot = try XCTUnwrap(WineDistribution.distribution(id: "9.9-dxmt"))

        let simplePlan = WineRuntimePlan(distribution: simple)
        let appBundlePlan = WineRuntimePlan(distribution: appBundle)
        let archiveRootPlan = WineRuntimePlan(distribution: archiveRoot)

        XCTAssertEqual(simplePlan.archiveSubpath, "wine")
        XCTAssertEqual(simplePlan.normalizedRoot, "./wine")
        XCTAssertTrue(simplePlan.extractionLog.contains("archive subpath wine"))
        XCTAssertTrue(simplePlan.extractionLog.contains("normalized runtime root ./wine"))

        XCTAssertEqual(appBundlePlan.archiveSubpath, "Wine Stable.app/Contents/Resources/wine")
        XCTAssertTrue(appBundlePlan.extractionLog.contains("Wine Stable.app/Contents/Resources/wine"))
        XCTAssertTrue(appBundlePlan.extractionLog.contains("normalized runtime root ./wine"))

        XCTAssertNil(archiveRootPlan.archiveSubpath)
        XCTAssertTrue(archiveRootPlan.extractionLog.contains("archive subpath <archive root>"))
        XCTAssertTrue(archiveRootPlan.extractionLog.contains("normalized runtime root ./wine"))
    }
}
