import Foundation

nonisolated struct DesktopBuildChannel: Identifiable, Hashable, Sendable {
    static let baseApplicationID = "com.3shain.yaagl"
    static let baseBinaryName = "Yaagl"

    let id: String
    let bundleIDSuffix: String
    let distributionNameSuffix: String
    let iconPath: String
    let includesSophon: Bool
    let runtimeRouteEnvironmentKey: String?
    let runtimeDefaultClientID: String?
    let runtimeEnabledClientID: String?
    let updaterRouteEnvironmentKey: String?
    let updaterDefaultResourceID: String?
    let updaterEnabledResourceID: String?

    var bundleIdentifier: String {
        Self.baseApplicationID + bundleIDSuffix
    }

    var appDistributionName: String {
        Self.baseBinaryName + distributionNameSuffix
    }

    var testBundleIdentifier: String {
        bundleIdentifier + ".test"
    }

    var testAppDistributionName: String {
        appDistributionName + " Test"
    }

    var bundleSummary: String {
        "\(bundleIdentifier) -> \(appDistributionName).app"
    }

    var settingsSummary: String {
        let sophonSummary = includesSophon ? "bundles Sophon sidecar metadata" : "does not bundle Sophon sidecar metadata"
        return "\(bundleSummary); \(sophonSummary)"
    }

    var hasRuntimeRouting: Bool {
        runtimeRouteEnvironmentKey != nil || updaterRouteEnvironmentKey != nil
    }

    var routingSummary: String {
        guard let runtimeRouteEnvironmentKey,
              let runtimeDefaultClientID,
              let runtimeEnabledClientID,
              let updaterRouteEnvironmentKey,
              let updaterDefaultResourceID,
              let updaterEnabledResourceID
        else {
            return "no runtime channel routing"
        }

        return "\(runtimeRouteEnvironmentKey)=1 routes client \(runtimeEnabledClientID), otherwise \(runtimeDefaultClientID); \(updaterRouteEnvironmentKey)=1 routes updater \(updaterEnabledResourceID), otherwise \(updaterDefaultResourceID)"
    }

    static let catalog: [DesktopBuildChannel] = [
        DesktopBuildChannel(
            id: "hk4ecn",
            bundleIDSuffix: "",
            distributionNameSuffix: "",
            iconPath: "/src/icons/Paimon.cr.png",
            includesSophon: true
        ),
        DesktopBuildChannel(
            id: "hk4eos",
            bundleIDSuffix: ".os",
            distributionNameSuffix: " OS",
            iconPath: "/src/icons/Paimon.cr.png",
            includesSophon: true
        ),
        DesktopBuildChannel(
            id: "hk4euniversal",
            bundleIDSuffix: ".uni",
            distributionNameSuffix: " Uni",
            iconPath: "/src/icons/Paimon.cr.png",
            includesSophon: true,
            runtimeRouteEnvironmentKey: "YAAGL_OVERSEA",
            runtimeDefaultClientID: "hk4ecn",
            runtimeEnabledClientID: "hk4eos",
            updaterRouteEnvironmentKey: "YAAGL_OS",
            updaterDefaultResourceID: "hk4ecn",
            updaterEnabledResourceID: "hk4eos"
        ),
        DesktopBuildChannel(
            id: "hkrpgcn",
            bundleIDSuffix: ".hkrpg.cn",
            distributionNameSuffix: " HSR",
            iconPath: "/src/icons/March7th.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "hkrpgos",
            bundleIDSuffix: ".hkrpg.os",
            distributionNameSuffix: " HSR OS",
            iconPath: "/src/icons/March7th.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "bh3glb",
            bundleIDSuffix: ".bh3.glb",
            distributionNameSuffix: " Honkai Global",
            iconPath: "/src/icons/Elysia.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "cbjq",
            bundleIDSuffix: ".scz.os",
            distributionNameSuffix: " SCZ OS",
            iconPath: "/src/icons/Paimon.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "cbjqcn",
            bundleIDSuffix: ".scz.cn",
            distributionNameSuffix: " SCZ",
            iconPath: "/src/icons/Paimon.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "napos",
            bundleIDSuffix: ".nap.os",
            distributionNameSuffix: " ZZZ OS",
            iconPath: "/src/icons/ZZZ_Bang.cr.png",
            includesSophon: false
        ),
        DesktopBuildChannel(
            id: "napcn",
            bundleIDSuffix: ".nap.cn",
            distributionNameSuffix: " ZZZ",
            iconPath: "/src/icons/ZZZ_Bang.cr.png",
            includesSophon: false
        )
    ]

    init(
        id: String,
        bundleIDSuffix: String,
        distributionNameSuffix: String,
        iconPath: String,
        includesSophon: Bool,
        runtimeRouteEnvironmentKey: String? = nil,
        runtimeDefaultClientID: String? = nil,
        runtimeEnabledClientID: String? = nil,
        updaterRouteEnvironmentKey: String? = nil,
        updaterDefaultResourceID: String? = nil,
        updaterEnabledResourceID: String? = nil
    ) {
        self.id = id
        self.bundleIDSuffix = bundleIDSuffix
        self.distributionNameSuffix = distributionNameSuffix
        self.iconPath = iconPath
        self.includesSophon = includesSophon
        self.runtimeRouteEnvironmentKey = runtimeRouteEnvironmentKey
        self.runtimeDefaultClientID = runtimeDefaultClientID
        self.runtimeEnabledClientID = runtimeEnabledClientID
        self.updaterRouteEnvironmentKey = updaterRouteEnvironmentKey
        self.updaterDefaultResourceID = updaterDefaultResourceID
        self.updaterEnabledResourceID = updaterEnabledResourceID
    }

    static func channel(id: String) -> DesktopBuildChannel? {
        catalog.first { $0.id == id }
    }
}
