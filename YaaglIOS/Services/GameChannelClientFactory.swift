import Foundation

enum GameChannelClientFactory {
    static func makeDefaultClients() -> [any GameChannelClient] {
        GameLibrary.defaultClients.map { SimulatedGameChannelClient(descriptor: $0) }
    }

    static func makeTestingClients(stepDurationMilliseconds: Int = 0) -> [any GameChannelClient] {
        GameLibrary.defaultClients.map {
            SimulatedGameChannelClient(
                descriptor: $0,
                simulationService: LauncherSimulationService(stepDurationMilliseconds: stepDurationMilliseconds)
            )
        }
    }
}

