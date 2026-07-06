import Foundation

enum VirtualInstallSnippetSource: String, Equatable, Sendable {
    case configINI = "config.ini"
    case packageVersion = "pkg_version"
    case manifestJSON = "manifest JSON"
}
