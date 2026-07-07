import Foundation

enum VirtualInstallProbeResult: Equatable, Sendable {
    case newTarget
    case existing(
        version: String,
        metadata: VirtualInstallMetadata? = nil,
        manifestMetadata: VirtualInstallManifestMetadata? = nil
    )
    case unreadable
}
