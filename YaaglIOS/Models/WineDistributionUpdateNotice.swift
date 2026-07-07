import Foundation

struct WineDistributionUpdateNotice: Equatable, Sendable {
    let title: String
    let message: String

    static let relaunchRequired = WineDistributionUpdateNotice(
        title: "Launcher restart required",
        message: "Desktop YAAGL would restart to complete the Wine installation. The iOS build records the pending Wine update and completes it during the simulated environment initialization."
    )
}
