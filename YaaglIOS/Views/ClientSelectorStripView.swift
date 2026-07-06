import SwiftUI

struct ClientSelectorStripView: View {
    @Environment(LauncherViewModel.self) private var viewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(viewModel.clients) { client in
                    Button {
                        viewModel.selectedClientID = client.id
                    } label: {
                        Text(client.shortTitle)
                            .font(.caption.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(
                                viewModel.selectedClientID == client.id
                                    ? Color.accentColor.opacity(0.18)
                                    : Color.secondary.opacity(0.12),
                                in: Capsule()
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    ClientSelectorStripView()
        .environment(LauncherViewModel.preview)
        .padding()
}
