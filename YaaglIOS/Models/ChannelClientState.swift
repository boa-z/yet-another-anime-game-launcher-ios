import Foundation

struct ChannelClientState: Equatable, Sendable {
    var installState: InstallState
    var installDirectory: String
    var currentVersion: String
    var predownloadedAll: Bool

    static let empty = ChannelClientState(
        installState: .notInstalled,
        installDirectory: "",
        currentVersion: "0.0.0",
        predownloadedAll: false
    )
}
