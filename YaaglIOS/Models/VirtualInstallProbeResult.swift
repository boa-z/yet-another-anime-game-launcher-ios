import Foundation

enum VirtualInstallProbeResult: Equatable, Sendable {
    case newTarget
    case existing(version: String)
    case unreadable
}
