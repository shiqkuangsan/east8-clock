import AppKit
import ServiceManagement

@MainActor
final class LoginItem: ObservableObject {
    @Published private(set) var status = SMAppService.mainApp.status
    @Published private(set) var errorMessage: String?

    private let service = SMAppService.mainApp
    private let defaults = UserDefaults.standard
    private let initializedKey = "LoginItemInitialized"

    var isRequested: Bool {
        status == .enabled || status == .requiresApproval
    }

    func enableOnFirstLaunch() {
        guard !defaults.bool(forKey: initializedKey) else { return }
        refresh()
        if isRequested {
            defaults.set(true, forKey: initializedKey)
        } else {
            setEnabled(true)
        }
    }

    func refresh() {
        status = service.status
    }

    func setEnabled(_ enabled: Bool) {
        errorMessage = nil
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
            defaults.set(true, forKey: initializedKey)
        } catch {
            errorMessage = error.localizedDescription
        }
        refresh()
    }
}

@MainActor
final class StartupDelegate: NSObject, NSApplicationDelegate {
    let loginItem = LoginItem()

    func applicationDidFinishLaunching(_ notification: Notification) {
        loginItem.enableOnFirstLaunch()
    }
}
