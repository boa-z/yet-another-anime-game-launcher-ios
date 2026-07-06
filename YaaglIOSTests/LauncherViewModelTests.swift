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
        XCTAssertEqual(viewModel.statusText, "Unsupported game version 4.9.0")
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Update simulation complete" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Update Game completed" })
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "Update skipped: unsupported version; virtual install record reset" })
    }

    @MainActor
    func testInitializeEnvironmentClearsVirtualPatchMarkerOnce() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "iOS Sandbox/VirtualGameData/hk4e_cn",
                currentVersion: "5.3.0",
                predownloadedAll: false,
                requiresPatchRevert: true
            ),
            for: "hk4e_cn"
        )
        let viewModel = makeViewModel(defaults: defaults)

        await viewModel.initializeEnvironment()

        XCTAssertFalse(store.load(for: "hk4e_cn").requiresPatchRevert)
        XCTAssertEqual(viewModel.taskStatus, .completed(.initEnvironment))
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "init: virtual patched marker was cleared" })

        let historyCount = viewModel.taskHistory.count
        await viewModel.initializeEnvironment()

        XCTAssertEqual(viewModel.taskHistory.count, historyCount)
    }

    @MainActor
    func testPredownloadRunsOnBackgroundQueueWithoutBlockingPrimaryTask() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults, stepDurationMilliseconds: 40)

        await viewModel.runPrimaryAction()

        let predownloadTask = Task { @MainActor in
            await viewModel.predownload()
        }

        while !viewModel.isBackgroundBusy {
            await Task.yield()
        }

        XCTAssertFalse(viewModel.isBusy)

        let launchTask = Task { @MainActor in
            await viewModel.runPrimaryAction()
        }

        while !viewModel.isBusy {
            await Task.yield()
        }

        XCTAssertTrue(viewModel.isBackgroundBusy)

        await predownloadTask.value
        await launchTask.value

        XCTAssertFalse(viewModel.isBusy)
        XCTAssertFalse(viewModel.isBackgroundBusy)
        XCTAssertTrue(ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id).predownloadedAll)
    }

    @MainActor
    private func makeViewModel(
        defaults: UserDefaults? = nil,
        stepDurationMilliseconds: Int = 0
    ) -> LauncherViewModel {
        let defaults = defaults ?? makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: stepDurationMilliseconds)
        )
    }

    @MainActor
    private func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
