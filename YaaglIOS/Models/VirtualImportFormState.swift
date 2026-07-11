import Foundation

struct VirtualImportFormState: Equatable, Sendable {
    var importPath = ""
    var detectedVersion = ""
    var probeSnippet = ""
    var probeStatus = ""

    private var evidence: ProbeEvidence?

    var hasImportPath: Bool {
        !normalizedImportPath.isEmpty
    }

    func canParseSnippet(isBusy: Bool) -> Bool {
        !normalizedProbeSnippet.isEmpty && !isBusy
    }

    func canImportExisting(client: GameClientDescriptor, isBusy: Bool) -> Bool {
        !isBusy && existingImportRequest(client: client) != nil
    }

    mutating func reset(for client: GameClientDescriptor) {
        importPath = "iOS Sandbox/Imported/\(client.id)"
        detectedVersion = client.latestVersion
        probeSnippet = ""
        probeStatus = ""
        evidence = nil
    }

    mutating func apply(
        _ parsedSnippet: VirtualInstallSnippetProbeResult,
        client: GameClientDescriptor
    ) {
        probeStatus = parsedSnippet.message

        guard case .existing(let version, let metadata, let manifestMetadata) = parsedSnippet.probeResult,
              let source = parsedSnippet.source,
              metadata?.gameVersion == nil || metadata?.gameVersion == version,
              metadata?.sourceServerID == nil || metadata?.sourceServerID == client.serverID,
              manifestMetadata?.projectVersion == nil || manifestMetadata?.projectVersion == version,
              manifestMetadata?.sourceServerID == nil || manifestMetadata?.sourceServerID == client.serverID
        else {
            evidence = nil
            return
        }

        detectedVersion = version
        evidence = ProbeEvidence(
            clientID: client.id,
            serverID: client.serverID,
            importPath: normalizedImportPath,
            version: version,
            snippet: normalizedProbeSnippet,
            source: source,
            probeResult: parsedSnippet.probeResult
        )
    }

    mutating func reconcileEvidence(client: GameClientDescriptor) {
        guard evidence?.matches(
            clientID: client.id,
            serverID: client.serverID,
            importPath: normalizedImportPath,
            version: normalizedDetectedVersion,
            snippet: normalizedProbeSnippet
        ) == true else {
            evidence = nil
            return
        }
    }

    func existingImportRequest(client: GameClientDescriptor) -> VirtualInstallImportRequest? {
        guard hasImportPath,
              !normalizedDetectedVersion.isEmpty,
              let evidence,
              evidence.matches(
                clientID: client.id,
                serverID: client.serverID,
                importPath: normalizedImportPath,
                version: normalizedDetectedVersion,
                snippet: normalizedProbeSnippet
              )
        else {
            return nil
        }
        return VirtualInstallImportRequest(
            path: normalizedImportPath,
            clientID: client.id,
            serverID: client.serverID,
            source: evidence.source,
            probeResult: evidence.probeResult
        )
    }

    private var normalizedImportPath: String {
        importPath.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedDetectedVersion: String {
        detectedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var normalizedProbeSnippet: String {
        probeSnippet.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private extension VirtualImportFormState {
    struct ProbeEvidence: Equatable, Sendable {
        let clientID: String
        let serverID: String
        let importPath: String
        let version: String
        let snippet: String
        let source: VirtualInstallSnippetSource
        let probeResult: VirtualInstallProbeResult

        func matches(
            clientID: String,
            serverID: String,
            importPath: String,
            version: String,
            snippet: String
        ) -> Bool {
            self.clientID == clientID
                && self.serverID == serverID
                && self.importPath == importPath
                && self.version == version
                && self.snippet == snippet
        }
    }
}
