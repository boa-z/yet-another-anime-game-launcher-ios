import SwiftUI

struct LauncherRootView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var columnVisibility = NavigationSplitViewVisibility.all

    var body: some View {
        @Bindable var viewModel = viewModel

        Group {
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
        .alert("YAAGL", isPresented: $viewModel.isShowingAlert) {
            Button("OK", role: .cancel, action: viewModel.dismissAlert)
        } message: {
            Text(viewModel.alertMessage ?? "")
        }
    }
}

#Preview {
    LauncherRootView()
        .environment(LauncherViewModel.preview)
}
