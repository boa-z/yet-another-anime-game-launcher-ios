import Foundation

struct WineDistribution: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let remoteURL: String
    let renderBackend: String
    let winePath: String?

    static let defaultID = "11.0-dxmt-signed-with-patches"

    static let catalog = [
        WineDistribution(
            id: "11.0-1-crossover-signed-experimental",
            displayName: "Wine 11.0-1 Crossover (signed, experimental)",
            remoteURL: "https://github.com/yaagl/anime-game-wine/releases/download/wine-crossover-11.0-1-signed/wine-crossover-11.0-1-osx64-signed.tar.xz",
            renderBackend: "dxmt",
            winePath: "wine"
        ),
        WineDistribution(
            id: defaultID,
            displayName: "Wine 11.0 DXMT (signed, with patches)",
            remoteURL: "https://github.com/yaagl/anime-game-wine/releases/download/wine-11.0-signed/wine-devel-11.0-osx64-signed.tar.xz",
            renderBackend: "dxmt",
            winePath: "wine"
        ),
        WineDistribution(
            id: "11.8-dxmt-signed-experimental",
            displayName: "Wine 11.8 DXMT (signed, experimental)",
            remoteURL: "https://github.com/yaagl/anime-game-wine/releases/download/wine-11.8-signed/wine-devel-11.8-osx64-signed.tar.xz",
            renderBackend: "dxmt",
            winePath: "wine"
        ),
        WineDistribution(
            id: "11.4-dxmt-signed",
            displayName: "Wine 11.4 DXMT (signed)",
            remoteURL: "https://github.com/dawn-winery/dawn-signed/releases/download/wine-gcenx-11.4-osx64/wine-devel-11.4-osx64-signed.tar.xz",
            renderBackend: "dxmt",
            winePath: "wine-devel-11.4-osx64-signed/Contents/Resources/wine"
        ),
        WineDistribution(
            id: "11.0-dxmt-signed",
            displayName: "Wine 11.0 DXMT (signed)",
            remoteURL: "https://github.com/dawn-winery/dawn-signed/releases/download/wine-stable-gcenx-11.0-osx64/wine-stable-11.0-osx64-signed.tar.xz",
            renderBackend: "dxmt",
            winePath: "Wine Stable.app/Contents/Resources/wine"
        ),
        WineDistribution(
            id: "9.9-dxmt",
            displayName: "Wine 9.9 DXMT",
            remoteURL: "https://github.com/3Shain/wine/releases/download/v9.9-mingw/wine.tar.gz",
            renderBackend: "dxmt",
            winePath: nil
        ),
        WineDistribution(
            id: "unstable-bh-wine-1.1",
            displayName: "Wine unstable BH 1.1",
            remoteURL: "https://github.com/3Shain/winecx/releases/download/unstable-bh-wine-1.1/wine.tar.gz",
            renderBackend: "wine",
            winePath: nil
        ),
        WineDistribution(
            id: "unstable-bh-gptk-1.0",
            displayName: "Wine unstable BH GPTK 1.0",
            remoteURL: "https://github.com/3Shain/wine/releases/download/unstable-bh-gptk-1.0/wine.tar.gz",
            renderBackend: "gptk",
            winePath: nil
        ),
        WineDistribution(
            id: "v9.2-mingw",
            displayName: "Wine 9.2 MinGW",
            remoteURL: "https://github.com/3Shain/wine/releases/download/v9.2-mingw/wine.tar.gz",
            renderBackend: "wine",
            winePath: nil
        )
    ]

    static func distribution(id: String) -> WineDistribution? {
        catalog.first { $0.id == id }
    }

    static func selectionCatalog(currentID: String) -> [WineDistribution] {
        guard !currentID.isEmpty,
              distribution(id: currentID) == nil
        else {
            return catalog
        }

        return [unknownCurrentDistribution(id: currentID)] + catalog
    }

    static var defaultDistribution: WineDistribution {
        distribution(id: defaultID) ?? catalog[0]
    }

    private static func unknownCurrentDistribution(id: String) -> WineDistribution {
        WineDistribution(
            id: id,
            displayName: id,
            remoteURL: "not_applicable",
            renderBackend: "unknown",
            winePath: nil
        )
    }
}
