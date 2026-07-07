import SwiftUI

struct WineSettingsView: View {
    var configuration: LauncherConfiguration

    var body: some View {
        let translationRuntime = BinaryTranslationRuntime.box64Reference

        Section("Wine") {
            Picker("Wine Distribution", selection: wineDistributionSelection) {
                ForEach(configuration.wineDistributionOptions) { distribution in
                    Text(distribution.displayName).tag(distribution.id)
                }
            }

            LabeledContent("Current Tag", value: configuration.wineDistro)
            LabeledContent("Render Backend", value: configuration.currentWineDistribution?.renderBackend.uppercased() ?? "Unknown")
            LabeledContent("Translation Reference", value: translationRuntime.settingsSummary)
            LabeledContent("Translation Plan", value: translationRuntime.stageSummary)
            LabeledContent("Box64 Sources", value: translationRuntime.sourcePathSummary)
            LabeledContent("DynaRec Controls", value: translationRuntime.dynarecControlsSummary)
            LabeledContent("Native Bridge", value: translationRuntime.nativeBridgeSummary)
            LabeledContent("NetBIOS Name", value: configuration.wineNetbiosName)

            if let pendingWineDistribution = configuration.pendingWineDistribution {
                LabeledContent("Pending Update", value: pendingWineDistribution.displayName)
            }

            UnavailableCapabilityView(
                title: "Wine Environment",
                systemImage: "wineglass",
                detail: "Wine installation is represented as configuration only in the iOS build; \(translationRuntime.safetyNote)."
            )
        }
    }

    private var wineDistributionSelection: Binding<String> {
        Binding {
            configuration.wineDistributionSelection
        } set: { distroID in
            configuration.requestWineDistributionUpdate(id: distroID)
        }
    }
}

#Preview {
    Form {
        WineSettingsView(configuration: LauncherConfiguration())
    }
}
