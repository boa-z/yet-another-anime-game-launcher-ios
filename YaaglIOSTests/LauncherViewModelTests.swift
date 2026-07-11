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
        XCTAssertNil(savedState.virtualManifestMetadata)
    }

    @MainActor
    func testBH3FreshInstallDoesNotInventConfigMetadata() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let bh3 = try XCTUnwrap(viewModel.clients.first { $0.id == "bh3_global" })
        viewModel.selectedClientID = bh3.id

        await viewModel.runPrimaryAction()

        let savedState = ChannelClientStore(defaults: defaults).load(for: bh3.id)
        XCTAssertEqual(savedState.installState, .installed)
        XCTAssertEqual(savedState.currentVersion, bh3.latestVersion)
        XCTAssertNil(savedState.virtualInstallMetadata)
        XCTAssertNil(savedState.virtualManifestMetadata)
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
        XCTAssertNil(ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id).virtualManifestMetadata)
    }

    @MainActor
    func testBH3UpdateWritesDesktopConfigMetadata() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let bh3 = try XCTUnwrap(viewModel.clients.first { $0.id == "bh3_global" })
        viewModel.selectedClientID = bh3.id
        viewModel.installState = .installed
        viewModel.installDirectory = "iOS Sandbox/VirtualGameData/bh3_global"
        viewModel.currentVersion = "8.3.0"

        XCTAssertEqual(viewModel.primaryAction, .update)

        await viewModel.runPrimaryAction()

        let savedState = ChannelClientStore(defaults: defaults).load(for: bh3.id)
        XCTAssertEqual(savedState.currentVersion, bh3.latestVersion)
        XCTAssertEqual(
            savedState.virtualInstallMetadata,
            VirtualInstallMetadata(client: bh3, gameVersion: bh3.latestVersion)
        )
    }

    @MainActor
    func testCBJQManifestSupportedVersionUpdatesWithoutStaticPatchList() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let cbjq = try XCTUnwrap(viewModel.clients.first { $0.id == "cbjq_global" })
        viewModel.selectedClientID = cbjq.id
        viewModel.installState = .installed
        viewModel.installDirectory = "iOS Sandbox/VirtualGameData/cbjq_global"
        viewModel.currentVersion = cbjq.currentSupportedVersion

        XCTAssertTrue(viewModel.updateRequired)
        XCTAssertEqual(viewModel.primaryAction, .update)

        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(viewModel.currentVersion, cbjq.latestVersion)
        XCTAssertFalse(viewModel.updateRequired)
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "update: Seasun manifest diff compares local manifest.json paks by hash, removes stale paks, and downloads missing paks via Aria2"
        })
        let savedState = ChannelClientStore(defaults: defaults).load(for: cbjq.id)
        XCTAssertNil(savedState.virtualInstallMetadata)
        XCTAssertEqual(
            savedState.virtualManifestMetadata,
            VirtualInstallManifestMetadata(client: cbjq, projectVersion: cbjq.latestVersion)
        )
    }

    @MainActor
    func testInitialWineDefaultUsesSavedSelectedClientDesktopDefault() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" })
        defaults.set(nap.id, forKey: "selected_client_id")

        let viewModel = makeViewModel(defaults: defaults)

        XCTAssertEqual(viewModel.selectedClientID, nap.id)
        XCTAssertEqual(viewModel.configuration.wineDistro, nap.server.desktopDefaultWineDistributionID)
        XCTAssertNil(defaults.string(forKey: "wine_tag"))
    }

    @MainActor
    func testInitialWorkaround3DefaultUsesSavedSelectedClientDesktopDefault() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let hk4eGlobal = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "hk4e_global" })
        defaults.set(hk4eGlobal.id, forKey: "selected_client_id")

        let viewModel = makeViewModel(defaults: defaults)

        XCTAssertEqual(viewModel.selectedClientID, hk4eGlobal.id)
        XCTAssertFalse(viewModel.configuration.workaround3)
        XCTAssertFalse(viewModel.configuration.snapshot.workaround3)
        XCTAssertNil(defaults.string(forKey: "config_workaround3"))
    }

    @MainActor
    func testWineDefaultFollowsClientSwitchUntilStored() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let viewModel = makeViewModel(defaults: defaults)
        let nap = try XCTUnwrap(viewModel.clients.first { $0.id == "nap_global" })
        let cbjq = try XCTUnwrap(viewModel.clients.first { $0.id == "cbjq_global" })

        XCTAssertEqual(viewModel.configuration.wineDistro, viewModel.selectedClient.server.desktopDefaultWineDistributionID)

        viewModel.selectedClientID = nap.id
        XCTAssertEqual(viewModel.configuration.wineDistro, nap.server.desktopDefaultWineDistributionID)
        XCTAssertNil(defaults.string(forKey: "wine_tag"))

        viewModel.selectedClientID = cbjq.id
        XCTAssertEqual(viewModel.configuration.wineDistro, cbjq.server.desktopDefaultWineDistributionID)
        XCTAssertNil(defaults.string(forKey: "wine_tag"))
    }

    @MainActor
    func testWorkaround3DefaultFollowsHK4EClientSwitchUntilStored() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let viewModel = makeViewModel(defaults: defaults)
        let hk4eCN = try XCTUnwrap(viewModel.clients.first { $0.id == "hk4e_cn" })
        let hk4eGlobal = try XCTUnwrap(viewModel.clients.first { $0.id == "hk4e_global" })

        XCTAssertEqual(viewModel.selectedClientID, hk4eCN.id)
        XCTAssertTrue(viewModel.configuration.workaround3)

        viewModel.selectedClientID = hk4eGlobal.id
        XCTAssertFalse(viewModel.configuration.workaround3)
        XCTAssertNil(defaults.string(forKey: "config_workaround3"))

        viewModel.selectedClientID = hk4eCN.id
        XCTAssertTrue(viewModel.configuration.workaround3)
        XCTAssertNil(defaults.string(forKey: "config_workaround3"))
    }

    @MainActor
    func testStoredWorkaround3DoesNotFollowClientSwitch() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        defaults.set("true", forKey: "config_workaround3")
        let viewModel = makeViewModel(defaults: defaults)
        let hk4eGlobal = try XCTUnwrap(viewModel.clients.first { $0.id == "hk4e_global" })

        viewModel.selectedClientID = hk4eGlobal.id

        XCTAssertTrue(viewModel.configuration.workaround3)
        XCTAssertEqual(defaults.string(forKey: "config_workaround3"), "true")
    }

    @MainActor
    func testStoredWineDistributionDoesNotFollowClientSwitch() throws {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        defaults.set("9.9-dxmt", forKey: "wine_tag")
        let viewModel = makeViewModel(defaults: defaults)
        let cbjq = try XCTUnwrap(viewModel.clients.first { $0.id == "cbjq_global" })

        viewModel.selectedClientID = cbjq.id

        XCTAssertEqual(viewModel.configuration.wineDistro, "9.9-dxmt")
        XCTAssertEqual(defaults.string(forKey: "wine_tag"), "9.9-dxmt")
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
    func testSettingsQuickOpenActionsAreRecordedWithoutExternalLaunch() {
        let viewModel = makeViewModel()

        viewModel.openWineCommandLineTool()
        viewModel.openGameInstallDirectory()
        viewModel.openYaaglDataDirectory()

        let messages = viewModel.taskHistory.map(\.message)

        XCTAssertEqual(viewModel.installState, .notInstalled)
        XCTAssertTrue(viewModel.taskHistory.allSatisfy { $0.action == .settingsQuickAction })
        XCTAssertTrue(messages.contains("settings quick action: Wine command line request was recorded; no shell was launched"))
        XCTAssertTrue(messages.contains("settings quick action: game install directory open request for iOS Sandbox/VirtualGameData/hk4e_cn was recorded; no external file manager was launched"))
        XCTAssertTrue(messages.contains("settings quick action: YAAGL data directory open request for iOS sandbox was recorded; no external file manager was launched"))
        XCTAssertEqual(viewModel.alertMessage, "YAAGL data directory open request was recorded for the iOS sandbox.")
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
    func testImportExistingPersistsParsedVirtualMetadata() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let metadata = VirtualInstallMetadata(
            gameVersion: "5.2.0",
            channelID: 9,
            subchannelID: 8,
            cpsReference: "PASTED_CPS",
            sourceServerID: viewModel.selectedClient.serverID
        )

        await viewModel.importExistingVirtualInstall(
            path: "Imported/ParsedGI",
            probeResult: .existing(version: "5.2.0", metadata: metadata)
        )

        XCTAssertEqual(
            ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id).virtualInstallMetadata,
            metadata
        )
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "import: pasted metadata game_version=5.2.0 channel=9 sub_channel=8 cps=<PASTED_CPS> is represented without reading game files"
        })
    }

    @MainActor
    func testImportExistingPersistsParsedCBJQManifestMetadata() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let cbjq = try XCTUnwrap(viewModel.clients.first { $0.id == "cbjq_global" })
        viewModel.selectedClientID = cbjq.id
        let manifestMetadata = VirtualInstallManifestMetadata(
            manifestVersion: "2.0.0.71",
            projectVersion: cbjq.currentSupportedVersion,
            pathOffset: "assets",
            paks: [
                VirtualInstallManifestMetadata.Pak(
                    name: "game_a.pak",
                    hash: "hash-a",
                    sizeInBytes: 100,
                    bPrimary: true,
                    base: "base-a",
                    diff: "diff-a",
                    diffSizeBytes: "10"
                )
            ],
            sourceServerID: cbjq.serverID,
            channel: cbjq.server.desktopServerChannel,
            expectedPakCount: 1,
            expectedPayloadBytes: 100
        )

        await viewModel.importExistingVirtualInstall(
            path: "Imported/SCZManifest",
            probeResult: .existing(
                version: cbjq.currentSupportedVersion,
                manifestMetadata: manifestMetadata
            )
        )

        let savedState = ChannelClientStore(defaults: defaults).load(for: cbjq.id)
        XCTAssertNil(savedState.virtualInstallMetadata)
        XCTAssertEqual(savedState.virtualManifestMetadata, manifestMetadata)
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "import: pasted Seasun manifest version=2.0.0.71 projectVersion=\(cbjq.currentSupportedVersion) pathOffset=assets paks=1 payload_bytes=100 is represented without reading game files"
        })
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
    func testImportExistingCBJQAboveSupportedVersionIsRejected() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let cbjq = try XCTUnwrap(viewModel.clients.first { $0.id == "cbjq_global" })
        viewModel.selectedClientID = cbjq.id

        await viewModel.importExistingVirtualInstall(
            path: "Imported/SCZ",
            probeResult: .existing(version: cbjq.latestVersion)
        )

        XCTAssertEqual(viewModel.installState, .notInstalled)
        XCTAssertEqual(viewModel.installDirectory, "")
        XCTAssertEqual(viewModel.currentVersion, "0.0.0")
        XCTAssertEqual(viewModel.statusText, "Unsupported game version 2.1.0")
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "import: 2.1.0 is above desktop supported 2.0.0; virtual install record is unchanged"
        })
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "Import skipped: existing install could not be used"
        })
    }

    @MainActor
    func testImportExistingBH3AboveSupportedVersionIsRejected() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let bh3 = try XCTUnwrap(viewModel.clients.first { $0.id == "bh3_global" })
        viewModel.selectedClientID = bh3.id

        await viewModel.importExistingVirtualInstall(
            path: "Imported/BH3",
            probeResult: .existing(version: bh3.latestVersion)
        )

        XCTAssertEqual(viewModel.installState, .notInstalled)
        XCTAssertEqual(viewModel.installDirectory, "")
        XCTAssertEqual(viewModel.currentVersion, "0.0.0")
        XCTAssertEqual(viewModel.statusText, "Unsupported game version 8.4.0")
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "import: 8.4.0 is above desktop supported 7.5.0; virtual install record is unchanged"
        })
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "Import skipped: existing install could not be used"
        })
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
    func testImportExistingPersistsParsedDesktopMetadata() async {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults)
        let metadata = VirtualInstallMetadata(
            gameVersion: viewModel.selectedClient.latestVersion,
            channelID: 9,
            subchannelID: 2,
            cpsReference: "CUSTOM_CPS",
            sourceServerID: viewModel.selectedClient.serverID
        )

        await viewModel.importExistingVirtualInstall(
            path: "Imported/Metadata",
            probeResult: .existing(version: viewModel.selectedClient.latestVersion, metadata: metadata)
        )

        XCTAssertEqual(
            ChannelClientStore(defaults: defaults).load(for: viewModel.selectedClient.id).virtualInstallMetadata,
            metadata
        )
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "import: pasted metadata game_version=5.3.0 channel=9 sub_channel=2 cps=<CUSTOM_CPS> is represented without reading game files"
        })
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
    func testStoredBH3ProbeRefreshDoesNotInventConfigMetadata() throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        defaults.set(bh3.id, forKey: "selected_client_id")
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "Imported/BH3Refresh",
                currentVersion: "7.5.0",
                predownloadedAll: false,
                requiresPatchRevert: false
            ),
            for: bh3.id
        )

        let viewModel = makeViewModel(
            defaults: defaults,
            installProbe: VirtualInstallProbe { _, _, _ in .existing(version: "7.5.0") }
        )

        XCTAssertEqual(viewModel.selectedClientID, bh3.id)
        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertNil(store.load(for: bh3.id).virtualInstallMetadata)
    }

    @MainActor
    func testStoredBH3ProbeRefreshPreservesExplicitConfigMetadata() throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        defaults.set(bh3.id, forKey: "selected_client_id")
        let metadata = VirtualInstallMetadata(
            gameVersion: "7.5.0",
            channelID: 0,
            subchannelID: 0,
            cpsReference: "",
            sourceServerID: bh3.serverID
        )
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "Imported/BH3Config",
                currentVersion: "7.5.0",
                predownloadedAll: false,
                requiresPatchRevert: false
            ),
            for: bh3.id
        )

        let viewModel = makeViewModel(
            defaults: defaults,
            installProbe: VirtualInstallProbe { _, _, _ in
                .existing(version: "7.5.0", metadata: metadata)
            }
        )

        XCTAssertEqual(viewModel.selectedClientID, bh3.id)
        XCTAssertEqual(viewModel.installState, .installed)
        XCTAssertEqual(store.load(for: bh3.id).virtualInstallMetadata, metadata)
    }

    @MainActor
    func testCBJQUnsupportedLaunchIsBlockedBeforeSideEffects() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let cbjq = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "cbjq_global" })
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "iOS Sandbox/VirtualGameData/cbjq_global",
                currentVersion: cbjq.latestVersion,
                predownloadedAll: false,
                requiresPatchRevert: true
            ),
            for: cbjq.id
        )
        let viewModel = makeViewModel(defaults: defaults)
        viewModel.selectedClientID = cbjq.id

        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.statusText, "Unsupported game version 2.1.0")
        XCTAssertEqual(viewModel.alertMessage, "Unsupported game version 2.1.0")
        XCTAssertTrue(store.load(for: cbjq.id).requiresPatchRevert)
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "launch: CBJQ version 2.1.0 is above desktop supported 2.0.0; desktop would show unsupported-version alert and skip launch; patchOff is unavailable for this desktop channel"
        })
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "Launch skipped: unsupported version" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Launch simulation complete" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message.contains("launch command preview") })

        viewModel.configuration.patchOff = true
        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.statusText, "Unsupported game version 2.1.0")
        XCTAssertEqual(viewModel.alertMessage, "Unsupported game version 2.1.0")
        XCTAssertTrue(store.load(for: cbjq.id).requiresPatchRevert)
        XCTAssertEqual(
            viewModel.taskHistory.filter { $0.message == "Launch skipped: unsupported version" }.count,
            2
        )
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Launch simulation complete" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message.contains("launch command preview") })
    }

    @MainActor
    func testBH3UnsupportedLaunchCannotBeBypassedByResidualPatchOff() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let bh3 = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "bh3_global" })
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "iOS Sandbox/VirtualGameData/bh3_global",
                currentVersion: bh3.latestVersion,
                predownloadedAll: false,
                requiresPatchRevert: true
            ),
            for: bh3.id
        )
        let viewModel = makeViewModel(defaults: defaults)
        viewModel.selectedClientID = bh3.id

        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.statusText, "Unsupported game version 8.4.0")
        XCTAssertEqual(viewModel.alertMessage, "Unsupported game version 8.4.0")
        XCTAssertTrue(store.load(for: bh3.id).requiresPatchRevert)
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "launch: BH3 version 8.4.0 is above desktop supported 7.5.0; desktop would show unsupported-version alert and skip launch; patchOff is unavailable for this desktop channel"
        })
        XCTAssertTrue(viewModel.taskHistory.contains { $0.message == "Launch skipped: unsupported version" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Launch simulation complete" })

        viewModel.configuration.patchOff = true
        await viewModel.runPrimaryAction()

        XCTAssertEqual(viewModel.statusText, "Unsupported game version 8.4.0")
        XCTAssertEqual(viewModel.alertMessage, "Unsupported game version 8.4.0")
        XCTAssertTrue(store.load(for: bh3.id).requiresPatchRevert)
        XCTAssertEqual(
            viewModel.taskHistory.filter { $0.message == "Launch skipped: unsupported version" }.count,
            2
        )
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message == "Launch simulation complete" })
        XCTAssertFalse(viewModel.taskHistory.contains { $0.message.contains("launch command preview") })
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

        viewModel.configuration.requestWineDistributionUpdate(id: "11.8-dxmt-signed-experimental")

        XCTAssertEqual(viewModel.configuration.wineDistro, WineDistribution.defaultID)
        XCTAssertEqual(viewModel.configuration.wineState, .update)
        XCTAssertEqual(defaults.string(forKey: "wine_state"), "update")

        await viewModel.initializeEnvironment()

        XCTAssertEqual(viewModel.configuration.wineDistro, "11.8-dxmt-signed-experimental")
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
    func testLauncherUpdateCheckRecordsMetadataOnlyResult() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let viewModel = makeViewModel(defaults: defaults, launcherUpdateService: .simulated)

        await viewModel.checkLauncherUpdate()

        let metadata = try XCTUnwrap(viewModel.configuration.launcherUpdateMetadata)

        XCTAssertEqual(metadata.version, "999.0.0")
        XCTAssertEqual(metadata.resourceID, viewModel.selectedClient.server.launcherUpdateResourceID)
        XCTAssertEqual(metadata.resourceAssetName, "resources_hk4ecn.neu")
        XCTAssertEqual(metadata.sidecarAssetName, "Yaagl.app.tar.gz")
        XCTAssertEqual(viewModel.alertMessage, "YAAGL update 999.0.0 metadata is available. Downloads stay disabled on iOS.")
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "launcher update: metadata captured for 999.0.0 (resources_hk4ecn.neu)"
        })
        XCTAssertEqual(defaults.string(forKey: "launcher_update_version"), "999.0.0")
    }

    @MainActor
    func testManualLauncherUpdateCheckStillReportsIgnoredVersion() async {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let viewModel = makeViewModel(defaults: defaults, launcherUpdateService: .simulated)
        viewModel.configuration.ignoreLauncherUpdate(version: "999.0.0")

        await viewModel.checkLauncherUpdate()

        XCTAssertNil(viewModel.configuration.pendingLauncherUpdateMetadata)
        XCTAssertEqual(viewModel.configuration.launcherUpdateMetadata?.version, "999.0.0")
        XCTAssertEqual(viewModel.alertMessage, "YAAGL update 999.0.0 metadata is available. Downloads stay disabled on iOS.")
    }

    @MainActor
    func testLatestLauncherUpdateCheckClearsStoredMetadata() async {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let latestService = LauncherUpdateMetadataService { client in
            let resourceID = await client.server.launcherUpdateResourceID
            return .latest(resourceID: resourceID)
        }
        let viewModel = makeViewModel(defaults: defaults, launcherUpdateService: latestService)
        viewModel.configuration.recordLauncherUpdateMetadata(
            LauncherUpdateMetadata(
                version: "999.0.0",
                releaseBody: "Old",
                resourceID: "hk4ecn",
                resourceAssetName: "resources_hk4ecn.neu",
                downloadURL: "https://example.test/resources_hk4ecn.neu",
                sidecarAssetName: "Yaagl.app.tar.gz",
                sidecarDownloadURL: "https://example.test/Yaagl.app.tar.gz"
            )
        )

        await viewModel.checkLauncherUpdate()

        XCTAssertNil(viewModel.configuration.launcherUpdateMetadata)
        XCTAssertNil(defaults.string(forKey: "launcher_update_version"))
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message == "launcher update: hk4ecn is already latest"
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
    func testPredownloadPersistsPerArchiveMarkersForAria2Clients() async throws {
        let suiteName = "YaaglIOSTests.\(UUID().uuidString)"
        let defaults = makeDefaults(suiteName: suiteName)
        let nap = try XCTUnwrap(GameLibrary.defaultClients.first { $0.id == "nap_global" }).applying(
            runtimeMetadata: GameClientRuntimeMetadata(
                predownloadArchiveBasenames: [
                    "nap_3.0.0_3.1.0_game.zip",
                    "nap_3.0.0_3.1.0_audio_en-us.zip"
                ]
            )
        )
        let viewModel = LauncherViewModel(
            defaults: defaults,
            channelClients: [
                SimulatedGameChannelClient(
                    descriptor: nap,
                    simulationService: LauncherSimulationService(stepDurationMilliseconds: 0)
                )
            ]
        )
        let store = ChannelClientStore(defaults: defaults)
        store.save(
            ChannelClientState(
                installState: .installed,
                installDirectory: "iOS Sandbox/VirtualGameData/nap_global",
                currentVersion: nap.latestVersion,
                predownloadedAll: false,
                requiresPatchRevert: false
            ),
            for: nap.id
        )

        await viewModel.predownload()

        let expectedKeys = PredownloadArchiveMarker.markers(for: nap).map(\.key).sorted()
        let savedState = store.load(for: nap.id)

        XCTAssertTrue(savedState.predownloadedAll)
        XCTAssertEqual(savedState.predownloadedArchiveKeys, expectedKeys)
        XCTAssertTrue(viewModel.taskHistory.contains {
            $0.message.contains("predownload: per-archive marker keys")
        })
    }

    @MainActor
    func testZeroProgressIsDisplayedAsIndeterminate() async {
        let defaults = makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        let viewModel = LauncherViewModel(
            defaults: defaults,
            channelClients: [ZeroProgressChannelClient(descriptor: GameLibrary.defaultClients[0])]
        )

        let integrityTask = Task { @MainActor in
            await viewModel.checkIntegrity()
        }

        while viewModel.statusText != "Zero progress" {
            await Task.yield()
        }

        XCTAssertNil(viewModel.progress)

        await integrityTask.value
    }

    @MainActor
    func testClientSwitchIsBlockedWhileForegroundTaskRuns() async {
        let viewModel = makeViewModel(stepDurationMilliseconds: 40)
        let originalClientID = viewModel.selectedClientID
        let nextClientID = viewModel.clients[1].id

        let installTask = Task { @MainActor in
            await viewModel.runPrimaryAction()
        }

        while !viewModel.isBusy {
            await Task.yield()
        }

        viewModel.selectedClientID = nextClientID

        XCTAssertEqual(viewModel.selectedClientID, originalClientID)
        XCTAssertEqual(viewModel.alertMessage, "Finish the current task before switching clients.")

        await installTask.value
    }

    @MainActor
    func testClientSwitchIsBlockedWhileBackgroundTaskRuns() async {
        let viewModel = makeViewModel(stepDurationMilliseconds: 40)
        let originalClientID = viewModel.selectedClientID
        let nextClientID = viewModel.clients[1].id

        await viewModel.runPrimaryAction()
        let predownloadTask = Task { @MainActor in
            await viewModel.predownload()
        }

        while !viewModel.isBackgroundBusy {
            await Task.yield()
        }

        viewModel.selectedClientID = nextClientID

        XCTAssertEqual(viewModel.selectedClientID, originalClientID)
        XCTAssertEqual(viewModel.alertMessage, "Finish the current task before switching clients.")

        await predownloadTask.value
    }

    @MainActor
    private func makeViewModel(
        defaults: UserDefaults? = nil,
        stepDurationMilliseconds: Int = 0,
        installProbe: VirtualInstallProbe = .trustingPersistedRecord,
        launcherUpdateService: LauncherUpdateMetadataService = .simulated
    ) -> LauncherViewModel {
        let defaults = defaults ?? makeDefaults(suiteName: "YaaglIOSTests.\(UUID().uuidString)")
        return LauncherViewModel(
            defaults: defaults,
            channelClients: GameChannelClientFactory.makeTestingClients(stepDurationMilliseconds: stepDurationMilliseconds),
            installProbe: installProbe,
            launcherUpdateService: launcherUpdateService
        )
    }

    @MainActor
    private func makeDefaults(suiteName: String) -> UserDefaults {
        let defaults = UserDefaults(suiteName: suiteName) ?? .standard
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}

private struct ZeroProgressChannelClient: GameChannelClient {
    let descriptor: GameClientDescriptor

    func updateRequired(in state: ChannelClientState) -> Bool {
        false
    }

    func showPredownloadPrompt(in state: ChannelClientState) -> Bool {
        false
    }

    func predownloadTitle(in state: ChannelClientState) -> String {
        "Pre-download"
    }

    func virtualInstallDirectory() -> String {
        "iOS Sandbox/VirtualGameData/zero_progress"
    }

    func program(for action: LauncherAction, context: GameChannelClientContext) -> CommonUpdateProgram {
        CommonUpdateProgram { continuation in
            Task {
                continuation.yield(.setStateText("Zero progress"))
                continuation.yield(.setProgress(0))
                try? await Task.sleep(for: .milliseconds(120))
                continuation.yield(.setProgress(1))
                continuation.finish()
            }
        }
    }

    func state(
        after action: LauncherAction,
        currentState: ChannelClientState,
        context: GameChannelClientContext
    ) -> ChannelClientState {
        currentState
    }
}
