import SwiftUI

struct ContentView: View {
    var body: some View {
        LauncherRootView()
    }
}

#Preview {
    ContentView()
        .environment(LauncherViewModel.preview)
}

