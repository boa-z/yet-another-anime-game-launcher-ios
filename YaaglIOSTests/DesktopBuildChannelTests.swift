import XCTest
@testable import YaaglIOS

final class DesktopBuildChannelTests: XCTestCase {
    func testCatalogMatchesDesktopBuildChannels() {
        XCTAssertEqual(
            DesktopBuildChannel.catalog.map(\.id),
            [
                "hk4ecn",
                "hk4eos",
                "hk4euniversal",
                "hkrpgcn",
                "hkrpgos",
                "bh3glb",
                "cbjq",
                "cbjqcn",
                "napos",
                "napcn"
            ]
        )
    }

    func testBundleIdentifiersAndDistributionNamesMatchDesktopBuildScript() {
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4ecn")?.bundleIdentifier, "com.3shain.yaagl")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4ecn")?.appDistributionName, "Yaagl")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4eos")?.bundleIdentifier, "com.3shain.yaagl.os")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4eos")?.appDistributionName, "Yaagl OS")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4euniversal")?.bundleIdentifier, "com.3shain.yaagl.uni")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "hk4euniversal")?.appDistributionName, "Yaagl Uni")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "cbjq")?.bundleIdentifier, "com.3shain.yaagl.scz.os")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "cbjq")?.appDistributionName, "Yaagl SCZ OS")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "napcn")?.bundleIdentifier, "com.3shain.yaagl.nap.cn")
        XCTAssertEqual(DesktopBuildChannel.channel(id: "napcn")?.appDistributionName, "Yaagl ZZZ")
    }

    func testTestBuildMetadataMatchesYAAGLTestBranch() {
        let universal = DesktopBuildChannel.channel(id: "hk4euniversal")

        XCTAssertEqual(universal?.testBundleIdentifier, "com.3shain.yaagl.uni.test")
        XCTAssertEqual(universal?.testAppDistributionName, "Yaagl Uni Test")
    }

    func testSophonBundleFlagOnlyAppliesToHK4EBuilds() {
        let sophonEnabledIDs = DesktopBuildChannel.catalog
            .filter(\.includesSophon)
            .map(\.id)

        XCTAssertEqual(sophonEnabledIDs, ["hk4ecn", "hk4eos", "hk4euniversal"])
    }

    func testUniversalChannelDocumentsRuntimeAndUpdaterRouting() {
        let universal = DesktopBuildChannel.channel(id: "hk4euniversal")

        XCTAssertEqual(universal?.runtimeRouteEnvironmentKey, "YAAGL_OVERSEA")
        XCTAssertEqual(universal?.runtimeDefaultClientID, "hk4ecn")
        XCTAssertEqual(universal?.runtimeEnabledClientID, "hk4eos")
        XCTAssertEqual(universal?.updaterRouteEnvironmentKey, "YAAGL_OS")
        XCTAssertEqual(universal?.updaterDefaultResourceID, "hk4ecn")
        XCTAssertEqual(universal?.updaterEnabledResourceID, "hk4eos")
        XCTAssertEqual(universal?.hasRuntimeRouting, true)
        XCTAssertTrue(universal?.routingSummary.contains("YAAGL_OVERSEA") == true)
        XCTAssertTrue(universal?.routingSummary.contains("hk4eos") == true)
        XCTAssertTrue(universal?.routingSummary.contains("hk4ecn") == true)
        XCTAssertTrue(universal?.routingSummary.contains("YAAGL_OS") == true)
    }

    func testNonUniversalChannelsDoNotInventRuntimeRouting() {
        let cn = DesktopBuildChannel.channel(id: "hk4ecn")

        XCTAssertEqual(cn?.hasRuntimeRouting, false)
        XCTAssertEqual(cn?.routingSummary, "no runtime channel routing")
    }
}
