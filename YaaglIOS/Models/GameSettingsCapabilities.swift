import Foundation

struct GameSettingsCapabilities: Equatable, Sendable {
    let patchOff: Bool
    let workaround3: Bool
    let steamPatch: Bool
    let blockNet: Bool
    let timeoutFix: Bool
    let resolution: Bool
    let hdr: Bool

    static let hk4e = GameSettingsCapabilities(
        patchOff: true,
        workaround3: true,
        steamPatch: true,
        blockNet: true,
        timeoutFix: true,
        resolution: true,
        hdr: true
    )

    static let nap = GameSettingsCapabilities(
        patchOff: true,
        workaround3: false,
        steamPatch: true,
        blockNet: true,
        timeoutFix: true,
        resolution: true,
        hdr: false
    )

    static let hkrpg = GameSettingsCapabilities(
        patchOff: true,
        workaround3: false,
        steamPatch: false,
        blockNet: true,
        timeoutFix: false,
        resolution: false,
        hdr: false
    )

    static let cbjq = GameSettingsCapabilities(
        patchOff: true,
        workaround3: false,
        steamPatch: false,
        blockNet: false,
        timeoutFix: false,
        resolution: false,
        hdr: false
    )

    static let none = GameSettingsCapabilities(
        patchOff: false,
        workaround3: false,
        steamPatch: false,
        blockNet: false,
        timeoutFix: false,
        resolution: false,
        hdr: false
    )
}
