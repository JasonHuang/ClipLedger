import Foundation
import ServiceManagement

enum LaunchAtLoginService {
    @MainActor
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                guard SMAppService.mainApp.status != .enabled else { return }
                try SMAppService.mainApp.register()
            } else {
                guard SMAppService.mainApp.status == .enabled else { return }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("ClipLedger launch-at-login update failed: \(error.localizedDescription)")
        }
    }
}
