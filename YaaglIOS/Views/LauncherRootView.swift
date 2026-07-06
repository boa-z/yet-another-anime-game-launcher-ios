import SwiftUI

struct LauncherRootView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var viewModel = viewModel

        if horizontalSizeClass == .compact {
            NavigationStack {
                LauncherDashboardView(showsClientSelector: true)
            }
        } else {
            NavigationSplitView(columnVisibility: $columnVisibility) {
                GameSidebarView(selection: $viewModel.selectedClientID)
                    .navigationTitle("YAAGL")
            } detail: {
                LauncherDashboardView()
            }
        }
    }
}

#Preview {
    LauncherRootView()
        .environment(LauncherViewModel.preview)
}
