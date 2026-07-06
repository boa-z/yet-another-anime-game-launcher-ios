import Foundation

struct GameChannelClientContext: Sendable {
    let configuration: LauncherConfigurationSnapshot
    let installDirectory: String
    let state: ChannelClientState
    let importProbeResult: VirtualInstallProbeResult?

    init(
        configuration: LauncherConfigurationSnapshot,
        installDirectory: String,
        state: ChannelClientState,
        importProbeResult: VirtualInstallProbeResult? = nil
    ) {
        self.configuration = configuration
        self.installDirectory = installDirectory
        self.state = state
        self.importProbeResult = importProbeResult
    }
}
