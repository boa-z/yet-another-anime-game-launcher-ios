import SwiftUI

struct SettingsView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = SettingsTab.general

    var body: some View {
        @Bindable var configuration = viewModel.configuration

        NavigationStack {
            Form {
                Picker("Section", selection: $selectedTab) {
                    ForEach(SettingsTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)

                switch selectedTab {
                case .general:
                    GeneralSettingsView(configuration: configuration)
                case .game:
                    GameSettingsView(configuration: configuration)
                case .wine:
                    WineSettingsView(configuration: configuration)
                case .advanced:
                    AdvancedSettingsView(configuration: configuration)
                case .licenses:
                    LicenseSettingsView()
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environment(LauncherViewModel.preview)
}

