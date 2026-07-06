import SwiftUI

struct LicenseSettingsView: View {
    var body: some View {
        Section("Licenses") {
            Text("Original YAAGL code is MIT licensed. Sidecar binaries from the desktop launcher are not bundled in this iOS project.")
            Text("Steam compatibility files, Wine, DXMT, DXVK, aria2, hpatchz, xdelta, and Sophon server assets are intentionally absent.")
        }
    }
}

#Preview {
    Form {
        LicenseSettingsView()
    }
}

