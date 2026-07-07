import Foundation

nonisolated struct DependencyResource: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let installedVersionKey: String?
    let currentVersion: String
    let artifactNames: [String]
    let remoteURLs: [String]
    let desktopInstallPath: String
    let iOSAvailabilityNote: String
    let blockedOperationDescription: String

    init(
        id: String,
        displayName: String,
        installedVersionKey: String?,
        currentVersion: String,
        artifactNames: [String],
        remoteURLs: [String],
        desktopInstallPath: String,
        iOSAvailabilityNote: String,
        blockedOperationDescription: String = "were not downloaded"
    ) {
        self.id = id
        self.displayName = displayName
        self.installedVersionKey = installedVersionKey
        self.currentVersion = currentVersion
        self.artifactNames = artifactNames
        self.remoteURLs = remoteURLs
        self.desktopInstallPath = desktopInstallPath
        self.iOSAvailabilityNote = iOSAvailabilityNote
        self.blockedOperationDescription = blockedOperationDescription
    }

    var settingsSummary: String {
        if let installedVersionKey {
            "\(currentVersion) (\(installedVersionKey))"
        } else {
            "\(currentVersion) (no desktop installed-version key)"
        }
    }

    var artifactSummary: String {
        artifactNames.joined(separator: ", ")
    }

    var downloadBlockLog: String {
        if let installedVersionKey {
            "dependency: \(displayName) \(currentVersion) metadata mirrors \(installedVersionKey); \(artifactSummary) \(blockedOperationDescription)"
        } else {
            "dependency: \(displayName) \(currentVersion) metadata has no desktop installed-version key; \(artifactSummary) \(blockedOperationDescription)"
        }
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
            artifactNames: ["ReShade_Setup_5.8.0_Addon.exe", "install.exe", "install.zip", "d3dcompiler_47.dll", "ReShade64.dll", "dxgi.dll", "ReShade.ini"],
            remoteURLs: [
                "https://reshade.me/downloads/ReShade_Setup_5.8.0_Addon.exe",
                "https://lutris.net/files/tools/dll/d3dcompiler_47.dll"
            ],
            desktopInstallPath: "./reshade",
            iOSAvailabilityNote: "metadata only; installer extraction, DLL copies, and Wine path writes are disabled",
            blockedOperationDescription: "were not downloaded, extracted, copied, or written"
        ),
        DependencyResource(
            id: "media-foundation",
            displayName: "Media Foundation",
            installedVersionKey: nil,
            currentVersion: "mf-install",
            artifactNames: [
                "colorcnv.dll",
                "mf.dll",
                "mferror.dll",
                "mfplat.dll",
                "mfplay.dll",
                "mfreadwrite.dll",
                "msmpeg2adec.dll",
                "msmpeg2vdec.dll",
                "sqmapi.dll",
                "mf.reg",
                "wmf.reg"
            ],
            remoteURLs: [
                "https://github.com/Ultimator14/mf-install/raw/master/system32/{dll}.dll"
            ],
            desktopInstallPath: "Wine prefix drive_c/windows/system32",
            iOSAvailabilityNote: "metadata only; DLL downloads, registry imports, and regsvr32 calls are disabled"
        )
    ]

    static func resource(id: String) -> DependencyResource? {
        catalog.first { $0.id == id }
    }
}
