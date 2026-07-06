import SwiftUI

struct PrimaryActionPanelView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Binding var showingSettings: Bool
    @Binding var showingHistory: Bool

    var body: some View {
        VStack(spacing: 12) {
            if viewModel.showPredownloadPrompt {
                PredownloadPromptView()
            }

            if horizontalSizeClass == .compact {
                VStack(spacing: 10) {
                    PrimaryLauncherButtonView()
                        .frame(maxWidth: .infinity)

                    HStack(spacing: 10) {
                        SettingsLauncherButtonView(action: showSettings)
                            .frame(maxWidth: .infinity)
                        HistoryLauncherButtonView(action: showHistory)
                            .frame(maxWidth: .infinity)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    PrimaryLauncherButtonView()
                    SettingsLauncherButtonView(action: showSettings)
                    HistoryLauncherButtonView(action: showHistory)
                }
                .frame(maxWidth: .infinity, alignment: buttonAlignment)
            }
        }
    }

    private var buttonAlignment: Alignment {
        viewModel.selectedClient.launchButtonLocation == .left ? .leading : .trailing
    }

    private func showSettings() {
        showingSettings = true
    }

    private func showHistory() {
        showingHistory = true
    }
}

#Preview {
    PrimaryActionPanelView(showingSettings: .constant(false), showingHistory: .constant(false))
        .environment(LauncherViewModel.preview)
        .padding()
}
