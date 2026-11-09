import XCTest
@testable import LogiBatteryBar
import Foundation

final class LogiDeviceTests: XCTestCase {
    func testDeviceProperties() {
        let device = LogiDevice(
            id: "bolt-slot-1",
            slot: 1,
            name: "MX Master 3S",
            deviceType: .mouse,
            batteryLevel: 85,
            chargingStatus: .discharging,
            isOnline: true,
            lastSeen: Date()
        )
        XCTAssertEqual(device.name, "MX Master 3S")
        XCTAssertEqual(device.batteryLevel, 85)
        XCTAssertEqual(device.chargingStatus, .discharging)
        XCTAssertEqual(device.deviceType, .mouse)
        XCTAssertEqual(device.batteryText, "85%")
        XCTAssertEqual(device.iconName, "computermouse.fill")
        XCTAssertEqual(device.displayName, "MX Master 3S")
    }
}
