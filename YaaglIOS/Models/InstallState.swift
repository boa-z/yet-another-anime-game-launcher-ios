import Foundation

enum InstallState: String, Codable, Sendable {
    case installed = "INSTALLED"
    case notInstalled = "NOT_INSTALLED"

    var title: String {
        switch self {
        case .installed:
            "Installed"
        case .notInstalled:
            "Not Installed"
        }
    }
}

