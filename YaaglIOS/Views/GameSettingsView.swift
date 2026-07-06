import SwiftUI

struct GameSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("Game") {
            LabeledContent("Game Version", value: viewModel.currentVersion)
            LabeledContent("Product", value: viewModel.selectedClient.productName)
            LabeledContent("Executable", value: viewModel.selectedClient.executable)

            Toggle("Turn off the AC patch", isOn: $configuration.patchOff)
            Toggle("Workaround #3", isOn: $configuration.workaround3)
            Toggle("Enable Steam Patch", isOn: $configuration.steamPatch)
            Toggle("Launch Fix (block hosts)", isOn: $configuration.blockNet)
            Toggle("Timeout Fix", isOn: $configuration.timeoutFix)
            Toggle("Enable HDR", isOn: $configuration.hk4eEnableHDR)

            Button("Check Integrity", systemImage: "checkmark.shield") {
                Task { await viewModel.checkIntegrity() }
            }
            .disabled(viewModel.installState == .notInstalled || viewModel.isBusy)
        }

        Section("Resolution") {
            Toggle("Custom resolution", isOn: $configuration.resolutionCustom)
            TextField("Width", value: $configuration.resolutionWidth, format: .number)
                .keyboardType(.numberPad)
            TextField("Height", value: $configuration.resolutionHeight, format: .number)
                .keyboardType(.numberPad)
        }
    }
}

#Preview {
    Form {
        GameSettingsView(configuration: LauncherConfiguration())
            .environment(LauncherViewModel.preview)
    }
}
