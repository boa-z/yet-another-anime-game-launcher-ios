import Foundation

protocol GameChannelClient: Sendable {
    var descriptor: GameClientDescriptor { get }

    func updateRequired(in state: ChannelClientState) -> Bool
    func showPredownloadPrompt(in state: ChannelClientState) -> Bool
    func predownloadTitle(in state: ChannelClientState) -> String
    func virtualInstallDirectory() -> String
    func program(for action: LauncherAction, context: GameChannelClientContext) -> CommonUpdateProgram
    func state(after action: LauncherAction, currentState: ChannelClientState, context: GameChannelClientContext) -> ChannelClientState
}

