import SwiftUI

struct ProgressPanelView: View {
    @Environment(LauncherViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Task", systemImage: "waveform.path.ecg")
                    .font(.headline)
                Spacer()
                Text(viewModel.isBusy || viewModel.isBackgroundBusy ? "Busy" : "Idle")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        viewModel.isBusy || viewModel.isBackgroundBusy ? .orange.opacity(0.18) : .green.opacity(0.18),
                        in: Capsule()
                    )
            }

            Text(viewModel.statusText)
                .font(.body)
                .foregroundStyle(.secondary)
                .lineLimit(2)

            if viewModel.isBusy {
                if let progress = viewModel.progress {
                    ProgressView(value: progress)
                } else {
                    ProgressView()
                }
            } else {
                Color.clear
                    .frame(height: 20)
            }

            if viewModel.isBackgroundBusy {
                Divider()

                Text(viewModel.backgroundStatusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)

                if let backgroundProgress = viewModel.backgroundProgress {
                    ProgressView(value: backgroundProgress)
                } else {
                    ProgressView()
                }
            }
        }
        .padding(16)
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    ProgressPanelView()
        .environment(LauncherViewModel.preview)
        .padding()
}
