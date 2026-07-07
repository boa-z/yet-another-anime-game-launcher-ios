import SwiftUI

struct WineSettingsView: View {
    var configuration: LauncherConfiguration
    @State private var selectedWineDistributionID: String
    @State private var wineUpdateNotice: WineDistributionUpdateNotice?
    @State private var isShowingWineUpdateNotice = false

    init(configuration: LauncherConfiguration) {
        self.configuration = configuration
        _selectedWineDistributionID = State(initialValue: configuration.wineDistributionSelection)
    }

    var body: some View {
        let translationRuntime = BinaryTranslationRuntime.box64Reference

        Section("Wine") {
            Picker("Wine Distribution", selection: $selectedWineDistributionID) {
                ForEach(configuration.wineDistributionOptions) { distribution in
                    Text(distribution.displayName).tag(distribution.id)
                }
            }

            if configuration.wineDistributionSelectionRequiresConfirmation(selectedWineDistributionID) {
                Button("Confirm Wine Change", systemImage: "checkmark.circle", action: confirmWineDistributionChange)
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
        .onChange(of: configuration.wineDistributionSelection) { _, newSelection in
            selectedWineDistributionID = newSelection
        }
        .alert(wineUpdateNotice?.title ?? "Wine update", isPresented: $isShowingWineUpdateNotice) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(wineUpdateNotice?.message ?? "")
        }
    }

    private func confirmWineDistributionChange() {
        wineUpdateNotice = configuration.requestWineDistributionUpdate(id: selectedWineDistributionID)
        selectedWineDistributionID = configuration.wineDistributionSelection
        isShowingWineUpdateNotice = wineUpdateNotice != nil
    }
}

#Preview {
    Form {
        WineSettingsView(configuration: LauncherConfiguration())
    }
}
