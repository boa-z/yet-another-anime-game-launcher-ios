import SwiftUI

struct TaskHistoryView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                if viewModel.taskHistory.isEmpty {
                    ContentUnavailableView("No Activity", systemImage: "clock")
                } else {
                    ForEach(viewModel.taskHistory) { item in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Label(item.action.title, systemImage: item.action.systemImage)
                                    .font(.headline)
                                Spacer()
                                Text(item.date.shortTimeDisplay)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(item.message)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("Activity")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", action: dismiss.callAsFunction)
                }
            }
        }
    }
}

#Preview {
    TaskHistoryView()
        .environment(LauncherViewModel.preview)
}
