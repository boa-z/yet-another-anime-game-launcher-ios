import SwiftUI

struct WineSettingsView: View {
    @Bindable var configuration: LauncherConfiguration

    var body: some View {
        Section("Wine") {
            TextField("Wine Distribution", text: $configuration.wineDistro)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            UnavailableCapabilityView(
                title: "Wine Environment",
                systemImage: "wineglass",
                detail: "Wine installation is represented as configuration only in the iOS build."
            )
        }
    }
}

#Preview {
    Form {
        WineSettingsView(configuration: LauncherConfiguration())
    }
}

