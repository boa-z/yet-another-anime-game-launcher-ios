import SwiftUI

struct VirtualImportSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @State private var importPath = ""
    @State private var detectedVersion = ""

    var body: some View {
        Section("Virtual Import") {
            TextField("Install Directory", text: $importPath)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Detected Version", text: $detectedVersion)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Import Existing", systemImage: "folder.badge.gearshape", action: importExisting)
                .disabled(!canImportExisting)

            Button("Use New Target", systemImage: "square.and.arrow.down", action: useNewTarget)
                .disabled(!hasImportPath || viewModel.isBusy)
        }
        .onAppear(perform: fillDefaults)
        .onChange(of: viewModel.selectedClientID) {
            fillDefaults()
        }
    }

    private var hasImportPath: Bool {
        !importPath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canImportExisting: Bool {
        hasImportPath
            && !detectedVersion.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isBusy
    }

    private func fillDefaults() {
        importPath = "iOS Sandbox/Imported/\(viewModel.selectedClient.id)"
        detectedVersion = viewModel.selectedClient.latestVersion
    }

    private func importExisting() {
        Task {
            await viewModel.importExistingVirtualInstall(
                path: importPath,
                probeResult: .existing(version: detectedVersion)
            )
        }
    }

    private func useNewTarget() {
        Task {
            await viewModel.importExistingVirtualInstall(
                path: importPath,
                probeResult: .newTarget
            )
        }
    }
}

#Preview {
    Form {
        VirtualImportSettingsView()
            .environment(LauncherViewModel.preview)
    }
}
