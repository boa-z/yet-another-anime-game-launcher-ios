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
    func testPrimaryInstallPersistsVirtualDesktopConfigMetadata() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)

        await viewModel.runPrimaryAction()

        let savedState = ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id)

        XCTAssertEqual(
            savedState.virtualInstallMetadata,
            VirtualInstallMetadata(client: viewModel.selectedClient, gameVersion: viewModel.selectedClient.latestVersion)
        )
    }

    @MainActor
    func testOutdatedVirtualInstallUpdatesToLatestVersion() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        viewModel.installState = .installed
        viewModel.installDirectory = "iOS Sandbox/VirtualGameData/test"
        viewModel.currentVersion = "5.2.0"

        XCTAssertTrue(viewModel.updateRequired)
        XCTAssertEqual(viewModel.primaryAction, .update)

        await viewModel.runPrimaryAction()

        XCTAssertFalse(viewModel.updateRequired)
        XCTAssertEqual(viewModel.currentVersion, viewModel.selectedClient.latestVersion)
        XCTAssertEqual(
            ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id).virtualInstallMetadata,
            VirtualInstallMetadata(client: viewModel.selectedClient, gameVersion: viewModel.selectedClient.latestVersion)
        )
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
    func testAlertMessageCanBePresentedAndDismissed() async {
        let viewModel = makeViewModel()

        await viewModel.importExistingVirtualInstall(path: "   ", probeResult: .newTarget)

        XCTAssertTrue(viewModel.isShowingAlert)
        XCTAssertEqual(viewModel.alertMessage, "Import path is empty")

        viewModel.dismissAlert()

        XCTAssertFalse(viewModel.isShowingAlert)
        XCTAssertNil(viewModel.alertMessage)
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
    func testNewTargetSelectionRunsFreshVirtualInstallAtSelectedPath() async {
        let viewModel = makeViewModel()

        await viewModel.importExistingVirtualInstall(
            path: "Imported/NewTarget",
            probeResult: .newTarget
        )

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.installDirectory, "Imported/NewTarget")
        XCTAssertEqual(viewModel.currentVersion, viewModel.selectedClient.latestVersion)
        XCTAssertEqual(viewModel.primaryAction, .launch)
    }

    @MainActor
    func testImportExistingUpdatableVersionBecomesUpdateAction() async {
        let viewModel = makeViewModel()

        await viewModel.importExistingVirtualInstall(
            path: "Imported/GI",
            probeResult: .existing(version: "5.2.0")
        )

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.installDirectory, "Imported/GI")
        XCTAssertEqual(viewModel.currentVersion, "5.2.0")
        XCTAssertEqual(viewModel.primaryAction, .update)
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "import: existing package at Imported/GI requires update" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message.contains("Blocked game resource download") })
    }

    @MainActor
    func testImportExistingUnsupportedVersionKeepsStoredInstallUnchanged() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let store = ChannelClientStore(defaults: defaults)
        let retainedState = ChannelClientState(
            installState: .installed,
            installDirectory: "Imported/Retained",
            currentVersion: "5.3.0",
            predownloadedAll: false,
            requiresPatchRevert: false
        )
        store.save(retainedState, for: "hk4e_cn")
        let viewModel = makeViewModel(defaults: defaults)
        var refreshedRetainedState = retainedState
        refreshedRetainedState.virtualInstallMetadata = VirtualInstallMetadata(
            client: viewModel.selectedClient,
            gameVersion: retainedState.currentVersion
        )

        await viewModel.importExistingVirtualInstall(
            path: "Imported/TooOld",
            probeResult: .existing(version: "4.9.0")
        )

        XCTAssertEqual(store.load(for: viewModel.selectedClient.id), refreshedRetainedState)
        XCTAssertEqual(viewModel.installDirectory, retainedState.installDirectory)
        XCTAssertEqual(viewModel.currentVersion, retainedState.currentVersion)
        XCTAssertEqual(viewModel.primaryAction, .launch)
        XCTAssertEqual(viewModel.statusText, "Unsupported game version 4.9.0")
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "Import skipped: existing virtual install record unchanged" })
    }

    @MainActor
    func testImportExistingLatestVersionRunsIntegritySimulationThenLaunches() async {
        let viewModel = makeViewModel()

        await viewModel.importExistingVirtualInstall(
            path: "Imported/Latest",
            probeResult: .existing(version: viewModel.selectedClient.latestVersion)
        )

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.installDirectory, "Imported/Latest")
        XCTAssertEqual(viewModel.currentVersion, viewModel.selectedClient.latestVersion)
        XCTAssertEqual(viewModel.primaryAction, .launch)
        XCTAssertEqual(viewModel.statusText, "Import simulation complete")
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "integrity: local files were not read or repaired" })
    }

    @MainActor
    func testStoredVirtualInstallProbeFailureResetsState() {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "Imported/Missing",
                currentVersion: "5.3.0",
                predownloadedAll: true,
                requiresPatchRevert: true
            ),
            for: "hk4e_cn"
        )

        let viewModel = makeViewModel(
            defaults: defaults,
            installProbe: VirtualInstallProbe { _, _, _ in .unreadable }
        )

        XCTAssertEqual(viewModel.installState, .notInstalled)
        XCTAssertEqual(viewModel.installDirectory, "")
        XCTAssertEqual(viewModel.currentVersion, "0.0.0")
        XCTAssertEqual(store.load(for: viewModel.selectedClient.id), .empty)
    }

    @MainActor
    func testStoredVirtualInstallProbeRefreshesVersion() {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "Imported/Refresh",
                currentVersion: "5.1.0",
                predownloadedAll: false,
                requiresPatchRevert: false
            ),
            for: "hk4e_cn"
        )

        let viewModel = makeViewModel(
            defaults: defaults,
            installProbe: VirtualInstallProbe { _, _, _ in .existing(version: "5.2.0") }
        )

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.installDirectory, "Imported/Refresh")
        XCTAssertEqual(viewModel.currentVersion, "5.2.0")
        XCTAssertEqual(viewModel.primaryAction, .update)
        XCTAssertEqual(store.load(for: viewModel.selectedClient.id).currentVersion, "5.2.0")
        XCTAssertEqual(
            store.load(for: viewModel.selectedClient.id).virtualInstallMetadata,
            VirtualInstallMetadata(client: viewModel.selectedClient, gameVersion: "5.2.0")
        )
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
    func testInitializeEnvironmentCompletesPendingWineUpdateSimulation() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)

        viewModel.configuration.wineDistro = "11.8-dxmt-signed-experimental"

        XCTAssertEqual(viewModel.configuration.wineState, .update)
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "update")

        await viewModel.initializeEnvironment()

        XCTAssertEqual(viewModel.configuration.wineState, .ready)
        XCTAssertNil(viewModel.configuration.pendingWineDistribution)
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "ready")
        XCTAssertNil(defaults.string(forKey: "wine_update_tag"))
        XCTAssertNil(defaults.string(forKey: "wine_update_url"))
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "wine update: remote archive https://github.com/yaagl/anime-game-wine/releases/download/wine-11.8-signed/wine-devel-11.8-osx64-signed.tar.xz was not requested"
        })
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "wine update: wine_state will be marked ready after simulation"
        })
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
        stepDurationMilliseconds: Int = 0,
        installProbe: VirtualInstallProbe = .trustingPersistedRecord
    ) -> LauncherViewModel {
        let defaults = defaults ?? makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: stepDurationMilliseconds),
            installProbe: installProbe
        )
    }

    @MainActor
    private func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
