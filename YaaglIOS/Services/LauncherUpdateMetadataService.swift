import Foundation

nonisolated struct LauncherUpdateMetadataService: Sendable {
    var check: @Sendable (GameClientDescriptor) async -> LauncherUpdateCheckResult

    func check(for client: GameClientDescriptor) async -> LauncherUpdateCheckResult {
        await check(client)
    }

    static let live = LauncherUpdateMetadataService { client in
        do {
            let release = try await GitHubLatestRelease.fetch()
            return release.updateResult(
                resourceID: client.server.launcherUpdateResourceID,
                currentVersion: LauncherUpdateMetadataService.currentLauncherVersion
            )
        } catch {
            return .unavailable
        }
    }

    static let simulated = LauncherUpdateMetadataService { client in
        let resourceID = client.server.launcherUpdateResourceID
        let resourceAssetName = LauncherUpdateMetadata.resourceAssetName(for: resourceID)
        let sidecarAssetName = LauncherUpdateMetadata.sidecarAssetName(for: resourceID)

        return .available(
            LauncherUpdateMetadata(
                version: "999.0.0",
                releaseBody: "Metadata-only iOS update check; downloads and resource replacement stay disabled.",
                resourceID: resourceID,
                resourceAssetName: resourceAssetName,
                downloadURL: "https://github.com/3shain/yet-another-anime-game-launcher/releases/latest/download/\(resourceAssetName)",
                sidecarAssetName: sidecarAssetName,
                sidecarDownloadURL: sidecarAssetName.map {
                    "https://github.com/3shain/yet-another-anime-game-launcher/releases/latest/download/\($0)"
                }
            )
        )
    }

    static let unavailable = LauncherUpdateMetadataService { _ in
        .unavailable
    }

    private static let currentLauncherVersion = "development-ios"
}

nonisolated private struct GitHubLatestRelease: Decodable, Sendable {
    let tagName: String
    let body: String
    let assets: [Asset]

    enum CodingKeys: String, CodingKey {
        case tagName = "tag_name"
        case body
        case assets
    }

    nonisolated struct Asset: Decodable, Sendable {
        let name: String
        let browserDownloadURL: String

        enum CodingKeys: String, CodingKey {
            case name
            case browserDownloadURL = "browser_download_url"
        }
    }

    static func fetch() async throws -> GitHubLatestRelease {
        guard let url = URL(string: "https://api.github.com/repos/3shain/yet-another-anime-game-launcher/releases/latest") else {
            throw URLError(.badURL)
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        return try JSONDecoder().decode(GitHubLatestRelease.self, from: data)
    }

    func updateResult(resourceID: String, currentVersion: String) -> LauncherUpdateCheckResult {
        let resourceAssetName = LauncherUpdateMetadata.resourceAssetName(for: resourceID)
        guard !currentVersion.hasPrefix("development"),
              SemanticVersion(currentVersion) < SemanticVersion(tagName),
              let resourceAsset = assets.first(where: { $0.name == resourceAssetName })
        else {
            return .latest(resourceID: resourceID)
        }

        let sidecarAssetName = LauncherUpdateMetadata.sidecarAssetName(for: resourceID)
        let sidecarAsset = sidecarAssetName.flatMap { name in
            assets.first { $0.name == name }
        }

        return .available(
            LauncherUpdateMetadata(
                version: tagName,
                releaseBody: body,
                resourceID: resourceID,
                resourceAssetName: resourceAssetName,
                downloadURL: resourceAsset.browserDownloadURL,
                sidecarAssetName: sidecarAssetName,
                sidecarDownloadURL: sidecarAsset?.browserDownloadURL
            )
        )
    }
}
