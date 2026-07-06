import Foundation
import Observation

@MainActor
@Observable
final class LauncherConfiguration {
    static let advancedSettingsUnlockEnabled = true

    var metalHud: Bool {
        didSet { saveDesktopBoolString(metalHud, forKey: Keys.metalHud) }
    }

    var retina: Bool {
        didSet { saveDesktopBoolString(retina, forKey: Keys.retina) }
    }

    var leftCmd: Bool {
        didSet { saveDesktopBoolString(leftCmd, forKey: Keys.leftCmd) }
    }

    var proxyEnabled: Bool {
        didSet { saveDesktopBoolString(proxyEnabled, forKey: Keys.proxyEnabled) }
    }

    var proxyHost: String {
        didSet { save(proxyHost, forKey: Keys.proxyHost) }
    }

    var fpsUnlock: FPSUnlockOption {
        didSet { save(fpsUnlock.rawValue, forKey: Keys.fpsUnlock) }
    }

    var uiLocale: UILocaleOption {
        didSet { save(uiLocale.rawValue, forKey: Keys.uiLocale) }
    }

    var advancedSettingsVisible: Bool {
        didSet { saveDesktopBoolString(advancedSettingsVisible, forKey: Keys.advancedSettingsVisible) }
    }

    var reshade: Bool {
        didSet { saveDesktopBoolString(reshade, forKey: Keys.reshade) }
    }

    var patchOff: Bool {
        didSet { saveDesktopBoolString(patchOff, forKey: Keys.patchOff) }
    }

    var workaround3: Bool {
        didSet { saveDesktopBoolString(workaround3, forKey: Keys.workaround3) }
    }

    var steamPatch: Bool {
        didSet { saveDesktopBoolString(steamPatch, forKey: Keys.steamPatch) }
    }

    var blockNet: Bool {
        didSet { saveDesktopBoolString(blockNet, forKey: Keys.blockNet) }
    }

    var timeoutFix: Bool {
        didSet { saveDesktopBoolString(timeoutFix, forKey: Keys.timeoutFix) }
    }

    var resolutionCustom: Bool {
        didSet { saveDesktopBoolString(resolutionCustom, forKey: Keys.resolutionCustom) }
    }

    var resolutionWidth: Int {
        didSet {
            if resolutionWidth < 1 {
                resolutionWidth = 1
            }
            save(resolutionWidth, forKey: Keys.resolutionWidth)
        }
    }

    var resolutionHeight: Int {
        didSet {
            if resolutionHeight < 1 {
                resolutionHeight = 1
            }
            save(resolutionHeight, forKey: Keys.resolutionHeight)
        }
    }

    var hk4eEnableHDR: Bool {
        didSet { saveDesktopBoolString(hk4eEnableHDR, forKey: Keys.hk4eEnableHDR) }
    }

    private(set) var wineDistro: String {
        didSet { save(wineDistro, forKey: Keys.wineDistro) }
    }

    private(set) var wineNetbiosName: String {
        didSet { save(wineNetbiosName, forKey: Keys.wineNetbiosName) }
    }

    private(set) var wineState: WineState {
        didSet { save(wineState.rawValue, forKey: Keys.wineState) }
    }

    private(set) var wineUpdateTag: String {
        didSet { saveOptionalString(wineUpdateTag, forKey: Keys.wineUpdateTag) }
    }

    private(set) var wineUpdateURL: String {
        didSet { saveOptionalString(wineUpdateURL, forKey: Keys.wineUpdateURL) }
    }

    private(set) var ignoredLauncherUpdateVersion: String {
        didSet { saveOptionalString(ignoredLauncherUpdateVersion, forKey: Keys.ignoredLauncherUpdateVersion) }
    }

    private(set) var launcherUpdateVersion: String {
        didSet { saveOptionalString(launcherUpdateVersion, forKey: Keys.launcherUpdateVersion) }
    }

    private(set) var launcherUpdateReleaseBody: String {
        didSet { saveOptionalString(launcherUpdateReleaseBody, forKey: Keys.launcherUpdateReleaseBody) }
    }

    private(set) var launcherUpdateResourceID: String {
        didSet { saveOptionalString(launcherUpdateResourceID, forKey: Keys.launcherUpdateResourceID) }
    }

