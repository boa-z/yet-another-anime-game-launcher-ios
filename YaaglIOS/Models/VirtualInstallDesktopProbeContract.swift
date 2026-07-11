import Foundation

struct VirtualInstallDesktopProbeContract: Equatable, Sendable {
    let markerPath: String
    let versionPath: String
    let auxiliaryPaths: [String]
    let versionStrategy: String
    let source: VirtualInstallSnippetSource
}

extension GameClientDescriptor {
    var virtualInstallDesktopProbeContract: VirtualInstallDesktopProbeContract? {
        switch gameType {
        case "hk4e":
            VirtualInstallDesktopProbeContract(
                markerPath: "pkg_version",
                versionPath: "\(dataDirectory)/globalgamemanagers",
                auxiliaryPaths: [],
                versionStrategy: "unity-globalgamemanagers-0xac-fallback-0x88",
                source: .hk4eDesktopProbe
            )
        case "hkrpg":
            VirtualInstallDesktopProbeContract(
                markerPath: "GameAssembly.dll",
                versionPath: "\(dataDirectory)/data.unity3d",
                auxiliaryPaths: [],
                versionStrategy: "unity-data.unity3d-2019",
                source: .hkrpgDesktopProbe
            )
        case "nap":
            VirtualInstallDesktopProbeContract(
                markerPath: "pkg_version",
                versionPath: "\(dataDirectory)/globalgamemanagers",
                auxiliaryPaths: ["\(dataDirectory)/resources.assets"],
                versionStrategy: "unity-globalgamemanagers-0xc4-with-resources-md5-override",
                source: .napDesktopProbe
            )
        case "bh3":
            VirtualInstallDesktopProbeContract(
                markerPath: "pkg_version",
                versionPath: "\(dataDirectory)/globalgamemanagers",
                auxiliaryPaths: [],
                versionStrategy: "unity-globalgamemanagers-0x88",
                source: .bh3DesktopProbe
            )
        default:
            nil
        }
    }
}

extension VirtualInstallSnippetSource {
    func supportsExistingImport(for client: GameClientDescriptor) -> Bool {
        if client.gameType == "cbjq" {
            return self == .manifestJSON
        }
        return self == client.virtualInstallDesktopProbeContract?.source
    }
}
