import SwiftUI

struct LauncherDashboardView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @State private var showingSettings = false
    @State private var showingHistory = false
    let showsClientSelector: Bool

    init(showsClientSelector: Bool = false) {
        self.showsClientSelector = showsClientSelector
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                if showsClientSelector {
                    ClientSelectorStripView()
                }
                HeroArtworkView(client: viewModel.selectedClient)
                StatusSummaryView()
                ProgressPanelView()
                PrimaryActionPanelView(
                    showingSettings: $showingSettings,
                    showingHistory: $showingHistory
                )
            }
            .padding()
            .frame(maxWidth: 980)
            .frame(maxWidth: .infinity)
        }
        .background(.background)
        .navigationTitle(viewModel.selectedClient.shortTitle)
        .toolbar {
            Button("History", systemImage: "clock", action: showHistory)
            Button("Settings", systemImage: "gearshape", action: showSettings)
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showingHistory) {
            TaskHistoryView()
        }
    }

    private func showSettings() {
        showingSettings = true
    }

    private func showHistory() {
        showingHistory = true
    }
}

#Preview {
    NavigationStack {
        LauncherDashboardView()
            .environment(LauncherViewModel.preview)
    }
}
