import XCTest
@testable import YaaglIOS

final class LauncherConfigurationTests: XCTestCase {
    @MainActor
    func testWorkaround3DefaultsToEnabledForAppleSimulation() {
        let configuration = LauncherConfiguration(defaults: makeDefaults())

        XCTAssertTrue(configuration.workaround3)
        XCTAssertTrue(configuration.snapshot.workaround3)
    }

    @MainActor
    func testWorkaround3PersistsToDefaults() {
        let suiteName = "LauncherConfigurationTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.workaround3 = false

        let reloadedConfiguration = LauncherConfiguration(defaults: defaults)

        XCTAssertFalse(reloadedConfiguration.workaround3)
        XCTAssertFalse(reloadedConfiguration.snapshot.workaround3)
    }

    @MainActor
    func testFPSUnlockPersistsDesktopRawValues() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(configuration.fpsUnlock, .disabled)
        XCTAssertEqual(FPSUnlockOption.disabled.rawValue, "default")
        XCTAssertEqual(FPSUnlockOption.hz120.rawValue, "120")
        XCTAssertEqual(FPSUnlockOption.hz144.rawValue, "144")

        configuration.fpsUnlock = .hz120

        XCTAssertEqual(defaults.string(forKey: "config_fps_unlock"), "120")
        XCTAssertEqual(FPSUnlockOption.hz120.title, "120Hz")
    }

    @MainActor
    func testFPSUnlockLoadsLegacyIOSValues() {
        let defaults = makeDefaults()
        defaults.set("hz144", forKey: "config_fps_unlock")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(configuration.fpsUnlock, .hz144)
    }

    @MainActor
    func testUILocalePersistsDesktopRawValues() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.uiLocale = .japanese

        XCTAssertEqual(defaults.string(forKey: "config_uiLocale"), "ja_jp")
        XCTAssertEqual(UILocaleOption.simplifiedChinese.rawValue, "zh_cn")
        XCTAssertEqual(UILocaleOption.french.rawValue, "fr_FR")
    }

    @MainActor
    func testUILocaleLoadsLegacyIOSValues() {
        let defaults = makeDefaults()
        defaults.set("simplifiedChinese", forKey: "config_uiLocale")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(configuration.uiLocale, .simplifiedChinese)
    }

    @MainActor
    func testUILocaleMapsSystemLanguageIdentifiers() {
        XCTAssertEqual(UILocaleOption.option(matchingSystemIdentifier: "zh-Hans-US"), .simplifiedChinese)
        XCTAssertEqual(UILocaleOption.option(matchingSystemIdentifier: "ja-JP"), .japanese)
        XCTAssertEqual(UILocaleOption.option(matchingSystemIdentifier: "fr-FR"), .french)
        XCTAssertNil(UILocaleOption.option(matchingSystemIdentifier: "it-IT"))
    }

    @MainActor
    func testWineDistributionDefaultsToDesktopDefaultTag() {
        let configuration = LauncherConfiguration(defaults: makeDefaults())

        XCTAssertEqual(configuration.wineDistro, WineDistribution.defaultID)
        XCTAssertEqual(configuration.selectedWineDistribution.displayName, "Wine 11.0 DXMT (signed, with patches)")
        XCTAssertEqual(configuration.wineState, .ready)
        XCTAssertNil(configuration.pendingWineDistribution)
    }

    @MainActor
    func testWineNetbiosNameIsGeneratedAndPersistedWithDesktopShape() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertTrue(configuration.wineNetbiosName.hasPrefix("DESKTOP-"))
        XCTAssertEqual(configuration.wineNetbiosName.count, 15)
        XCTAssertEqual(defaults.string(forKey: "wine_netbiosname"), configuration.wineNetbiosName)
        XCTAssertEqual(configuration.snapshot.wineNetbiosName, configuration.wineNetbiosName)

        let reloadedConfiguration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(reloadedConfiguration.wineNetbiosName, configuration.wineNetbiosName)
    }

    @MainActor
    func testWineDistributionSelectionWritesDesktopPendingUpdateKeys() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.wineDistro = "11.8-dxmt-signed-experimental"

        XCTAssertEqual(defaults.string(forKey: "wine_tag"), "11.8-dxmt-signed-experimental")
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "update")
        XCTAssertEqual(defaults.string(forKey: "wine_update_tag"), "11.8-dxmt-signed-experimental")
        XCTAssertEqual(
            defaults.string(forKey: "wine_update_url"),
            "https://github.com/yaagl/anime-game-wine/releases/download/wine-11.8-signed/wine-devel-11.8-osx64-signed.tar.xz"
        )
        XCTAssertEqual(configuration.pendingWineDistribution?.id, "11.8-dxmt-signed-experimental")
    }

    @MainActor
    func testCompletingPendingWineUpdateSimulationMarksReadyAndClearsDesktopKeys() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.wineDistro = "11.8-dxmt-signed-experimental"
        configuration.completePendingWineUpdateSimulation()

        XCTAssertEqual(configuration.wineState, .ready)
        XCTAssertNil(configuration.pendingWineDistribution)
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "ready")
        XCTAssertEqual(defaults.string(forKey: "wine_tag"), "11.8-dxmt-signed-experimental")
        XCTAssertNil(defaults.string(forKey: "wine_update_tag"))
        XCTAssertNil(defaults.string(forKey: "wine_update_url"))
    }

    @MainActor
    func testLauncherUpdateMetadataAndIgnoreVersionPersistDesktopKeys() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)
        let metadata = LauncherUpdateMetadata(
            version: "2.0.0",
            releaseBody: "Release body",
            resourceID: "napos",
            resourceAssetName: "resources_napos.neu",
            downloadURL: "https://example.test/resources_napos.neu",
            sidecarAssetName: "Yaagl.ZZZ.OS.app.tar.gz",
            sidecarDownloadURL: "https://example.test/Yaagl.ZZZ.OS.app.tar.gz"
        )

        configuration.recordLauncherUpdateMetadata(metadata)
        configuration.ignoreLauncherUpdate(version: metadata.version)

        XCTAssertEqual(defaults.string(forKey: "ignore_launcher_update"), "2.0.0")
        XCTAssertEqual(defaults.string(forKey: "launcher_update_version"), "2.0.0")
        XCTAssertEqual(defaults.string(forKey: "launcher_update_resource_id"), "napos")
        XCTAssertEqual(configuration.launcherUpdateMetadata, metadata)
        XCTAssertNil(configuration.pendingLauncherUpdateMetadata)

        let reloadedConfiguration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(reloadedConfiguration.launcherUpdateMetadata, metadata)
        XCTAssertEqual(reloadedConfiguration.ignoredLauncherUpdateVersion, "2.0.0")

        reloadedConfiguration.clearIgnoredLauncherUpdate()
        XCTAssertEqual(reloadedConfiguration.pendingLauncherUpdateMetadata, metadata)
        XCTAssertNil(defaults.string(forKey: "ignore_launcher_update"))

        reloadedConfiguration.clearLauncherUpdateMetadata()
        XCTAssertNil(reloadedConfiguration.launcherUpdateMetadata)
        XCTAssertNil(defaults.string(forKey: "launcher_update_version"))
    }

    @MainActor
    func testResolutionDefaultsMatchDesktopSettings() {
        let configuration = LauncherConfiguration(defaults: makeDefaults())

        XCTAssertFalse(configuration.resolutionCustom)
        XCTAssertEqual(configuration.resolutionWidth, 1920)
        XCTAssertEqual(configuration.resolutionHeight, 1920)
    }

    @MainActor
    func testResolutionValuesAreConstrainedToPositiveIntegers() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.resolutionWidth = 0
        configuration.resolutionHeight = -12

        XCTAssertEqual(configuration.resolutionWidth, 1)
        XCTAssertEqual(configuration.resolutionHeight, 1)
        XCTAssertEqual(defaults.integer(forKey: "config_resolution_width"), 1)
        XCTAssertEqual(defaults.integer(forKey: "config_resolution_height"), 1)
    }

    @MainActor
    func testUnknownStoredWineDistributionFallsBackToDefault() {
        let defaults = makeDefaults()
        defaults.set("unknown-distro", forKey: "wine_tag")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(configuration.wineDistro, WineDistribution.defaultID)
    }

    @MainActor
    private func makeDefaults(suiteName: String = "LauncherConfigurationTests.\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
