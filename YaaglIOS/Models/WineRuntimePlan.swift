import Foundation

struct WineRuntimePlan: Equatable, Sendable {
    let archiveSubpath: String?
    let normalizedRoot: String
    let loaderCandidates: [String]

    init(distribution: WineDistribution?) {
        archiveSubpath = distribution?.winePath
        normalizedRoot = "./wine"
        loaderCandidates = [
            "./wine/bin/wine64",
            "./wine/bin/wine"
        ]
    }

    var extractionLog: String {
        let source = archiveSubpath ?? "<archive root>"
        return "wine update: archive subpath \(source) would be extracted into normalized runtime root \(normalizedRoot); archive extraction and path writes are disabled on iOS"
    }

    var loaderSelectionLog: String {
        "launch: desktop Wine loader candidates \(loaderCandidates.joined(separator: " -> ")); desktop probes wine64 first and falls back to wine for newer WoW64 layouts; candidates are x86_64 targets for the Box64-style reference plan; no loader was probed on iOS"
    }

    func commandCandidates(arguments: [String]) -> [String] {
        loaderCandidates.map { loader in
            DesktopCommandBuilder.build([loader] + arguments)
        }
    }
}
