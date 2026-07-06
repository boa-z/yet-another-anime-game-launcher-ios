import Foundation

struct LauncherConfigurationSnapshot: Sendable {
    let metalHud: Bool
    let retina: Bool
    let leftCmd: Bool
    let proxyEnabled: Bool
    let proxyHost: String
    let fpsUnlock: FPSUnlockOption
    let reshade: Bool
    let patchOff: Bool
    let workaround3: Bool
    let steamPatch: Bool
    let blockNet: Bool
    let timeoutFix: Bool
    let resolutionCustom: Bool
    let resolutionWidth: Int
    let resolutionHeight: Int
    let hk4eEnableHDR: Bool
    let wineDistro: String
}
