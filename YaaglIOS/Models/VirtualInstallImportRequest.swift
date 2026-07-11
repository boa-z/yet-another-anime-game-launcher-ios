import Foundation

struct VirtualInstallImportRequest: Equatable, Sendable {
    let path: String
    let clientID: String
    let serverID: String
    let source: VirtualInstallSnippetSource
    let probeResult: VirtualInstallProbeResult
}
