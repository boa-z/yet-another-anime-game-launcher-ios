import SwiftUI

struct GeneralSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Bindable var configuration: LauncherConfiguration
    @State private var versionTapTimestamps: [Date] = []
    @State private var isShowingAdvancedUnlockAlert = false

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

            Button {
                registerVersionTap()
            } label: {
                LabeledContent("YAAGL Version", value: "development-ios")
            }
            .buttonStyle(.plain)

            if let launcherUpdate = configuration.launcherUpdateMetadata {
                LabeledContent("Latest Update Metadata", value: launcherUpdate.displaySummary)
                LabeledContent("Resource Asset", value: launcherUpdate.resourceAssetName)
                if let sidecarAssetName = launcherUpdate.sidecarAssetName {
                    LabeledContent("Sidecar Asset", value: sidecarAssetName)
                }

                Button("Ignore This Launcher Update", systemImage: "eye.slash") {
                    configuration.ignoreLauncherUpdate(version: launcherUpdate.version)
                }
            }

            Button("Reset Virtual Install", systemImage: "arrow.counterclockwise", role: .destructive) {
                viewModel.resetVirtualInstall()
            }
        }
        .alert("Advanced settings are now available.", isPresented: $isShowingAdvancedUnlockAlert) {
            Button("OK", role: .cancel) {}
        }

        Section("Quick Actions") {
            Button("Check Integrity", systemImage: "checkmark.shield") {
                Task { await viewModel.checkIntegrity() }
            }
            .disabled(viewModel.installState == .notInstalled || viewModel.isBusy)

            Button("Launch Wine Command Line Tool", systemImage: "terminal") {
                viewModel.openWineCommandLineTool()
            }

            Button("Open Game Install Directory", systemImage: "folder") {
                viewModel.openGameInstallDirectory()
            }

            Button("Open YAAGL Data Directory", systemImage: "folder.badge.gearshape") {
                viewModel.openYaaglDataDirectory()
            }

            Button("Check for YAAGL Updates", systemImage: "sparkle.magnifyingglass") {
                Task { await viewModel.checkLauncherUpdate() }
            }
        }
    }

    private func registerVersionTap() {
        guard LauncherConfiguration.advancedSettingsUnlockEnabled else {
            return
        }

        let now = Date.now
        versionTapTimestamps.append(now)
        if versionTapTimestamps.count > 6 {
            versionTapTimestamps.removeFirst(versionTapTimestamps.count - 6)
        }

        guard versionTapTimestamps.count > 5 else {
            return
        }

        let comparisonTap = versionTapTimestamps[versionTapTimestamps.count - 5]
        guard now.timeIntervalSince(comparisonTap) < 1 else {
            return
        }

        let wasHidden = !configuration.advancedSettingsVisible
        configuration.advancedSettingsVisible.toggle()
        versionTapTimestamps.removeAll()
        if wasHidden {
            isShowingAdvancedUnlockAlert = true
        }
    }
}

#Preview {
    Form {
        GeneralSettingsView(configuration: LauncherConfiguration())
            .environment(LauncherViewModel.preview)
    }
}
