import SwiftUI

struct VirtualImportSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @State private var form = VirtualImportFormState()

    var body: some View {
        Section("Virtual Import") {
            TextField("Install Directory", text: $form.importPath)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Version Probe Snippet", text: $form.probeSnippet, axis: .vertical)
                .lineLimit(4...8)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Parse Snippet", systemImage: "doc.text.magnifyingglass", action: parseProbeSnippet)
                .disabled(!canParseSnippet)

            if !form.probeStatus.isEmpty {
                Text(form.probeStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            TextField("Detected Version", text: $form.detectedVersion)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Import Existing", systemImage: "folder.badge.gearshape", action: importExisting)
                .disabled(!canImportExisting)

            Button("Use New Target", systemImage: "square.and.arrow.down", action: useNewTarget)
                .disabled(!form.hasImportPath || viewModel.isBusy)
        }
        .onAppear(perform: fillDefaults)
        .onChange(of: viewModel.selectedClientID) {
            fillDefaults()
        }
        .onChange(of: form.importPath) {
            form.reconcileEvidence(client: viewModel.selectedClient)
        }
        .onChange(of: form.detectedVersion) {
            form.reconcileEvidence(client: viewModel.selectedClient)
        }
        .onChange(of: form.probeSnippet) {
            form.reconcileEvidence(client: viewModel.selectedClient)
        }
    }

    private var canImportExisting: Bool {
        form.canImportExisting(client: viewModel.selectedClient, isBusy: viewModel.isBusy)
    }

    private var canParseSnippet: Bool {
        form.canParseSnippet(isBusy: viewModel.isBusy)
    }

    private func fillDefaults() {
        form.reset(for: viewModel.selectedClient)
    }

    private func parseProbeSnippet() {
        let parsedSnippet = VirtualInstallSnippetParser().parse(
            form.probeSnippet,
            for: viewModel.selectedClient,
            installPath: form.importPath
        )
        form.apply(parsedSnippet, client: viewModel.selectedClient)
    }

    private func importExisting() {
        let client = viewModel.selectedClient
        guard let request = form.existingImportRequest(client: client) else {
            return
        }
        Task {
            await viewModel.importExistingVirtualInstall(request)
        }
    }

    private func useNewTarget() {
        let importPath = form.importPath
        let clientID = viewModel.selectedClient.id
        Task {
            await viewModel.useNewVirtualInstallTarget(
                path: importPath,
                expectedClientID: clientID
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
