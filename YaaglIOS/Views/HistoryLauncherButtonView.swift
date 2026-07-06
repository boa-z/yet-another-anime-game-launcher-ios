import SwiftUI

struct HistoryLauncherButtonView: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label("History", systemImage: "clock")
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }
}

#Preview {
    HistoryLauncherButtonView(action: {})
        .padding()
}
