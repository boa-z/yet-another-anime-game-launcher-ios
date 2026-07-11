import Foundation

struct GameClientRuntimeMetadata: Equatable, Sendable {
    let latestVersion: String?
    let currentSupportedVersion: String?
    let updatableVersions: [String]?
    let predownloadVersion: String?
    let predownloadAvailable: Bool?
    let predownloadTargetAvailable: Bool?
    let installSize: String?
    let predownloadArchiveBasenames: [String]?
    let seasunManifestMetadata: VirtualInstallManifestMetadata?

    init(
        latestVersion: String? = nil,
        currentSupportedVersion: String? = nil,
        updatableVersions: [String]? = nil,
        predownloadVersion: String? = nil,
        predownloadAvailable: Bool? = nil,
        predownloadTargetAvailable: Bool? = nil,
        installSize: String? = nil,
        installSizeBytes: Int64? = nil,
        predownloadArchiveBasenames: [String]? = nil,
        seasunManifestMetadata: VirtualInstallManifestMetadata? = nil
    ) {
        self.latestVersion = latestVersion
        self.currentSupportedVersion = currentSupportedVersion
        self.updatableVersions = updatableVersions
        self.predownloadVersion = predownloadVersion
        self.predownloadAvailable = predownloadAvailable
        self.predownloadTargetAvailable = predownloadTargetAvailable
        self.installSize = installSize ?? installSizeBytes.map(Self.installSizeString(bytes:))
        self.predownloadArchiveBasenames = predownloadArchiveBasenames
        self.seasunManifestMetadata = seasunManifestMetadata
    }

    private static func installSizeString(bytes: Int64) -> String {
        let gibibyte: Int64 = 1_073_741_824
        let tenths = max(0, (bytes * 10 + gibibyte / 2) / gibibyte)
        let whole = tenths / 10
        let fraction = tenths % 10

        if fraction == 0 {
            return "\(whole) GiB"
        }

        return "\(whole).\(fraction) GiB"
    }
}

struct GameClientRuntimeMetadataProvider: Sendable {
    private let metadata: @Sendable (GameClientDescriptor) -> GameClientRuntimeMetadata?

    init(_ metadata: @escaping @Sendable (GameClientDescriptor) -> GameClientRuntimeMetadata?) {
        self.metadata = metadata
    }

    func metadata(for client: GameClientDescriptor) -> GameClientRuntimeMetadata? {
        metadata(client)
    }

    static let none = GameClientRuntimeMetadataProvider { _ in nil }

    static func fixture(_ values: [String: GameClientRuntimeMetadata]) -> GameClientRuntimeMetadataProvider {
        GameClientRuntimeMetadataProvider { client in
            values[client.id]
        }
    }
}

enum GameClientRuntimeMetadataParser {
    enum ParseError: Error, Equatable {
        case invalidRoot
        case missingField(String)
    }

    static func parseHK4ESophonGameInfo(_ data: Data) throws -> GameClientRuntimeMetadata {
        let root = try jsonObject(from: data)
        let predownloadAvailable = bool("pre_download", in: root) ?? false
        return GameClientRuntimeMetadata(
            latestVersion: try string("version", in: root),
            updatableVersions: try stringArray("updatable_versions", in: root),
            predownloadVersion: predownloadAvailable ? try string("pre_download_version", in: root) : nil,
            predownloadAvailable: predownloadAvailable,
            predownloadTargetAvailable: predownloadAvailable,
            installSizeBytes: try int64("install_size", in: root)
        )
    }

    static func parseHoyoVersionInfo(
        _ data: Data,
        currentVersion: String? = nil,
        installedVoiceLanguages: Set<String> = []
    ) throws -> GameClientRuntimeMetadata {
        let root = try jsonObject(from: data)
        let main = try dictionary("main", in: root)
        let major = try dictionary("major", in: main)
        let patches = array("patches", in: main) ?? []
        let predownload = optionalDictionary("pre_download", in: root)
        let predownloadMajor = predownload.flatMap { optionalDictionary("major", in: $0) }
        let predownloadVersion = predownloadMajor.flatMap { optionalString("version", in: $0) }
        let predownloadPatches = predownload.flatMap { array("patches", in: $0) } ?? []
        let predownloadTargetAvailable = predownloadVersion != nil
            && containsPatch(for: currentVersion, in: predownloadPatches)

        return GameClientRuntimeMetadata(
            latestVersion: try string("version", in: major),
            updatableVersions: versions(from: patches),
            predownloadVersion: predownloadVersion,
            predownloadAvailable: predownloadVersion != nil,
            predownloadTargetAvailable: predownloadTargetAvailable,
            installSizeBytes: installSizeBytes(from: array("game_pkgs", in: major) ?? []),
            predownloadArchiveBasenames: predownloadArchiveBasenames(
                from: predownloadPatches,
                gamePackageKey: "game_pkgs",
                voicePackageKey: "audio_pkgs",
                remotePathKey: "url",
                currentVersion: currentVersion,
                installedVoiceLanguages: installedVoiceLanguages
            )
        )
    }

