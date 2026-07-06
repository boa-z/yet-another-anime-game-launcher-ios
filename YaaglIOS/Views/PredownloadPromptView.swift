import SwiftUI

struct PredownloadPromptView: View {
    @Environment(LauncherViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 12) {
            Label(viewModel.predownloadTitle, systemImage: "tray.and.arrow.down")
                .font(.headline)

            Spacer(minLength: 0)

            Button("Dismiss", systemImage: "xmark", action: viewModel.dismissPredownload)
                .buttonStyle(.borderless)

            Button("Start", systemImage: "play.fill") {
                Task { await viewModel.predownload() }
            }
            .buttonStyle(.borderedProminent)
            .disabled(viewModel.isBusy)
        }
        .padding(14)
        .background(.green.opacity(0.14), in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    PredownloadPromptView()
        .environment(LauncherViewModel.preview)
        .padding()
}

