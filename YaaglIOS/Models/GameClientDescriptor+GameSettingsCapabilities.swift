import Foundation

extension GameClientDescriptor {
    var gameSettingsCapabilities: GameSettingsCapabilities {
        switch gameType {
        case "hk4e":
            .hk4e
        case "nap":
            .nap
        case "hkrpg":
            .hkrpg
        default:
            .none
        }
    }
}
