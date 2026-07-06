import SwiftUI

struct GameSidebarView: View {
    @Environment(LauncherViewModel.self) private var viewModel
    @Binding var selection: String

    var body: some View {
        List {
            Section("Clients") {
                ForEach(viewModel.clients) { client in
                    Button {
                        selection = client.id
                    } label: {
                        ClientBadgeView(client: client)
                    }
                    .buttonStyle(.plain)
                    .listRowBackground(
                        selection == client.id ? Color.accentColor.opacity(0.16) : Color.clear
                    )
                }
            }
        }
        .listStyle(.sidebar)
    }
}

#Preview {
    GameSidebarView(selection: .constant(GameLibrary.defaultClients[0].id))
        .environment(LauncherViewModel.preview)
}
