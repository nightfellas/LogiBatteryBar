import XCTest
@testable import LogiBatteryBar

final class HIDPlusPlusProtocolTests: XCTestCase {
    func testMakeFeatureQueryWithSoftwareId() {
        let report = HIDPlusPlusProtocol.makeFeatureQuery(deviceIndex: 1, featureId: 0x1004, softwareId: 0x02)
        XCTAssertEqual(report.count, 20)
        XCTAssertEqual(report[0], 0x11) // Long report ID
        XCTAssertEqual(report[1], 1)    // Device index
        XCTAssertEqual(report[2], 0x00) // Root feature
        XCTAssertEqual(report[3], 0x02) // Software ID
        XCTAssertEqual(report[4], 0x10) // Feature ID high
        XCTAssertEqual(report[5], 0x04) // Feature ID low
    }

    func testParseFeatureIndex() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x00
        response[3] = 0x02 // Echoed software ID
        response[4] = 0x08 // Feature Index found = 8
        
        let index = HIDPlusPlusProtocol.parseFeatureIndex(response: response)
        XCTAssertEqual(index, 0x08)
    }

    func testParseUnifiedBatteryReport() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x08
        response[4] = 85 // 85%
        response[6] = 0x01 // Charging
        
        let result = HIDPlusPlusProtocol.parseUnifiedBattery(response: response)
        XCTAssertEqual(result?.percentage, 85)
        XCTAssertEqual(result?.status, .charging)
    }

    func testParseUnifiedBatteryNearlyFullCharging() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x08
        response[4] = 95 // 95%
        response[6] = 0x02 // Nearly Full Charging
        
        let result = HIDPlusPlusProtocol.parseUnifiedBattery(response: response)
        XCTAssertEqual(result?.percentage, 95)
        XCTAssertEqual(result?.status, .charging)
    }

    func testParseLegacyBatteryReport() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x07
        response[4] = 70   // 70%
        response[5] = 20   // Next level threshold (not status)
        response[6] = 0x00 // Discharging (status is byte 6)
        
        let result = HIDPlusPlusProtocol.parseLegacyBattery(response: response)
        XCTAssertEqual(result?.percentage, 70)
        XCTAssertEqual(result?.status, .discharging)
    }

    func testParseDeviceNameChunkStartingAtByteFour() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x03 // Name feature index
        response[3] = 0x10 // Function 1
        // Name characters start at byte 4: "MX Master 3S"
        let nameBytes: [UInt8] = Array("MX Master 3S".utf8)
        for (i, b) in nameBytes.enumerated() {
            if i + 4 < 20 {
                response[i + 4] = b
            }
        }
        let result = HIDPlusPlusProtocol.parseDeviceNameChunk(response: response)
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.nameChunk, "MX Master 3S")
    }
}
