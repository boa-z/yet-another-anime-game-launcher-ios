import Foundation

struct ChannelClientState: Equatable, Sendable {
    var installState: InstallState
    var installDirectory: String
    var currentVersion: String
    var predownloadedAll: Bool
    var requiresPatchRevert: Bool
    var virtualInstallMetadata: VirtualInstallMetadata? = nil
    var predownloadedArchiveKeys: [String] = []

    static let empty = ChannelClientState(
        installState: .notInstalled,
        installDirectory: "",
        currentVersion: "0.0.0",
        predownloadedAll: false,
        requiresPatchRevert: false,
        virtualInstallMetadata: nil,
        predownloadedArchiveKeys: []
    )
}
