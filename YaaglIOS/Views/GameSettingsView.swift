import SwiftUI

struct GameSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        let capabilities = viewModel.selectedClient.gameSettingsCapabilities

        Section("Game") {
            LabeledContent("Game Version", value: viewModel.currentVersion)
            LabeledContent("Product", value: viewModel.selectedClient.productName)
            LabeledContent("Executable", value: viewModel.selectedClient.executable)

            if capabilities.patchOff {
                Toggle("Turn off the AC patch", isOn: $configuration.patchOff)
            }

            if capabilities.workaround3 {
                Toggle("Workaround #3", isOn: $configuration.workaround3)
            }

            if capabilities.steamPatch {
                Toggle("Enable Steam Patch", isOn: $configuration.steamPatch)
            }

            if capabilities.blockNet {
                Toggle("Launch Fix (block hosts)", isOn: $configuration.blockNet)
            }

            if capabilities.timeoutFix {
                Toggle("Timeout Fix", isOn: $configuration.timeoutFix)
            }

            if capabilities.hdr {
                Toggle("Enable HDR", isOn: $configuration.hk4eEnableHDR)
            }

            Button("Check Integrity", systemImage: "checkmark.shield") {
                Task { await viewModel.checkIntegrity() }
            }
            .disabled(viewModel.installState == .notInstalled || viewModel.isBusy)
        }

        if capabilities.resolution {
            Section("Resolution") {
                Toggle("Custom resolution", isOn: $configuration.resolutionCustom)
                TextField("Width", value: $configuration.resolutionWidth, format: .number)
                    .keyboardType(.numberPad)
                TextField("Height", value: $configuration.resolutionHeight, format: .number)
                    .keyboardType(.numberPad)
            }
        }
    }
}

#Preview {
    Form {
        GameSettingsView(configuration: LauncherConfiguration())
            .environment(LauncherViewModel.preview)
    }
}
