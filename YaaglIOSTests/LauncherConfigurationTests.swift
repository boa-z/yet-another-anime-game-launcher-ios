import XCTest
@testable import YaaglIOS

final class LauncherConfigurationTests: XCTestCase {
    @MainActor
    func testWorkaround3DefaultsToEnabledForAppleSimulation() {
        let configuration = LauncherConfiguration(defaults: makeDefaults())

        XCTAssertTrue(configuration.workaround3)
        XCTAssertTrue(configuration.snapshot.workaround3)
    }

    @MainActor
    func testWorkaround3PersistsToDefaults() {
        let suiteName = "LauncherConfigurationTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let configuration = LauncherConfiguration(defaults: defaults)

        configuration.workaround3 = false

        let reloadedConfiguration = LauncherConfiguration(defaults: defaults)

        XCTAssertFalse(reloadedConfiguration.workaround3)
        XCTAssertFalse(reloadedConfiguration.snapshot.workaround3)
    }

    @MainActor
    private func makeDefaults(suiteName: String = "LauncherConfigurationTests.\(UUID().uuidString)") -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
