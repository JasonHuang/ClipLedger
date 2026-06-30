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

    func testLaunchAtLoginDefaultsDisabledAndAppliesPreference() {
        var requestedStates: [Bool] = []
        let settings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        XCTAssertFalse(settings.launchAtLoginEnabled)
        XCTAssertTrue(requestedStates.isEmpty)

        settings.applyLaunchAtLoginPreference()

        XCTAssertEqual(requestedStates, [false])
    }

    func testLaunchAtLoginTogglePersistsAndUpdatesService() {
        var requestedStates: [Bool] = []
        let settings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        settings.launchAtLoginEnabled = true

        XCTAssertTrue(defaults.bool(forKey: AppSettings.Keys.launchAtLoginEnabled))
        XCTAssertTrue(defaults.bool(forKey: AppSettings.Keys.launchAtLoginUserConsented))
        XCTAssertEqual(requestedStates, [true])

        let reloadedSettings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        XCTAssertTrue(reloadedSettings.launchAtLoginEnabled)
        XCTAssertEqual(requestedStates, [true])
    }

    func testLegacyLaunchAtLoginDefaultTrueResetsWithoutConsent() {
        defaults.set(true, forKey: AppSettings.Keys.launchAtLoginEnabled)

        var requestedStates: [Bool] = []
        let settings = AppSettings(defaults: defaults) { enabled in
            requestedStates.append(enabled)
        }

        XCTAssertFalse(settings.launchAtLoginEnabled)
        XCTAssertFalse(defaults.bool(forKey: AppSettings.Keys.launchAtLoginEnabled))

        settings.applyLaunchAtLoginPreference()

        XCTAssertEqual(requestedStates, [false])
    }

    func testLaunchAtLoginTrueIsPreservedAfterUserConsent() {
        defaults.set(true, forKey: AppSettings.Keys.launchAtLoginEnabled)
        defaults.set(true, forKey: AppSettings.Keys.launchAtLoginUserConsented)

        let settings = AppSettings(defaults: defaults) { _ in }

        XCTAssertTrue(settings.launchAtLoginEnabled)
    }
}