    private(set) var launcherUpdateResourceAssetName: String {
        didSet { saveOptionalString(launcherUpdateResourceAssetName, forKey: Keys.launcherUpdateResourceAssetName) }
    }

    private(set) var launcherUpdateDownloadURL: String {
        didSet { saveOptionalString(launcherUpdateDownloadURL, forKey: Keys.launcherUpdateDownloadURL) }
    }

    private(set) var launcherUpdateSidecarAssetName: String {
        didSet { saveOptionalString(launcherUpdateSidecarAssetName, forKey: Keys.launcherUpdateSidecarAssetName) }
    }

    private(set) var launcherUpdateSidecarDownloadURL: String {
        didSet { saveOptionalString(launcherUpdateSidecarDownloadURL, forKey: Keys.launcherUpdateSidecarDownloadURL) }
    }

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        metalHud = Self.loadDesktopBool(defaults, forKey: Keys.metalHud)
        retina = Self.loadDesktopBool(defaults, forKey: Keys.retina)
        leftCmd = Self.loadDesktopBool(defaults, forKey: Keys.leftCmd)
        proxyEnabled = Self.loadDesktopBool(defaults, forKey: Keys.proxyEnabled)
        proxyHost = defaults.string(forKey: Keys.proxyHost) ?? "127.0.0.1:8080"
        fpsUnlock = FPSUnlockOption.option(forStoredValue: defaults.string(forKey: Keys.fpsUnlock)) ?? .disabled
        uiLocale = UILocaleOption.option(forStoredValue: defaults.string(forKey: Keys.uiLocale)) ?? .defaultOption
        advancedSettingsVisible = Self.advancedSettingsUnlockEnabled && Self.loadDesktopBool(defaults, forKey: Keys.advancedSettingsVisible)
        reshade = Self.loadDesktopBool(defaults, forKey: Keys.reshade)
        patchOff = Self.loadDesktopBool(defaults, forKey: Keys.patchOff)
        workaround3 = Self.loadDesktopBool(defaults, forKey: Keys.workaround3, defaultValue: true)
        steamPatch = Self.loadDesktopBool(defaults, forKey: Keys.steamPatch)
        blockNet = Self.loadDesktopBool(defaults, forKey: Keys.blockNet)
        timeoutFix = Self.loadDesktopBool(defaults, forKey: Keys.timeoutFix)
        resolutionCustom = Self.loadDesktopBool(defaults, forKey: Keys.resolutionCustom)
        resolutionWidth = max(1, defaults.integerOrDefault(forKey: Keys.resolutionWidth, defaultValue: 1920))
        resolutionHeight = max(1, defaults.integerOrDefault(forKey: Keys.resolutionHeight, defaultValue: 1920))
        hk4eEnableHDR = Self.loadDesktopBool(defaults, forKey: Keys.hk4eEnableHDR)
        let storedWineDistro = defaults.string(forKey: Keys.wineDistro) ?? WineDistribution.defaultID
        if WineDistribution.distribution(id: storedWineDistro) != nil {
            wineDistro = storedWineDistro
        } else {
            wineDistro = WineDistribution.defaultID
        }
        if let storedWineNetbiosName = defaults.string(forKey: Keys.wineNetbiosName) {
            wineNetbiosName = storedWineNetbiosName
        } else {
            let generatedWineNetbiosName = Self.generateWineNetbiosName()
            wineNetbiosName = generatedWineNetbiosName
            defaults.set(generatedWineNetbiosName, forKey: Keys.wineNetbiosName)
        }
        wineState = WineState(rawValue: defaults.string(forKey: Keys.wineState) ?? "") ?? .ready
        wineUpdateTag = defaults.string(forKey: Keys.wineUpdateTag) ?? ""
        wineUpdateURL = defaults.string(forKey: Keys.wineUpdateURL) ?? ""
        ignoredLauncherUpdateVersion = defaults.string(forKey: Keys.ignoredLauncherUpdateVersion) ?? ""
        launcherUpdateVersion = defaults.string(forKey: Keys.launcherUpdateVersion) ?? ""
        launcherUpdateReleaseBody = defaults.string(forKey: Keys.launcherUpdateReleaseBody) ?? ""
        launcherUpdateResourceID = defaults.string(forKey: Keys.launcherUpdateResourceID) ?? ""
        launcherUpdateResourceAssetName = defaults.string(forKey: Keys.launcherUpdateResourceAssetName) ?? ""
        launcherUpdateDownloadURL = defaults.string(forKey: Keys.launcherUpdateDownloadURL) ?? ""
        launcherUpdateSidecarAssetName = defaults.string(forKey: Keys.launcherUpdateSidecarAssetName) ?? ""
        launcherUpdateSidecarDownloadURL = defaults.string(forKey: Keys.launcherUpdateSidecarDownloadURL) ?? ""
    }

    var snapshot: LauncherConfigurationSnapshot {
        LauncherConfigurationSnapshot(
            metalHud: metalHud,
            retina: retina,
            leftCmd: leftCmd,
            proxyEnabled: proxyEnabled,
            proxyHost: proxyHost,
            fpsUnlock: fpsUnlock,
            reshade: reshade,
            patchOff: patchOff,
            workaround3: workaround3,
            steamPatch: steamPatch,
            blockNet: blockNet,
            timeoutFix: timeoutFix,
            resolutionCustom: resolutionCustom,
            resolutionWidth: resolutionWidth,
            resolutionHeight: resolutionHeight,
            hk4eEnableHDR: hk4eEnableHDR,
            wineDistro: wineDistro,
            wineNetbiosName: wineNetbiosName,
            wineState: wineState,
            wineUpdateTag: wineUpdateTag,
            wineUpdateURL: wineUpdateURL
        )
    }

    var selectedWineDistribution: WineDistribution {
        WineDistribution.distribution(id: wineDistro) ?? .defaultDistribution
    }

    var wineDistributionSelection: String {
        if wineState == .update, !wineUpdateTag.isEmpty {
            wineUpdateTag
        } else {
            wineDistro
        }
    }

    var pendingWineDistribution: WineDistribution? {
        guard wineState == .update else {
            return nil
        }

        return WineDistribution.distribution(id: wineUpdateTag)
    }

    var launcherUpdateMetadata: LauncherUpdateMetadata? {
        guard !launcherUpdateVersion.isEmpty,
              !launcherUpdateResourceID.isEmpty,
              !launcherUpdateResourceAssetName.isEmpty
        else {
            return nil
        }

        return LauncherUpdateMetadata(
            version: launcherUpdateVersion,
            releaseBody: launcherUpdateReleaseBody,
            resourceID: launcherUpdateResourceID,
            resourceAssetName: launcherUpdateResourceAssetName,
            downloadURL: launcherUpdateDownloadURL,
            sidecarAssetName: launcherUpdateSidecarAssetName.isEmpty ? nil : launcherUpdateSidecarAssetName,
            sidecarDownloadURL: launcherUpdateSidecarDownloadURL.isEmpty ? nil : launcherUpdateSidecarDownloadURL
        )
    }

    var pendingLauncherUpdateMetadata: LauncherUpdateMetadata? {
        guard let metadata = launcherUpdateMetadata,
              ignoredLauncherUpdateVersion != metadata.version
        else {
            return nil
        }

        return metadata
    }

    func requestWineDistributionUpdate(id distroID: String) {
        guard distroID != wineDistro else {
            clearPendingWineUpdate()
            return
        }

        markWineUpdatePending(for: distroID)
    }

    func completePendingWineUpdateSimulation() {
        guard wineState == .update else {
            return
        }

        let completedDistro = WineDistribution.distribution(id: wineUpdateTag)
        if let completedDistro, wineDistro != completedDistro.id {
            wineDistro = completedDistro.id
        }

        clearPendingWineUpdate()
    }

    func recordLauncherUpdateMetadata(_ metadata: LauncherUpdateMetadata) {
        launcherUpdateVersion = metadata.version
        launcherUpdateReleaseBody = metadata.releaseBody
        launcherUpdateResourceID = metadata.resourceID
        launcherUpdateResourceAssetName = metadata.resourceAssetName
        launcherUpdateDownloadURL = metadata.downloadURL
        launcherUpdateSidecarAssetName = metadata.sidecarAssetName ?? ""
        launcherUpdateSidecarDownloadURL = metadata.sidecarDownloadURL ?? ""
    }

    func clearLauncherUpdateMetadata() {
        launcherUpdateVersion = ""
        launcherUpdateReleaseBody = ""
        launcherUpdateResourceID = ""
        launcherUpdateResourceAssetName = ""
        launcherUpdateDownloadURL = ""
        launcherUpdateSidecarAssetName = ""
        launcherUpdateSidecarDownloadURL = ""
    }

    func ignoreLauncherUpdate(version: String) {
        ignoredLauncherUpdateVersion = version
    }

    func clearIgnoredLauncherUpdate() {
        ignoredLauncherUpdateVersion = ""
    }

    private func markWineUpdatePending(for distroID: String) {
        guard let distribution = WineDistribution.distribution(id: distroID) else {
            clearPendingWineUpdate()
            return
        }

        wineState = .update
        wineUpdateTag = distribution.id
        wineUpdateURL = distribution.remoteURL
    }

    private func clearPendingWineUpdate() {
        wineState = .ready
        wineUpdateTag = ""
        wineUpdateURL = ""
    }

    private func save(_ value: Int, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private func save(_ value: String, forKey key: String) {
        defaults.set(value, forKey: key)
    }

    private func saveOptionalString(_ value: String, forKey key: String) {
        if value.isEmpty {
            defaults.removeObject(forKey: key)
        } else {
            defaults.set(value, forKey: key)
        }
    }

    private func saveDesktopBoolString(_ value: Bool, forKey key: String) {
        defaults.set(value ? "true" : "false", forKey: key)
    }

    private static func loadDesktopBool(_ defaults: UserDefaults, forKey key: String) -> Bool {
        if let storedString = defaults.object(forKey: key) as? String {
            return storedString == "true"
        }

        if let storedBool = defaults.object(forKey: key) as? Bool {
            return storedBool
        }

        return false
    }

    private static func loadDesktopBool(
        _ defaults: UserDefaults,
        forKey key: String,
        defaultValue: Bool
    ) -> Bool {
        guard defaults.object(forKey: key) != nil else {
            return defaultValue
        }

        return loadDesktopBool(defaults, forKey: key)
    }

    private static func generateWineNetbiosName() -> String {
        let characters = Array("ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        let suffix = (0..<7).map { _ in
            String(characters[Int.random(in: characters.indices)])
        }.joined()

        return "DESKTOP-\(suffix)"
    }
}

