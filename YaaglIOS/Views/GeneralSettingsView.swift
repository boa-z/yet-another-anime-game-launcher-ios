import SwiftUI

struct GeneralSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("General") {
            LabeledContent("Game Installation Directory", value: viewModel.installDirectory.isEmpty ? "Not selected" : viewModel.installDirectory)
            Toggle("Metal HUD", isOn: $configuration.metalHud)
            Toggle("Retina Mode", isOn: $configuration.retina)
            Toggle("Map left CMD to CTRL", isOn: $configuration.leftCmd)
        }

        VirtualImportSettingsView()

        Section("Proxy") {
            Toggle("Enable HTTP Proxy", isOn: $configuration.proxyEnabled)
            TextField("HTTP Proxy Host", text: $configuration.proxyHost)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
        }

        Section("Launcher") {
            Picker("Launcher UI Language", selection: $configuration.uiLocale) {
                ForEach(UILocaleOption.allCases) { locale in
                    Text(locale.title).tag(locale)
                }
            }

            LabeledContent("YAAGL Version", value: "development-ios")

            Button("Check for YAAGL Updates", systemImage: "sparkle.magnifyingglass") {
                Task { await viewModel.checkLauncherUpdate() }
            }

            Button("Reset Virtual Install", systemImage: "arrow.counterclockwise", role: .destructive) {
                viewModel.resetVirtualInstall()
            }
        }
    }
}

#Preview {
    Form {
        GeneralSettingsView(configuration: LauncherConfiguration())
            .environment(LauncherViewModel.preview)
    }
}
