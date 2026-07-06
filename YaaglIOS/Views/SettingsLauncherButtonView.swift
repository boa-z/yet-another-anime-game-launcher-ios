import SwiftUI

struct SettingsLauncherButtonView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("Settings", systemImage: "gearshape")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
        .disabled(viewModel.isBusy)
    }
}

#Preview {
    SettingsLauncherButtonView(action: {})
        .environment(LauncherViewModel.preview)
        .padding()
}

