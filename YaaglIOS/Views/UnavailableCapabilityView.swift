import SwiftUI

struct UnavailableCapabilityView: View {
    let title: String
    let systemImage: String
    let detail: String

    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: systemImage)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    UnavailableCapabilityView(
        title: "Wine Environment",
        systemImage: "wineglass",
        detail: "Unavailable in this build."
    )
    .padding()
}

