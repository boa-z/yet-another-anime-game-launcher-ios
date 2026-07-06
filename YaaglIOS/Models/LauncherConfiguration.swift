import Foundation
import Observation

@MainActor
@Observable
final class LauncherConfiguration {
    var metalHud: Bool {
        didSet { save(metalHud, forKey: Keys.metalHud) }
    }

    var retina: Bool {
        didSet { save(retina, forKey: Keys.retina) }
    }

    var leftCmd: Bool {
        didSet { save(leftCmd, forKey: Keys.leftCmd) }
    }

    var proxyEnabled: Bool {
        didSet { save(proxyEnabled, forKey: Keys.proxyEnabled) }
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

    var reshade: Bool {
        didSet { save(reshade, forKey: Keys.reshade) }
    }

    var patchOff: Bool {
        didSet { save(patchOff, forKey: Keys.patchOff) }
    }

    var workaround3: Bool {
        didSet { save(workaround3, forKey: Keys.workaround3) }
    }

    var steamPatch: Bool {
        didSet { save(steamPatch, forKey: Keys.steamPatch) }
    }

    var blockNet: Bool {
        didSet { save(blockNet, forKey: Keys.blockNet) }
    }

    var timeoutFix: Bool {
        didSet { save(timeoutFix, forKey: Keys.timeoutFix) }
    }

    var resolutionCustom: Bool {
        didSet { save(resolutionCustom, forKey: Keys.resolutionCustom) }
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
        didSet { save(hk4eEnableHDR, forKey: Keys.hk4eEnableHDR) }
    }

    var wineDistro: String {
        didSet {
            save(wineDistro, forKey: Keys.wineDistro)
            guard oldValue != wineDistro else {
                return
            }

            markWineUpdatePending(for: wineDistro)
        }
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

    @ObservationIgnored private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        metalHud = defaults.bool(forKey: Keys.metalHud)
        retina = defaults.bool(forKey: Keys.retina)
        leftCmd = defaults.bool(forKey: Keys.leftCmd)
        proxyEnabled = defaults.bool(forKey: Keys.proxyEnabled)
        proxyHost = defaults.string(forKey: Keys.proxyHost) ?? "127.0.0.1:8080"
        fpsUnlock = FPSUnlockOption.option(forStoredValue: defaults.string(forKey: Keys.fpsUnlock)) ?? .disabled
        uiLocale = UILocaleOption.option(forStoredValue: defaults.string(forKey: Keys.uiLocale)) ?? .defaultOption
        reshade = defaults.bool(forKey: Keys.reshade)
        patchOff = defaults.bool(forKey: Keys.patchOff)
        workaround3 = defaults.object(forKey: Keys.workaround3) as? Bool ?? true
        steamPatch = defaults.bool(forKey: Keys.steamPatch)
        blockNet = defaults.bool(forKey: Keys.blockNet)
        timeoutFix = defaults.bool(forKey: Keys.timeoutFix)
        resolutionCustom = defaults.bool(forKey: Keys.resolutionCustom)
        resolutionWidth = max(1, defaults.integerOrDefault(forKey: Keys.resolutionWidth, defaultValue: 1920))
        resolutionHeight = max(1, defaults.integerOrDefault(forKey: Keys.resolutionHeight, defaultValue: 1920))
        hk4eEnableHDR = defaults.bool(forKey: Keys.hk4eEnableHDR)
        let storedWineDistro = defaults.string(forKey: Keys.wineDistro) ?? WineDistribution.defaultID
        if WineDistribution.distribution(id: storedWineDistro) != nil {
            wineDistro = storedWineDistro
        } else {
            wineDistro = WineDistribution.defaultID
        }
        wineState = WineState(rawValue: defaults.string(forKey: Keys.wineState) ?? "") ?? .ready
        wineUpdateTag = defaults.string(forKey: Keys.wineUpdateTag) ?? ""
        wineUpdateURL = defaults.string(forKey: Keys.wineUpdateURL) ?? ""
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
            wineDistro: wineDistro
        )
    }

    var selectedWineDistribution: WineDistribution {
        WineDistribution.distribution(id: wineDistro) ?? .defaultDistribution
    }

    var pendingWineDistribution: WineDistribution? {
        guard wineState == .update else {
            return nil
        }

        return WineDistribution.distribution(id: wineUpdateTag)
    }

    private func markWineUpdatePending(for distroID: String) {
        guard let distribution = WineDistribution.distribution(id: distroID) else {
            wineState = .ready
            wineUpdateTag = ""
            wineUpdateURL = ""
            return
        }

        wineState = .update
        wineUpdateTag = distribution.id
        wineUpdateURL = distribution.remoteURL
    }

    private func save(_ value: Bool, forKey key: String) {
        defaults.set(value, forKey: key)
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
}

private enum Keys {
    static let metalHud = "config_metalHud"
    static let retina = "config_retina"
    static let leftCmd = "left_cmd"
    static let proxyEnabled = "config_proxyEnabled"
    static let proxyHost = "config_proxyHost"
    static let fpsUnlock = "config_fps_unlock"
    static let uiLocale = "config_uiLocale"
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
    static let wineState = "wine_state"
    static let wineUpdateTag = "wine_update_tag"
    static let wineUpdateURL = "wine_update_url"
}
