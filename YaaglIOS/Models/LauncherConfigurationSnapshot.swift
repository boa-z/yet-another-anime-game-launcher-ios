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
    let wineNetbiosName: String
    let wineState: WineState
    let wineUpdateTag: String
    let wineUpdateURL: String

    init(
        metalHud: Bool,
        retina: Bool,
        leftCmd: Bool,
        proxyEnabled: Bool,
        proxyHost: String,
        fpsUnlock: FPSUnlockOption,
        reshade: Bool,
        patchOff: Bool,
        workaround3: Bool,
        steamPatch: Bool,
        blockNet: Bool,
        timeoutFix: Bool,
        resolutionCustom: Bool,
        resolutionWidth: Int,
        resolutionHeight: Int,
        hk4eEnableHDR: Bool,
        wineDistro: String,
        wineNetbiosName: String = "DESKTOP-IOS0000",
        wineState: WineState = .ready,
        wineUpdateTag: String = "",
        wineUpdateURL: String = ""
    ) {
        self.metalHud = metalHud
        self.retina = retina
        self.leftCmd = leftCmd
        self.proxyEnabled = proxyEnabled
        self.proxyHost = proxyHost
        self.fpsUnlock = fpsUnlock
        self.reshade = reshade
        self.patchOff = patchOff
        self.workaround3 = workaround3
        self.steamPatch = steamPatch
        self.blockNet = blockNet
        self.timeoutFix = timeoutFix
        self.resolutionCustom = resolutionCustom
        self.resolutionWidth = resolutionWidth
        self.resolutionHeight = resolutionHeight
        self.hk4eEnableHDR = hk4eEnableHDR
        self.wineDistro = wineDistro
        self.wineNetbiosName = wineNetbiosName
        self.wineState = wineState
        self.wineUpdateTag = wineUpdateTag
        self.wineUpdateURL = wineUpdateURL
    }
}