private enum Keys {
    static let metalHud = "config_metalHud"
    static let retina = "config_retina"
    static let leftCmd = "left_cmd"
    static let proxyEnabled = "config_proxyEnabled"
    static let proxyHost = "config_proxyHost"
    static let fpsUnlock = "config_fps_unlock"
    static let uiLocale = "config_uiLocale"
    static let advancedSettingsVisible = "config_advanced"
    static let reshade = "config_reshade"
    static let patchOff = "config_patch_off"
    static let workaround3 = "config_workaround3"
    static let steamPatch = "config_steam_patch"
    static let blockNet = "config_block_net"
    static let timeoutFix = "config_timeout_fix"
    static let resolutionCustom = "config_resolution_custom"
    static let resolutionWidth = "config_resolution_width"
    static let resolutionHeight = "config_resolution_height"
    static let hk4eEnableHDR = "config_hk4e_enable_hdr"
    static let wineDistro = "wine_tag"
    static let wineNetbiosName = "wine_netbiosname"
    static let wineState = "wine_state"
    static let wineUpdateTag = "wine_update_tag"
    static let wineUpdateURL = "wine_update_url"
    static let ignoredLauncherUpdateVersion = "ignore_launcher_update"
    static let launcherUpdateVersion = "launcher_update_version"
    static let launcherUpdateReleaseBody = "launcher_update_body"
    static let launcherUpdateResourceID = "launcher_update_resource_id"
    static let launcherUpdateResourceAssetName = "launcher_update_resource_asset"
    static let launcherUpdateDownloadURL = "launcher_update_download_url"
    static let launcherUpdateSidecarAssetName = "launcher_update_sidecar_asset"
    static let launcherUpdateSidecarDownloadURL = "launcher_update_sidecar_download_url"
}
