import AppKit
import ServiceManagement
import SwiftUI

@main
struct East8ClockApp: App {
    @NSApplicationDelegateAdaptor(StartupDelegate.self) private var startup
    @StateObject private var clock = MenuClock()

    var body: some Scene {
        MenuBarExtra {
            ClockPanel(clock: clock, loginItem: startup.loginItem)
        } label: {
            Text(clock.snapshot.beijing)
                .accessibilityLabel("北京时间 \(clock.snapshot.beijing)")
        }
        .menuBarExtraStyle(.window)
    }
}

private struct ClockPanel: View {
    @ObservedObject var clock: MenuClock
    @ObservedObject var loginItem: LoginItem

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            clockRow("北京时间", time: clock.snapshot.beijing)
            clockRow("洛杉矶时间", time: clock.snapshot.losAngeles)

            Divider()

            Toggle(
                "登录时打开",
                isOn: Binding(get: { loginItem.isRequested }, set: loginItem.setEnabled)
            )
            .toggleStyle(.switch)

            if loginItem.status == .requiresApproval {
                Button("在系统设置中允许登录启动") {
                    SMAppService.openSystemSettingsLoginItems()
                }
            }

            if let message = loginItem.errorMessage {
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Button("退出东八时钟") {
                NSApplication.shared.terminate(nil)
            }
            .buttonStyle(.borderless)
        }
        .padding(14)
        .frame(width: 288)
        .onAppear { loginItem.refresh() }
    }

    private func clockRow(_ city: String, time: String) -> some View {
        HStack {
            Text(city)
                .foregroundStyle(.secondary)
            Spacer(minLength: 16)
            Text(time)
                .monospacedDigit()
                .fontWeight(.medium)
        }
    }
}