    static func parseBH3LauncherResource(
        _ data: Data,
        currentVersion: String? = nil,
        installedVoiceLanguages: Set<String> = []
    ) throws -> GameClientRuntimeMetadata {
        let root = try jsonObject(from: data)
        let dataRoot = try dictionary("data", in: root)
        let game = try dictionary("game", in: dataRoot)
        let latest = try dictionary("latest", in: game)
        let diffs = array("diffs", in: game) ?? []
        let predownload = optionalDictionary("pre_download_game", in: dataRoot)
        let predownloadLatest = predownload.flatMap { optionalDictionary("latest", in: $0) }
        let predownloadVersion = predownloadLatest.flatMap { optionalString("version", in: $0) }
        let predownloadDiffs = predownload.flatMap { array("diffs", in: $0) } ?? []
        let predownloadTargetAvailable = predownloadVersion != nil
            && containsPatch(for: currentVersion, in: predownloadDiffs)

        return GameClientRuntimeMetadata(
            latestVersion: try string("version", in: latest),
            updatableVersions: versions(from: diffs),
            predownloadVersion: predownloadVersion,
            predownloadAvailable: predownloadVersion != nil,
            predownloadTargetAvailable: predownloadTargetAvailable,
            installSizeBytes: optionalInt64("size", in: latest),
            predownloadArchiveBasenames: predownloadArchiveBasenames(
                from: predownloadDiffs,
                gamePackageKey: nil,
                voicePackageKey: "voice_packs",
                remotePathKey: "path",
                currentVersion: currentVersion,
                installedVoiceLanguages: installedVoiceLanguages
            )
        )
    }

    static func parseCBJQManifest(_ data: Data) throws -> GameClientRuntimeMetadata {
        let root = try jsonObject(from: data)
        let paks = array("paks", in: root) ?? []
        return GameClientRuntimeMetadata(
            latestVersion: try string("projectVersion", in: root),
            predownloadAvailable: false,
            predownloadTargetAvailable: false,
            installSizeBytes: installSizeBytes(from: paks, sizeKey: "sizeInBytes"),
            seasunManifestMetadata: try seasunManifestMetadata(from: root)
        )
    }

    private static func seasunManifestMetadata(from root: [String: Any]) throws -> VirtualInstallManifestMetadata {
        let rawPaks = array("paks", in: root) ?? []
        let paks = rawPaks.compactMap(seasunPakMetadata)
        return VirtualInstallManifestMetadata(
            manifestVersion: try string("version", in: root),
            projectVersion: try string("projectVersion", in: root),
            pathOffset: try string("pathOffset", in: root),
            paks: paks,
            sourceServerID: "",
            channel: nil,
            expectedPakCount: rawPaks.count,
            expectedPayloadBytes: paks.reduce(0) { $0 + $1.sizeInBytes }
        )
    }

    private static func seasunPakMetadata(from dictionary: [String: Any]) -> VirtualInstallManifestMetadata.Pak? {
        guard let name = optionalString("name", in: dictionary),
              let hash = optionalString("hash", in: dictionary),
              let sizeInBytes = optionalInt64("sizeInBytes", in: dictionary)
        else {
            return nil
        }

        return VirtualInstallManifestMetadata.Pak(
            name: name,
            hash: hash,
            sizeInBytes: sizeInBytes,
            bPrimary: bool("bPrimary", in: dictionary) ?? false,
            base: optionalString("base", in: dictionary) ?? "",
            diff: optionalString("diff", in: dictionary) ?? "",
            diffSizeBytes: optionalString("diffSizeBytes", in: dictionary) ?? ""
        )
    }

