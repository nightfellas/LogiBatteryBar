import Foundation
import Combine
import AppKit

@MainActor
public final class BatteryStatusViewModel: ObservableObject {
    @Published public var devices: [LogiDevice] = []
    @Published public var isReceiverConnected: Bool = false
    @Published public var isRefreshing: Bool = false
    @Published public var lastUpdated: Date? = nil
    @Published public var launchAtLogin: Bool = false

    private let hidService: LogiBoltHIDService
    private var timer: Timer?

    public init(hidService: LogiBoltHIDService, autoStart: Bool = true) {
        self.hidService = hidService
        self.launchAtLogin = LaunchAtLoginService.isEnabled

        self.hidService.onDevicesUpdated = { [weak self] updatedDevices in
            guard let self = self else { return }
            self.devices = updatedDevices
            self.lastUpdated = Date()
            self.isRefreshing = false
        }

        self.hidService.onConnectionStateChanged = { [weak self] connected in
            guard let self = self else { return }
            self.isReceiverConnected = connected
            if !connected {
                self.devices = []
            }
        }

        if autoStart {
            startMonitoring()
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: OperationQueue.main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    public convenience init(autoStart: Bool = true) {
        self.init(hidService: LogiBoltHIDService(), autoStart: autoStart)
    }

    public func startMonitoring() {
        hidService.startMonitoring()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.refresh()
            }
        }
    }

    public func stopMonitoring() {
        timer?.invalidate()
        timer = nil
        hidService.stopMonitoring()
    }

    public func refresh() {
        isRefreshing = true
        hidService.refreshDevices()
    }

    public func setLaunchAtLogin(_ enabled: Bool) {
        LaunchAtLoginService.setEnabled(enabled)
        launchAtLogin = LaunchAtLoginService.isEnabled
    }

    public func toggleLaunchAtLogin() {
        setLaunchAtLogin(!launchAtLogin)
    }

    public var menuBarTitle: String {
        guard isReceiverConnected else {
            return "⚡ Logi (Off)"
        }

        guard !devices.isEmpty else {
            return "⚡ Logi..."
        }

        var parts: [String] = []

        // Sort: mouse first, then keyboard
        let sorted = devices.sorted { d1, d2 in
            if d1.deviceType == .mouse && d2.deviceType != .mouse { return true }
            if d1.deviceType != .mouse && d2.deviceType == .mouse { return false }
            return d1.slot < d2.slot
        }

        for device in sorted {
            let icon: String
            switch device.deviceType {
            case .mouse:
                icon = "🖱️"
            case .keyboard:
                icon = "⌨️"
            case .unknown:
                icon = "⚡"
            }

            let chargeBadge = device.chargingStatus.isCharging ? "⚡" : ""
            let pct = device.batteryLevel != nil ? "\(device.batteryLevel!)%" : "--"
            let offlineTag = device.isOnline ? "" : "(zZ)"

            let text = "\(icon) \(chargeBadge)\(pct)\(offlineTag)".replacingOccurrences(of: "  ", with: " ")
            parts.append(text)
        }

        return parts.joined(separator: "  ")
    }
}
