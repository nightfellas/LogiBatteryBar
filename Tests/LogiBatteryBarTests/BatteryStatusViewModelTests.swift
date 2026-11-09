import XCTest
@testable import LogiBatteryBar
import Foundation

@MainActor
final class BatteryStatusViewModelTests: XCTestCase {
    func testMenuBarTitleWithTwoDevices() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = true
        vm.devices = [
            LogiDevice(id: "1", slot: 1, name: "MX Master 3S", deviceType: .mouse, batteryLevel: 85, chargingStatus: .discharging, isOnline: true, lastSeen: Date()),
            LogiDevice(id: "2", slot: 2, name: "MX Mechanical Mini", deviceType: .keyboard, batteryLevel: 90, chargingStatus: .discharging, isOnline: true, lastSeen: Date())
        ]
        XCTAssertEqual(vm.menuBarTitle, "🖱️ 85%  ⌨️ 90%")
    }

    func testMenuBarTitleCharging() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = true
        vm.devices = [
            LogiDevice(id: "1", slot: 1, name: "MX Master 3S", deviceType: .mouse, batteryLevel: 45, chargingStatus: .charging, isOnline: true, lastSeen: Date())
        ]
        XCTAssertTrue(vm.menuBarTitle.contains("⚡"))
    }

    func testMenuBarTitleDisconnected() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = false
        XCTAssertEqual(vm.menuBarTitle, "⚡ Logi (Off)")
    }
}
