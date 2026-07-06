import SwiftUI

struct AdvancedSettingsView: View {
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("Advanced") {
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
    }
}

#Preview {
    Form {
        AdvancedSettingsView(configuration: LauncherConfiguration())
    }
}

