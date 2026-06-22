import XCTest
@testable import ClipLedger

@MainActor
final class AppSettingsTests: XCTestCase {
    private var defaults: UserDefaults!
    private var defaultsSuiteName: String!

    override func setUp() async throws {
        try await super.setUp()
        defaultsSuiteName = "ClipLedgerSettingsTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: defaultsSuiteName)
    }

    override func tearDown() async throws {
        defaults.removePersistentDomain(forName: defaultsSuiteName)
        defaults = nil
        defaultsSuiteName = nil
        try await super.tearDown()
    }

    func testLaunchAtLoginDefaultsEnabledAndAppliesPreference() {
        var requestedStates: [Bool] = []
        let settings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        XCTAssertTrue(settings.launchAtLoginEnabled)
        XCTAssertTrue(requestedStates.isEmpty)

        settings.applyLaunchAtLoginPreference()

        XCTAssertEqual(requestedStates, [true])
    }

    func testLaunchAtLoginTogglePersistsAndUpdatesService() {
        var requestedStates: [Bool] = []
        let settings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        settings.launchAtLoginEnabled = false

        XCTAssertFalse(defaults.bool(forKey: AppSettings.Keys.launchAtLoginEnabled))
        XCTAssertEqual(requestedStates, [false])

        let reloadedSettings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        XCTAssertFalse(reloadedSettings.launchAtLoginEnabled)
        XCTAssertEqual(requestedStates, [false])
    }
}
