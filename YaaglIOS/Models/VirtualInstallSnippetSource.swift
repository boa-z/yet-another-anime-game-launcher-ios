import Foundation

enum VirtualInstallSnippetSource: String, Equatable, Sendable {
    case configINI = "config.ini"
    case packageVersion = "pkg_version"
    case manifestJSON = "manifest JSON"
    case hk4eDesktopProbe = "HK4E pkg_version + Unity metadata"
    case hkrpgDesktopProbe = "HKRPG GameAssembly.dll + data.unity3d"
    case napDesktopProbe = "NAP pkg_version + Unity metadata"
    case bh3DesktopProbe = "BH3 pkg_version + Unity metadata"
}
