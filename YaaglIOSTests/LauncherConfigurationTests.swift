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
    func testAdvancedSettingsVisibilityPersistsDesktopKey() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertFalse(configuration.advancedSettingsVisible)
        XCTAssertNil(defaults.string(forKey: "config_advanced"))

        configuration.advancedSettingsVisible = true

        XCTAssertEqual(defaults.string(forKey: "config_advanced"), "true")
        XCTAssertTrue(LauncherConfiguration(defaults: defaults).advancedSettingsVisible)

        configuration.advancedSettingsVisible = false

        XCTAssertEqual(defaults.string(forKey: "config_advanced"), "false")
        XCTAssertFalse(LauncherConfiguration(defaults: defaults).advancedSettingsVisible)
    }

    @MainActor
    func testAdvancedSettingsVisibilityLoadsLegacyBoolValue() {
        let defaults = makeDefaults()
        defaults.set(true, forKey: "config_advanced")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertTrue(configuration.advancedSettingsVisible)
    }

    @MainActor
    func testDesktopBooleanSettingsPersistStringRawValues() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.metalHud = true
        configuration.retina = true
        configuration.leftCmd = true
        configuration.proxyEnabled = true
        configuration.reshade = true
        configuration.patchOff = true
        configuration.workaround3 = false
        configuration.steamPatch = true
        configuration.blockNet = true
        configuration.timeoutFix = true
        configuration.resolutionCustom = true
        configuration.hk4eEnableHDR = true

        XCTAssertEqual(defaults.string(forKey: "config_metalHud"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_retina"), "true")
        XCTAssertEqual(defaults.string(forKey: "left_cmd"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_proxyEnabled"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_reshade"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_patch_off"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_workaround3"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_steam_patch"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_block_net"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_timeout_fix"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_resolution_custom"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_hk4e_enable_hdr"), "true")

        configuration.metalHud = false
        configuration.retina = false
        configuration.leftCmd = false
        configuration.proxyEnabled = false
        configuration.reshade = false
        configuration.patchOff = false
        configuration.workaround3 = true
        configuration.steamPatch = false
        configuration.blockNet = false
        configuration.timeoutFix = false
        configuration.resolutionCustom = false
        configuration.hk4eEnableHDR = false

        XCTAssertEqual(defaults.string(forKey: "config_metalHud"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_retina"), "false")
        XCTAssertEqual(defaults.string(forKey: "left_cmd"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_proxyEnabled"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_reshade"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_patch_off"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_workaround3"), "true")
        XCTAssertEqual(defaults.string(forKey: "config_steam_patch"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_block_net"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_timeout_fix"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_resolution_custom"), "false")
        XCTAssertEqual(defaults.string(forKey: "config_hk4e_enable_hdr"), "false")
    }

    @MainActor
    func testDesktopBooleanSettingsLoadStringAndLegacyBoolRawValues() {
        let defaults = makeDefaults()
        defaults.set("true", forKey: "config_metalHud")
        defaults.set("false", forKey: "config_retina")
        defaults.set(true, forKey: "left_cmd")
        defaults.set(false, forKey: "config_proxyEnabled")
        defaults.set("true", forKey: "config_reshade")
        defaults.set("true", forKey: "config_patch_off")
        defaults.set("false", forKey: "config_workaround3")
        defaults.set(true, forKey: "config_steam_patch")
        defaults.set("true", forKey: "config_block_net")
        defaults.set("true", forKey: "config_timeout_fix")
        defaults.set("true", forKey: "config_resolution_custom")
        defaults.set(true, forKey: "config_hk4e_enable_hdr")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertTrue(configuration.metalHud)
        XCTAssertFalse(configuration.retina)
        XCTAssertTrue(configuration.leftCmd)
        XCTAssertFalse(configuration.proxyEnabled)
        XCTAssertTrue(configuration.reshade)
        XCTAssertTrue(configuration.patchOff)
        XCTAssertFalse(configuration.workaround3)
        XCTAssertTrue(configuration.steamPatch)
        XCTAssertTrue(configuration.blockNet)
        XCTAssertTrue(configuration.timeoutFix)
        XCTAssertTrue(configuration.resolutionCustom)
        XCTAssertTrue(configuration.hk4eEnableHDR)
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

        configuration.requestWineDistributionUpdate(id: "11.8-dxmt-signed-experimental")

        XCTAssertEqual(configuration.wineDistro, WineDistribution.defaultID)
        XCTAssertNil(defaults.string(forKey: "wine_tag"))
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "update")
        XCTAssertEqual(defaults.string(forKey: "wine_update_tag"), "11.8-dxmt-signed-experimental")
        XCTAssertEqual(
            defaults.string(forKey: "wine_update_url"),
            "https://github.com/yaagl/anime-game-wine/releases/download/wine-11.8-signed/wine-devel-11.8-osx64-signed.tar.xz"
        )
        XCTAssertEqual(configuration.wineDistributionSelection, "11.8-dxmt-signed-experimental")
        XCTAssertEqual(configuration.pendingWineDistribution?.id, "11.8-dxmt-signed-experimental")
        XCTAssertEqual(configuration.snapshot.wineDistro, WineDistribution.defaultID)
        XCTAssertEqual(configuration.snapshot.wineState, .update)
        XCTAssertEqual(configuration.snapshot.wineUpdateTag, "11.8-dxmt-signed-experimental")
    }

    @MainActor
    func testSelectingCurrentWineDistributionCancelsPendingUpdate() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.requestWineDistributionUpdate(id: "11.8-dxmt-signed-experimental")
        configuration.requestWineDistributionUpdate(id: WineDistribution.defaultID)

        XCTAssertEqual(configuration.wineDistro, WineDistribution.defaultID)
        XCTAssertEqual(configuration.wineState, .ready)
        XCTAssertEqual(configuration.wineDistributionSelection, WineDistribution.defaultID)
        XCTAssertNil(configuration.pendingWineDistribution)
        XCTAssertNil(defaults.string(forKey: "wine_tag"))
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "ready")
        XCTAssertNil(defaults.string(forKey: "wine_update_tag"))
        XCTAssertNil(defaults.string(forKey: "wine_update_url"))
    }

    @MainActor
    func testCompletingPendingWineUpdateSimulationMarksReadyAndClearsDesktopKeys() {
        let defaults = makeDefaults()
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.requestWineDistributionUpdate(id: "11.8-dxmt-signed-experimental")
        configuration.completePendingWineUpdateSimulation()

        XCTAssertEqual(configuration.wineDistro, "11.8-dxmt-signed-experimental")
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
    func testUnknownStoredWineDistributionPreservesDesktopCurrentTag() {
        let defaults = makeDefaults()
        defaults.set("unknown-distro", forKey: "wine_tag")

        let configuration = LauncherConfiguration(defaults: defaults)

        XCTAssertEqual(configuration.wineDistro, "unknown-distro")
        XCTAssertEqual(configuration.wineDistributionSelection, "unknown-distro")
        XCTAssertEqual(configuration.snapshot.wineDistro, "unknown-distro")
        XCTAssertNil(configuration.currentWineDistribution)
        XCTAssertEqual(configuration.selectedWineDistribution.id, WineDistribution.defaultID)
        XCTAssertEqual(configuration.wineDistributionOptions.first?.id, "unknown-distro")
        XCTAssertEqual(configuration.wineDistributionOptions.first?.displayName, "unknown-distro")
        XCTAssertEqual(configuration.wineDistributionOptions.first?.remoteURL, "not_applicable")
        XCTAssertEqual(configuration.wineDistributionOptions.first?.renderBackend, "unknown")
    }

    @MainActor
    func testUnknownStoredWineDistributionCanQueueAndCancelKnownUpdate() {
        let defaults = makeDefaults()
        defaults.set("unknown-distro", forKey: "wine_tag")
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.requestWineDistributionUpdate(id: "11.8-dxmt-signed-experimental")

        XCTAssertEqual(configuration.wineDistro, "unknown-distro")
        XCTAssertEqual(configuration.wineState, .update)
        XCTAssertEqual(configuration.wineDistributionSelection, "11.8-dxmt-signed-experimental")
        XCTAssertEqual(defaults.string(forKey: "wine_tag"), "unknown-distro")
        XCTAssertEqual(defaults.string(forKey: "wine_update_tag"), "11.8-dxmt-signed-experimental")

        configuration.requestWineDistributionUpdate(id: "unknown-distro")

        XCTAssertEqual(configuration.wineDistro, "unknown-distro")
        XCTAssertEqual(configuration.wineState, .ready)
        XCTAssertEqual(configuration.wineDistributionSelection, "unknown-distro")
        XCTAssertEqual(defaults.string(forKey: "wine_tag"), "unknown-distro")
        XCTAssertNil(defaults.string(forKey: "wine_update_tag"))
        XCTAssertNil(defaults.string(forKey: "wine_update_url"))
    }

    @MainActor
    private func makeDefaults(suiteName: String = "LauncherConfigurationTests.\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
