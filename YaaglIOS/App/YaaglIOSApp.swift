import SwiftUI

@main
struct YaaglIOSApp: App {
    @State private var viewModel = LauncherViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(viewModel)
                .task {
                    await viewModel.initializeEnvironment()
                }
        }
    }
}
