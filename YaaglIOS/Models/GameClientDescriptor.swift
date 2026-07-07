import Foundation

struct GameClientDescriptor: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let shortTitle: String
    let region: String
    let serverID: String
    let server: GameClientServerMetadata
    let gameType: String
    let releaseType: String
    let productName: String
    let executable: String
    let dataDirectory: String
    let latestVersion: String
    let currentSupportedVersion: String
    let updatableVersions: [String]
    let predownloadVersion: String?
    let predownloadAvailable: Bool
    let predownloadArchiveBasenames: [String]
    let seasunManifestMetadata: VirtualInstallManifestMetadata?
    let installSize: String
    let accentHex: String
    let secondaryHex: String
    let launchButtonLocation: LaunchButtonLocation

    init(
        id: String,
        title: String,
        shortTitle: String,
        region: String,
        serverID: String,
        server: GameClientServerMetadata,
        gameType: String,
        releaseType: String,
        productName: String,
        executable: String,
        dataDirectory: String,
        latestVersion: String,
        currentSupportedVersion: String,
        updatableVersions: [String],
        predownloadVersion: String?,
        predownloadAvailable: Bool,
        predownloadArchiveBasenames: [String] = [],
        seasunManifestMetadata: VirtualInstallManifestMetadata? = nil,
        installSize: String,
        accentHex: String,
        secondaryHex: String,
        launchButtonLocation: LaunchButtonLocation
    ) {
        self.id = id
        self.title = title
        self.shortTitle = shortTitle
        self.region = region
        self.serverID = serverID
        self.server = server
        self.gameType = gameType
        self.releaseType = releaseType
        self.productName = productName
        self.executable = executable
        self.dataDirectory = dataDirectory
        self.latestVersion = latestVersion
        self.currentSupportedVersion = currentSupportedVersion
        self.updatableVersions = updatableVersions
        self.predownloadVersion = predownloadVersion
        self.predownloadAvailable = predownloadAvailable
        self.predownloadArchiveBasenames = predownloadArchiveBasenames
        self.seasunManifestMetadata = seasunManifestMetadata
        self.installSize = installSize
        self.accentHex = accentHex
        self.secondaryHex = secondaryHex
        self.launchButtonLocation = launchButtonLocation
    }
}

extension GameClientDescriptor {
    var desktopDefaultWorkaround3: Bool {
        gameType == "hk4e" && releaseType != "os"
    }

    var enforcesDesktopSupportedVersionCeiling: Bool {
        switch gameType {
        case "bh3", "cbjq":
            true
        default:
            false
        }
    }

    func isAboveDesktopSupportedVersion(_ version: String) -> Bool {
        enforcesDesktopSupportedVersionCeiling
            && SemanticVersion(version) > SemanticVersion(currentSupportedVersion)
    }

    func applying(runtimeMetadata metadata: GameClientRuntimeMetadata) -> GameClientDescriptor {
        let updatedPredownloadAvailable = metadata.predownloadAvailable ?? predownloadAvailable
        let updatedPredownloadVersion = updatedPredownloadAvailable
            ? (metadata.predownloadVersion ?? predownloadVersion)
            : nil
        return GameClientDescriptor(
            id: id,
            title: title,
            shortTitle: shortTitle,
            region: region,
            serverID: serverID,
            server: server,
            gameType: gameType,
            releaseType: releaseType,
            productName: productName,
            executable: executable,
            dataDirectory: dataDirectory,
            latestVersion: metadata.latestVersion ?? latestVersion,
            currentSupportedVersion: metadata.currentSupportedVersion ?? currentSupportedVersion,
            updatableVersions: metadata.updatableVersions ?? updatableVersions,
            predownloadVersion: updatedPredownloadVersion,
            predownloadAvailable: updatedPredownloadAvailable,
            predownloadArchiveBasenames: metadata.predownloadArchiveBasenames ?? predownloadArchiveBasenames,
            seasunManifestMetadata: metadata.seasunManifestMetadata?.applying(client: self) ?? seasunManifestMetadata,
            installSize: metadata.installSize ?? installSize,
            accentHex: accentHex,
            secondaryHex: secondaryHex,
            launchButtonLocation: launchButtonLocation
        )
    }
}
