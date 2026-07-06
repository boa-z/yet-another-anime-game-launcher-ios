import Foundation

nonisolated struct DesktopSidecarTool: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let desktopExecutablePath: String
    let role: String
    let relatedFlows: [String]
    let iOSAvailabilityNote: String

    var flowSummary: String {
        relatedFlows.joined(separator: ", ")
    }

    var settingsSummary: String {
        "\(role) at \(desktopExecutablePath)"
    }

    var executionBlockLog: String {
        "sidecar: \(displayName) metadata mirrors \(desktopExecutablePath); \(flowSummary) are not bundled or executed on iOS"
    }

    static let catalog: [DesktopSidecarTool] = [
        DesktopSidecarTool(
            id: "aria2",
            displayName: "aria2",
            desktopExecutablePath: "./sidecar/aria2/aria2c",
            role: "RPC download scheduler",
            relatedFlows: [
                "install archives",
                "pre-download archives",
                "patch archives",
                "launcher assets",
                "dependency assets"
            ],
            iOSAvailabilityNote: "metadata only; RPC process launch and payload downloads are disabled"
        ),
        DesktopSidecarTool(
            id: "xdelta",
            displayName: "xdelta3",
            desktopExecutablePath: "./sidecar/xdelta/xdelta3",
            role: "legacy binary delta patcher",
            relatedFlows: [
                "server patch files",
                "patched-file replacement"
            ],
            iOSAvailabilityNote: "metadata only; binary patch execution is disabled"
        ),
        DesktopSidecarTool(
            id: "hpatchz",
            displayName: "hpatchz",
            desktopExecutablePath: "./sidecar/hpatchz/hpatchz",
            role: "HDiffPatch binary patcher",
            relatedFlows: [
                "hdiffmap.json patches",
                "hdifffiles.txt patches",
                "voice pack patches",
                "Sophon packaging"
            ],
            iOSAvailabilityNote: "metadata only; binary patch execution is disabled"
        ),
        DesktopSidecarTool(
            id: "sophon-server",
            displayName: "Sophon server",
            desktopExecutablePath: "./sidecar/sophon_server/sophon-server",
            role: "HoYoPlay manifest and chunk service",
            relatedFlows: [
                "HK4E install",
                "HK4E update",
                "HK4E pre-download",
                "HK4E integrity repair"
            ],
            iOSAvailabilityNote: "metadata only; local server launch and chunk downloads are disabled"
        )
    ]

    static func tool(id: String) -> DesktopSidecarTool? {
        catalog.first { $0.id == id }
    }

    static func blockLog(ids: [String]) -> String {
        let logs = ids.compactMap { tool(id: $0)?.executionBlockLog }
        guard !logs.isEmpty else {
            return "sidecar: desktop sidecar execution is disabled on iOS"
        }

        return logs.joined(separator: "; ")
    }
}
