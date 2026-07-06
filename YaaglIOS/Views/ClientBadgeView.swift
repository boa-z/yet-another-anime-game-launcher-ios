import SwiftUI

struct ClientBadgeView: View {
    let client: GameClientDescriptor

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 2) {
                Text(client.shortTitle)
                    .font(.headline)
                Text(client.region)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            RoundedRectangle(cornerRadius: 6)
                .fill(
                    LinearGradient(
                        colors: [Color(hex: client.accentHex), Color(hex: client.secondaryHex)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 30, height: 30)
                .overlay {
                    Text(String(client.shortTitle.prefix(1)))
                        .font(.caption.bold())
                        .foregroundStyle(.white)
                }
        }
    }
}

#Preview {
    List {
        ClientBadgeView(client: GameLibrary.defaultClients[0])
    }
}

