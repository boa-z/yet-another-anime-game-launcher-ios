import Foundation

struct VirtualInstallSnippetProbeResult: Equatable, Sendable {
    var probeResult: VirtualInstallProbeResult
    var source: VirtualInstallSnippetSource?
    var message: String

    var detectedVersion: String? {
        switch probeResult {
        case .existing(let version, _, _):
            version
        case .newTarget, .unreadable:
            nil
        }
    }
}
