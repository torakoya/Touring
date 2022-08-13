import Combine
import SwiftUI

struct StatusPanel: View {
    class Status: ObservableObject {
        @Published var clock = ""
        @Published var batteryPlugged = false
        @Published var batteryIcon = ""
        @Published var batteryColor = Color.primary

        private var cancellables = Set<AnyCancellable>()

        init() {
            subscribe()
            update()
        }

        func subscribe() {
            // Considering clock synchronization, it would be a bad idea to
            // refresh every 60 seconds just after the minute changes.
            Timer.publish(every: 5, on: .main, in: .common)
                .autoconnect()
                .sink { _ in
                    self.updateClock()
                }
                .store(in: &cancellables)

            UIDevice.current.isBatteryMonitoringEnabled = true

            NotificationCenter.default.publisher(for: UIDevice.batteryStateDidChangeNotification)
                .sink { _ in
                    self.updateBatteryState()
                }
                .store(in: &cancellables)

            NotificationCenter.default.publisher(for: UIDevice.batteryLevelDidChangeNotification)
                .sink { _ in
                    self.updateBatteryLevel()
                }
                .store(in: &cancellables)
        }

        func unsubscribe() {
            cancellables.removeAll()
        }

        private func updateClock() {
            clock = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        }

        private func updateBatteryLevel() {
            batteryIcon = batteryIcon(of: UIDevice.current.batteryLevel)
            batteryColor = UIDevice.current.batteryLevel <= 0.2 ? .red : .primary
        }

        private func updateBatteryState() {
            batteryPlugged = UIDevice.current.batteryState == .charging || UIDevice.current.batteryState == .full
        }

        private func update() {
            updateClock()
            updateBatteryLevel()
            updateBatteryState()
        }

        private func batteryIcon(of level: Float) -> String {
            if level < 0 {
                return ""
            } else if level < (0.0 + 0.25) / 2 {
                return "battery.0"
            } else if level < (0.25 + 0.5) / 2 {
                return "battery.25"
            } else if level < (0.5 + 0.75) / 2 {
                return "battery.50"
            } else if level < (0.75 + 1.0) / 2 {
                return "battery.75"
            } else {
                return "battery.100"
            }
        }
    }

    @StateObject private var status = Status()

    var body: some View {
        HStack {
            Text(status.clock)
                .bold()
            HStack(alignment: .center, spacing: 0) {
                if !status.batteryIcon.isEmpty {
                    Image(systemName: status.batteryIcon)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(status.batteryColor, Color.primary)
                }
                if status.batteryPlugged {
                    Image(systemName: "bolt.fill")
                }
            }
        }
        .font(.footnote)
        .panel(padding: 5)
        .allowsHitTesting(false)
        .onDisappear { status.unsubscribe() }
    }
}

struct StatusPanel_Previews: PreviewProvider {
    static var previews: some View {
        StatusPanel()
    }
}
