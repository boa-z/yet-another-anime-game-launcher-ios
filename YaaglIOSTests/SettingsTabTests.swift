import XCTest
@testable import YaaglIOS

final class SettingsTabTests: XCTestCase {
    func testAdvancedTabVisibilityMatchesDesktopGate() {
        XCTAssertEqual(SettingsTab.visibleTabs(advancedVisible: false), [.general, .game, .wine, .licenses])
        XCTAssertEqual(SettingsTab.visibleTabs(advancedVisible: true), [.general, .game, .wine, .advanced, .licenses])
    }
}
