import SwiftUI

struct HeroArtworkView: View {
    let client: GameClientDescriptor

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            LinearGradient(
                colors: [
                    Color(hex: client.accentHex),
                    Color(hex: client.secondaryHex),
                    .black.opacity(0.82)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(.white.opacity(0.18), lineWidth: 34)
                .frame(width: 220, height: 220)
                .offset(x: 210, y: -90)

            VStack(alignment: .leading, spacing: 12) {
                Text(client.title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Label(client.shortTitle, systemImage: "gamecontroller.fill")
                    Label(client.region, systemImage: "network")
                    Label("Simulation", systemImage: "lock.shield")
                }
                .font(.callout.weight(.medium))
                .foregroundStyle(.white.opacity(0.88))
                .labelStyle(.titleAndIcon)
            }
            .padding(24)
        }
        .frame(minHeight: 240)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    HeroArtworkView(client: GameLibrary.defaultClients[0])
        .padding()
}

