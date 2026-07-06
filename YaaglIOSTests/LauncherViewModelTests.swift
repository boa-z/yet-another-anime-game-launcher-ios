import XCTest
@testable import YaaglIOS

final class LauncherViewModelTests: XCTestCase {
    func testSemanticVersionComparesNumericPartsAndPlusSuffix() {
        XCTAssertLessThan(SemanticVersion("5.2.0"), SemanticVersion("5.3.0"))
        XCTAssertEqual(SemanticVersion("5.3.0+"), SemanticVersion("5.3.0"))
        XCTAssertGreaterThan(SemanticVersion("5.10.0"), SemanticVersion("5.3.9"))
    }

    @MainActor
    func testPrimaryActionInstallsVirtualRecordThenLaunches() async {
        let viewModel = makeViewModel()

        XCTAssertEqual(viewModel.primaryAction, .install)

        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.currentVersion, viewModel.selectedClient.latestVersion)
        XCTAssertEqual(viewModel.primaryAction, .launch)
        XCTAssertFalse(viewModel.installDirectory.isEmpty)
    }

    @MainActor
    func testOutdatedVirtualInstallUpdatesToLatestVersion() async {
        let viewModel = makeViewModel()
        viewModel.installState = .installed
        viewModel.installDirectory = "iOS Sandbox/VirtualGameData/test"
        viewModel.currentVersion = "5.2.0"

        XCTAssertTrue(viewModel.updateRequired)
        XCTAssertEqual(viewModel.primaryAction, .update)

        await viewModel.runPrimaryAction()

        XCTAssertFalse(viewModel.updateRequired)
        XCTAssertEqual(viewModel.currentVersion, viewModel.selectedClient.latestVersion)
    }

    @MainActor
    func testPredownloadPromptCanBeDismissed() async {
        let viewModel = makeViewModel()

        await viewModel.runPrimaryAction()

        XCTAssertTrue(viewModel.showPredownloadPrompt)
        viewModel.dismissPredownload()
        XCTAssertFalse(viewModel.showPredownloadPrompt)
    }

    @MainActor
    func testDismissedPredownloadPromptIsOnlySessionLocal() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)

        await viewModel.runPrimaryAction()
        viewModel.dismissPredownload()

        let reloadedViewModel = makeViewModel(defaults: defaults)

        XCTAssertTrue(reloadedViewModel.showPredownloadPrompt)
    }

    @MainActor
    func testPredownloadCompletionPersistsMarker() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)

        await viewModel.runPrimaryAction()

        XCTAssertTrue(viewModel.showPredownloadPrompt)

        await viewModel.predownload()

        XCTAssertFalse(viewModel.showPredownloadPrompt)

        let reloadedViewModel = makeViewModel(defaults: defaults)

        XCTAssertFalse(reloadedViewModel.showPredownloadPrompt)
    }

    @MainActor
    func testUnsupportedOutdatedVersionResetsVirtualInstall() async {
        let viewModel = makeViewModel()
        viewModel.installState = .installed
        viewModel.installDirectory = "iOS Sandbox/VirtualGameData/test"
        viewModel.currentVersion = "4.9.0"

        XCTAssertTrue(viewModel.updateRequired)
        XCTAssertEqual(viewModel.primaryAction, .update)

        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.installState, .notInstalled)
        XCTAssertEqual(viewModel.installDirectory, "")
        XCTAssertEqual(viewModel.currentVersion, "0.0.0")
        XCTAssertEqual(viewModel.primaryAction, .install)
    }

    @MainActor
    private func makeViewModel(defaults: UserDefaults? = nil) -> LauncherViewModel {
        let defaults = defaults ?? makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: 0)
        )
    }

    @MainActor
    private func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
