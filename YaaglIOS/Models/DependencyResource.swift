import Foundation

nonisolated struct DependencyResource: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let installedVersionKey: String
    let currentVersion: String
    let artifactNames: [String]
    let remoteURLs: [String]
    let desktopInstallPath: String
    let iOSAvailabilityNote: String

    var settingsSummary: String {
        "\(currentVersion) (\(installedVersionKey))"
    }

    var artifactSummary: String {
        artifactNames.joined(separator: ", ")
    }

    var downloadBlockLog: String {
        "dependency: \(displayName) \(currentVersion) metadata mirrors \(installedVersionKey); \(artifactSummary) were not downloaded"
    }

    static let catalog: [DependencyResource] = [
        DependencyResource(
            id: "moltenvk",
            displayName: "MoltenVK",
            installedVersionKey: "installed_moltenvk_version",
            currentVersion: "1.2.2",
            artifactNames: ["libMoltenVK.dylib"],
            remoteURLs: [
                "https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/libMoltenVK.dylib"
            ],
            desktopInstallPath: "./moltenvk/libMoltenVK.dylib",
            iOSAvailabilityNote: "metadata only; dynamic library download is disabled"
        ),
        DependencyResource(
            id: "dxvk",
            displayName: "DXVK",
            installedVersionKey: "installed_dxvk_version",
            currentVersion: "1.10.4-alpha.20230402",
            artifactNames: ["d3d9.dll", "d3d10core.dll", "d3d11.dll", "dxgi.dll"],
            remoteURLs: [
                "https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/d3d9.dll",
                "https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/d3d10core.dll",
                "https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/d3d11.dll",
                "https://github.com/3Shain/winecx/releases/download/gi-wine-1.0/dxgi.dll"
            ],
            desktopInstallPath: "./dxvk",
            iOSAvailabilityNote: "metadata only; DLL downloads are disabled"
        ),
        DependencyResource(
            id: "jadeite",
            displayName: "Jadeite",
            installedVersionKey: "installed_jadeite_version",
            currentVersion: "4.1.0",
            artifactNames: ["v4.1.0.zip"],
            remoteURLs: [
                "https://codeberg.org/mkrsym1/jadeite/releases/download/v4.1.0/v4.1.0.zip"
            ],
            desktopInstallPath: "./jadeite",
            iOSAvailabilityNote: "metadata only; wrapper archive download is disabled"
        ),
        DependencyResource(
            id: "dxmt",
            displayName: "DXMT",
            installedVersionKey: "installed_dxmt_version",
            currentVersion: "0.80.0",
            artifactNames: ["dxmt-v0.80-builtin.tar.gz", "d3d10core.dll", "d3d11.dll", "dxgi.dll", "winemetal.dll", "winemetal.so", "nvngx.dll"],
            remoteURLs: [
                "https://github.com/3Shain/dxmt/releases/download/v0.80/dxmt-v0.80-builtin.tar.gz"
            ],
            desktopInstallPath: "./dxmt",
            iOSAvailabilityNote: "metadata only; archive download and extraction are disabled"
        ),
        DependencyResource(
            id: "reshade",
            displayName: "ReShade",
            installedVersionKey: "installed_reshade",
            currentVersion: "5.8.0",
            artifactNames: ["ReShade_Setup_5.8.0_Addon.exe", "d3dcompiler_47.dll", "ReShade64.dll", "ReShade.ini"],
            remoteURLs: [
                "https://reshade.me/downloads/ReShade_Setup_5.8.0_Addon.exe",
                "https://lutris.net/files/tools/dll/d3dcompiler_47.dll"
            ],
            desktopInstallPath: "./reshade",
            iOSAvailabilityNote: "metadata only; installer extraction and Wine path writes are disabled"
        )
    ]

    static func resource(id: String) -> DependencyResource? {
        catalog.first { $0.id == id }
    }
}
