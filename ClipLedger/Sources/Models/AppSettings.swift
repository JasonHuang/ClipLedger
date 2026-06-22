import Foundation

@MainActor
final class AppSettings: ObservableObject {
    enum Keys {
        static let launchAtLoginEnabled = "launchAtLoginEnabled"
        static let maximumHistoryCount = "maximumHistoryCount"
        static let removeConsecutiveDuplicates = "removeConsecutiveDuplicates"
    }

    static let historyCountOptions = [50, 100, 200]
    static let autoPinThreshold = 3

    @Published var launchAtLoginEnabled: Bool {
        didSet {
            defaults.set(launchAtLoginEnabled, forKey: Keys.launchAtLoginEnabled)
            LaunchAtLoginService.setEnabled(launchAtLoginEnabled)
        }
    }

    @Published var maximumHistoryCount: Int {
        didSet {
            if !Self.historyCountOptions.contains(maximumHistoryCount) {
                maximumHistoryCount = 100
                return
            }
            defaults.set(maximumHistoryCount, forKey: Keys.maximumHistoryCount)
        }
    }

    @Published var removeConsecutiveDuplicates: Bool {
        didSet {
            defaults.set(removeConsecutiveDuplicates, forKey: Keys.removeConsecutiveDuplicates)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: [
            Keys.launchAtLoginEnabled: true,
            Keys.maximumHistoryCount: 100,
            Keys.removeConsecutiveDuplicates: true
        ])

        self.launchAtLoginEnabled = defaults.object(forKey: Keys.launchAtLoginEnabled) as? Bool ?? true
        self.maximumHistoryCount = defaults.object(forKey: Keys.maximumHistoryCount) as? Int ?? 100
        self.removeConsecutiveDuplicates = defaults.object(forKey: Keys.removeConsecutiveDuplicates) as? Bool ?? true
    }

    func applyLaunchAtLoginPreference() {
        LaunchAtLoginService.setEnabled(launchAtLoginEnabled)
    }
}
