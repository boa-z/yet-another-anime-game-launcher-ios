import SwiftUI

struct StatusSummaryView: View {
    @Environment(LauncherViewModel.self) private var viewModel

    var body: some View {
        Grid(horizontalSpacing: 12, verticalSpacing: 12) {
            GridRow {
                SummaryTileView(title: "Install State", value: viewModel.installState.title, systemImage: "externaldrive")
                SummaryTileView(title: "Current Version", value: viewModel.currentVersion, systemImage: "number")
            }
            GridRow {
                SummaryTileView(title: "Latest Version", value: viewModel.selectedClient.latestVersion, systemImage: "arrow.up.circle")
                SummaryTileView(title: "Install Size", value: viewModel.selectedClient.installSize, systemImage: "internaldrive")
            }
        }
    }
}

#Preview {
    StatusSummaryView()
        .environment(LauncherViewModel.preview)
        .padding()
}

