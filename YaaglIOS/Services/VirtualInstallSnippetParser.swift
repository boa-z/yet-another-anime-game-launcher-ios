import Foundation

struct VirtualInstallSnippetParser: Sendable {
    static let maximumSnippetBytes = 64 * 1024
    static let maximumPackageVersionLines = 128
    static let maximumLineBytes = 8 * 1024

    func parse(
        _ snippet: String,
        for client: GameClientDescriptor
    ) -> VirtualInstallSnippetProbeResult {
        let trimmedSnippet = snippet.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedSnippet.isEmpty else {
            return unreadable("Paste a small config.ini, pkg_version, or manifest JSON snippet")
        }

        guard trimmedSnippet.utf8.count <= Self.maximumSnippetBytes else {
            return unreadable("Snippet is over 64 KB")
        }

        if looksLikeConfigINI(trimmedSnippet) {
            return parseConfigINI(trimmedSnippet, for: client)
        }

        if let manifestResult = parseManifestJSON(trimmedSnippet, for: client) {
            return manifestResult
        }

        if looksLikePackageVersion(trimmedSnippet) {
            return parsePackageVersion(trimmedSnippet, for: client)
        }

        return unreadable("No supported game version metadata found")
    }

    private func parseConfigINI(
        _ snippet: String,
        for client: GameClientDescriptor
    ) -> VirtualInstallSnippetProbeResult {
        let fields = keyValueFields(in: snippet)
        let versions = fields["game_version", default: []].compactMap(normalizedVersion)
        guard versions.count == 1, let version = versions.first else {
            return unreadable("config.ini must contain exactly one game_version", source: .configINI)
        }

        let channelID = fields["channel", default: []].last.flatMap(Int.init) ?? client.server.channelID
        let subchannelID = fields["sub_channel", default: []].last.flatMap(Int.init) ?? client.server.subchannelID
        let cpsReference = fields["cps", default: []].last.map(normalizedCPSReference) ?? client.server.cpsReference
        let metadata = VirtualInstallMetadata(
            gameVersion: version,
            channelID: channelID,
            subchannelID: subchannelID,
            cpsReference: cpsReference,
            sourceServerID: client.serverID
        )

        return detected(version, metadata: metadata, source: .configINI)
    }