    private static func jsonObject(from data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw ParseError.invalidRoot
        }

        return dictionary
    }

    private static func dictionary(_ key: String, in dictionary: [String: Any]) throws -> [String: Any] {
        guard let value = dictionary[key] as? [String: Any] else {
            throw ParseError.missingField(key)
        }

        return value
    }

    private static func optionalDictionary(_ key: String, in dictionary: [String: Any]) -> [String: Any]? {
        dictionary[key] as? [String: Any]
    }

    private static func array(_ key: String, in dictionary: [String: Any]) -> [[String: Any]]? {
        dictionary[key] as? [[String: Any]]
    }

    private static func string(_ key: String, in dictionary: [String: Any]) throws -> String {
        guard let value = optionalString(key, in: dictionary) else {
            throw ParseError.missingField(key)
        }

        return value
    }

    private static func optionalString(_ key: String, in dictionary: [String: Any]) -> String? {
        dictionary[key] as? String
    }

    private static func stringArray(_ key: String, in dictionary: [String: Any]) throws -> [String] {
        guard let values = dictionary[key] as? [String] else {
            throw ParseError.missingField(key)
        }

        return values
    }

    private static func bool(_ key: String, in dictionary: [String: Any]) -> Bool? {
        dictionary[key] as? Bool
    }

    private static func int64(_ key: String, in dictionary: [String: Any]) throws -> Int64 {
        guard let value = optionalInt64(key, in: dictionary) else {
            throw ParseError.missingField(key)
        }

        return value
    }

    private static func optionalInt64(_ key: String, in dictionary: [String: Any]) -> Int64? {
        if let value = dictionary[key] as? Int {
            return Int64(value)
        }
        if let value = dictionary[key] as? Int64 {
            return value
        }
        if let value = dictionary[key] as? Double {
            return Int64(value)
        }
        if let value = dictionary[key] as? String {
            return Int64(value)
        }

        return nil
    }

    private static func versions(from dictionaries: [[String: Any]]) -> [String] {
        dictionaries.compactMap { optionalString("version", in: $0) }
    }

    private static func containsPatch(
        for currentVersion: String?,
        in patches: [[String: Any]]
    ) -> Bool {
        guard let currentVersion else {
            return false
        }
        return patches.contains { optionalString("version", in: $0) == currentVersion }
    }

    private static func installSizeBytes(
        from packages: [[String: Any]],
        sizeKey: String = "size"
    ) -> Int64? {
        let sizes = packages.compactMap { optionalInt64(sizeKey, in: $0) }
        guard !sizes.isEmpty else {
            return nil
        }

        return sizes.reduce(0, +)
    }

    private static func predownloadArchiveBasenames(
        from patches: [[String: Any]],
        gamePackageKey: String?,
        voicePackageKey: String,
        remotePathKey: String,
        currentVersion: String?,
        installedVoiceLanguages: Set<String>
    ) -> [String] {
        guard let currentVersion,
              let patch = patches.first(where: { optionalString("version", in: $0) == currentVersion })
        else {
            return []
        }

        var basenames = [String]()
        if let gamePackageKey {
            basenames += firstPackageBasename(
                from: array(gamePackageKey, in: patch) ?? [],
                remotePathKey: remotePathKey
            )
        } else if let basename = remoteBasename(from: optionalString(remotePathKey, in: patch)) {
            basenames.append(basename)
        }

        basenames += (array(voicePackageKey, in: patch) ?? []).compactMap { package in
            guard let language = optionalString("language", in: package),
                  installedVoiceLanguages.contains(language)
            else {
                return nil
            }

            return remoteBasename(from: optionalString(remotePathKey, in: package))
        }

        return basenames
    }

    private static func firstPackageBasename(
        from packages: [[String: Any]],
        remotePathKey: String
    ) -> [String] {
        guard let firstPackage = packages.first,
              let basename = remoteBasename(from: optionalString(remotePathKey, in: firstPackage))
        else {
            return []
        }

        return [basename]
    }

    private static func remoteBasename(from remotePath: String?) -> String? {
        guard let remotePath, !remotePath.isEmpty else {
            return nil
        }

        if let url = URL(string: remotePath),
           let lastComponent = url.path.split(separator: "/").last {
            return String(lastComponent)
        }

        return remotePath.split(separator: "/").last.map(String.init)
    }
}
