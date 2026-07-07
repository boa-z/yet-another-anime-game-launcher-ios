import Foundation

enum GameChannelClientFactory {
    static func makeDefaultClients(
        runtimeMetadataProvider: GameClientRuntimeMetadataProvider = .none
    ) -> [any GameChannelClient] {
        GameLibrary.clients(applying: runtimeMetadataProvider).map { SimulatedGameChannelClient(descriptor: $0) }
    }

    static func makeTestingClients(
        stepDurationMilliseconds: Int = 0,
        runtimeMetadataProvider: GameClientRuntimeMetadataProvider = .none
    ) -> [any GameChannelClient] {
        GameLibrary.clients(applying: runtimeMetadataProvider).map {
            SimulatedGameChannelClient(
                descriptor: $0,
                simulationService: LauncherSimulationService(stepDurationMilliseconds: stepDurationMilliseconds)
            )
        }
    }
}
