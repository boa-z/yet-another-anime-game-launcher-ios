import SwiftUI

struct WineSettingsView: View {
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("Wine") {
            Picker("Wine Distribution", selection: $configuration.wineDistro) {
                ForEach(WineDistribution.catalog) { distribution in
                    Text(distribution.displayName).tag(distribution.id)
                }
            }

            LabeledContent("Selected Tag", value: configuration.selectedWineDistribution.id)
            LabeledContent("Render Backend", value: configuration.selectedWineDistribution.renderBackend.uppercased())
            LabeledContent("Translation Reference", value: BinaryTranslationRuntime.box64Reference.settingsSummary)
            LabeledContent("NetBIOS Name", value: configuration.wineNetbiosName)

            if let pendingWineDistribution = configuration.pendingWineDistribution {
                LabeledContent("Pending Update", value: pendingWineDistribution.displayName)
            }

            UnavailableCapabilityView(
                title: "Wine Environment",
                systemImage: "wineglass",
                detail: "Wine installation is represented as configuration only in the iOS build."
            )
        }
    }
}

#Preview {
    Form {
        WineSettingsView(configuration: LauncherConfiguration())
    }
}
