import SwiftUI

struct PrimaryLauncherButtonView: View {
    @Environment(LauncherViewModel.self) private var viewModel

    var body: some View {
        Button {
            Task { await viewModel.runPrimaryAction() }
        } label: {
            Label(viewModel.primaryAction.title, systemImage: viewModel.primaryAction.systemImage)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.borderedProminent)
        .controlSize(.large)
        .disabled(viewModel.isBusy)
    }
}

#Preview {
    PrimaryLauncherButtonView()
        .environment(LauncherViewModel.preview)
        .padding()
}

