import SwiftUI

struct VirtualImportSettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @State private var importPath = ""
    @State private var detectedVersion = ""
    @State private var probeSnippet = ""
    @State private var probeStatus = ""
    @State private var detectedMetadata: VirtualInstallMetadata?
    @State private var detectedManifestMetadata: VirtualInstallManifestMetadata?

    var body: some View {
        Section("Virtual Import") {
            TextField("Install Directory", text: $importPath)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            TextField("Version Probe Snippet", text: $probeSnippet, axis: .vertical)
                .lineLimit(4...8)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            Button("Parse Snippet", systemImage: "doc.text.magnifyingglass", action: parseProbeSnippet)
                .disabled(!canParseSnippet)

            if !probeStatus.isEmpty {
                Text(probeStatus)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

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

    private var canParseSnippet: Bool {
        !probeSnippet.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !viewModel.isBusy
    }

    private var metadataForImport: VirtualInstallMetadata? {
        let version = detectedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard detectedMetadata?.gameVersion == version else {
            return nil
        }
        return detectedMetadata
    }

    private var manifestMetadataForImport: VirtualInstallManifestMetadata? {
        let version = detectedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        guard detectedManifestMetadata?.projectVersion == version else {
            return nil
        }
        return detectedManifestMetadata
    }

    private func fillDefaults() {
        importPath = "iOS Sandbox/Imported/\(viewModel.selectedClient.id)"
        detectedVersion = viewModel.selectedClient.latestVersion
        probeSnippet = ""
        probeStatus = ""
        detectedMetadata = nil
        detectedManifestMetadata = nil
    }

    private func parseProbeSnippet() {
        let parsedSnippet = VirtualInstallSnippetParser().parse(
            probeSnippet,
            for: viewModel.selectedClient
        )
        probeStatus = parsedSnippet.message

        if case .existing(let version, let metadata, let manifestMetadata) = parsedSnippet.probeResult {
            detectedVersion = version
            detectedMetadata = metadata
            detectedManifestMetadata = manifestMetadata
        } else {
            detectedMetadata = nil
            detectedManifestMetadata = nil
        }
    }

    private func importExisting() {
        let version = detectedVersion.trimmingCharacters(in: .whitespacesAndNewlines)
        let metadata = metadataForImport
        let manifestMetadata = manifestMetadataForImport
        Task {
            await viewModel.importExistingVirtualInstall(
                path: importPath,
                probeResult: .existing(
                    version: version,
                    metadata: metadata,
                    manifestMetadata: manifestMetadata
                )
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
