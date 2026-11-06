import AppKit
import Combine
import Foundation

@MainActor
final class MenuClock: ObservableObject {
    @Published private(set) var snapshot = ClockSnapshot(date: .now)

    private var timer: Timer?
    private var clockChanges: AnyCancellable?

    init() {
        clockChanges = NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .merge(with: NotificationCenter.default.publisher(for: .NSSystemClockDidChange))
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in self?.resetTimer() }
        resetTimer()
    }

    private func resetTimer() {
        let now = Date.now
        snapshot = ClockSnapshot(date: now)
        timer?.invalidate()

        let nextMinute = Date(timeIntervalSince1970: (floor(now.timeIntervalSince1970 / 60) + 1) * 60)
        let timer = Timer(fire: nextMinute, interval: 60, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.snapshot = ClockSnapshot(date: .now)
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }
}
