import SwiftUI

struct AdvancedSettingsView: View {
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("Advanced") {
            UnavailableCapabilityView(
                title: "Advanced Settings",
                systemImage: "exclamationmark.triangle",
                detail: "Do not change these settings unless you know what they do."
            )

            Picker("Unlock FPS Limit", selection: $configuration.fpsUnlock) {
                ForEach(FPSUnlockOption.allCases) { option in
                    Text(option.title).tag(option)
                }
            }

            Toggle("ReShade", isOn: $configuration.reshade)

            UnavailableCapabilityView(
                title: "Patch and Dependency Downloads",
                systemImage: "lock.shield",
                detail: "DXMT, DXVK, ReShade, aria2, Sophon, and game patch payloads are blocked in this target."
            )
        }

        Section("Dependency Metadata") {
            ForEach(DependencyResource.catalog) { resource in
                LabeledContent(resource.displayName, value: resource.settingsSummary)
                LabeledContent("Desktop Path", value: resource.desktopInstallPath)
            }
        }

        Section("Desktop Sidecar Metadata") {
            ForEach(DesktopSidecarTool.catalog) { tool in
                LabeledContent(tool.displayName, value: tool.settingsSummary)
                LabeledContent("Desktop Path", value: tool.desktopExecutablePath)
            }
        }
    }
}

#Preview {
    Form {
        AdvancedSettingsView(configuration: LauncherConfiguration())
    }
}