    private func parsePackageVersion(
        _ snippet: String,
        for client: GameClientDescriptor
    ) -> VirtualInstallSnippetProbeResult {
        let lines = snippet.split(whereSeparator: \.isNewline)
            .map { String($0).trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        guard lines.count <= Self.maximumPackageVersionLines else {
            return unreadable("pkg_version snippet has too many lines", source: .packageVersion)
        }

        var versions: [String] = []
        for line in lines {
            guard line.utf8.count <= Self.maximumLineBytes else {
                return unreadable("pkg_version line is over 8 KB", source: .packageVersion)
            }

            if let object = jsonObject(from: line) as? [String: Any] {
                versions.append(contentsOf: versionValues(in: object))
            } else if let value = keyValueFields(in: line)["version", default: []].last
                        ?? keyValueFields(in: line)["game_version", default: []].last {
                if let version = normalizedVersion(value) {
                    versions.append(version)
                }
            }
        }

        guard let version = mostConservativeVersion(from: versions) else {
            return unreadable("pkg_version snippet did not include a game version", source: .packageVersion)
        }

        return detected(version, metadata: VirtualInstallMetadata(client: client, gameVersion: version), source: .packageVersion)
    }

    private func parseManifestJSON(
        _ snippet: String,
        for client: GameClientDescriptor
    ) -> VirtualInstallSnippetProbeResult? {
        guard let object = jsonObject(from: snippet) as? [String: Any] else {
            return nil
        }

        let versionKeyPaths = [
            ["projectVersion"],
            ["data", "game", "latest", "version"],
            ["data", "game", "major", "version"],
            ["data", "main", "major", "version"],
            ["game", "latest", "version"],
            ["game", "major", "version"],
            ["main", "major", "version"],
            ["data", "tag"],
            ["tag"]
        ]

        for keyPath in versionKeyPaths {
            if let rawVersion = stringValue(at: keyPath, in: object),
               let version = normalizedVersion(rawVersion) {
                return detected(version, metadata: VirtualInstallMetadata(client: client, gameVersion: version), source: .manifestJSON)
            }
        }

        if looksLikePackageVersionObject(object) {
            return nil
        }

        if looksLikeLauncherUpdateManifest(object) {
            return unreadable("Launcher update manifests are not game metadata", source: .manifestJSON)
        }

        return unreadable("Manifest JSON did not include a supported game version", source: .manifestJSON)
    }

    private func looksLikeConfigINI(_ snippet: String) -> Bool {
        snippet.localizedCaseInsensitiveContains("[General]")
            || snippet.split(whereSeparator: \.isNewline).contains { line in
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                return trimmedLine.localizedCaseInsensitiveContains("game_version")
                    && trimmedLine.contains("=")
            }
    }

    private func looksLikePackageVersion(_ snippet: String) -> Bool {
        snippet.localizedCaseInsensitiveContains("remoteName")
            || snippet.localizedCaseInsensitiveContains("fileSize")
            || snippet.localizedCaseInsensitiveContains("pkg_version")
            || snippet.split(whereSeparator: \.isNewline).allSatisfy { line in
                line.trimmingCharacters(in: .whitespacesAndNewlines).hasPrefix("{")
            }
    }

    private func looksLikeLauncherUpdateManifest(_ object: [String: Any]) -> Bool {
        object["resourcesURL"] != nil
            || object["resourcesUrl"] != nil
            || object["resources"] != nil
            || object["applicationId"] != nil
    }

    private func looksLikePackageVersionObject(_ object: [String: Any]) -> Bool {
        object["remoteName"] != nil
            || object["fileSize"] != nil
            || object["md5"] != nil
    }

    private func keyValueFields(in snippet: String) -> [String: [String]] {
        var fields: [String: [String]] = [:]
        for line in snippet.split(whereSeparator: \.isNewline) {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmedLine.isEmpty,
                  !trimmedLine.hasPrefix("#"),
                  !trimmedLine.hasPrefix(";"),
                  !trimmedLine.hasPrefix("[")
            else {
                continue
            }

            let parts = trimmedLine.split(separator: "=", maxSplits: 1)
            guard parts.count == 2 else {
                continue
            }

            let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            let value = parts[1].trimmingCharacters(in: .whitespacesAndNewlines)
            fields[key, default: []].append(value)
        }
        return fields
    }

    private func jsonObject(from string: String) -> Any? {
        guard let data = string.data(using: .utf8) else {
            return nil
        }

        return try? JSONSerialization.jsonObject(with: data)
    }

    private func versionValues(in object: [String: Any]) -> [String] {
        [
            object["game_version"],
            object["gameVersion"],
            object["version"],
            object["projectVersion"]
        ].compactMap { $0 as? String }
            .compactMap(normalizedVersion)
    }

    private func stringValue(at keyPath: [String], in object: [String: Any]) -> String? {
        var current: Any = object
        for key in keyPath {
            guard let dictionary = current as? [String: Any],
                  let next = dictionary[key]
            else {
                return nil
            }
            current = next
        }
        return current as? String
    }

    private func normalizedVersion(_ rawValue: String) -> String? {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
            .trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
        let hasPlusSuffix = trimmedValue.hasSuffix("+")
        let coreVersion = hasPlusSuffix ? String(trimmedValue.dropLast()) : trimmedValue
        let parts = coreVersion.split(separator: ".", omittingEmptySubsequences: false)

        guard parts.count == 3,
              parts.allSatisfy(isASCIINumber)
        else {
            return nil
        }

        return hasPlusSuffix ? "\(coreVersion)+" : coreVersion
    }

    private func isASCIINumber(_ part: Substring) -> Bool {
        !part.isEmpty && part.unicodeScalars.allSatisfy { scalar in
            scalar.value >= 48 && scalar.value <= 57
        }
    }

    private func normalizedCPSReference(_ rawValue: String) -> String {
        let trimmedValue = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmedValue.hasPrefix("<"), trimmedValue.hasSuffix(">") {
            return String(trimmedValue.dropFirst().dropLast())
        }
        return trimmedValue
    }

    private func mostConservativeVersion(from versions: [String]) -> String? {
        versions.min { SemanticVersion($0) < SemanticVersion($1) }
    }

    private func detected(
        _ version: String,
        metadata: VirtualInstallMetadata,
        source: VirtualInstallSnippetSource
    ) -> VirtualInstallSnippetProbeResult {
        VirtualInstallSnippetProbeResult(
            probeResult: .existing(version: version, metadata: metadata),
            source: source,
            message: "Detected \(version) from \(source.rawValue)"
        )
    }

    private func unreadable(
        _ message: String,
        source: VirtualInstallSnippetSource? = nil
    ) -> VirtualInstallSnippetProbeResult {
        VirtualInstallSnippetProbeResult(
            probeResult: .unreadable,
            source: source,
            message: message
        )
    }
}
