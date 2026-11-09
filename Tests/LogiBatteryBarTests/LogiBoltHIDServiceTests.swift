import XCTest
@testable import LogiBatteryBar

@MainActor
final class LogiBoltHIDServiceTests: XCTestCase {
    func testServiceInit() {
        let service = LogiBoltHIDService()
        XCTAssertNotNil(service)
    }

    func testServiceCallbacksSetup() {
        let service = LogiBoltHIDService()
        var updated = false
        service.onDevicesUpdated = { _ in
            updated = true
        }
        XCTAssertFalse(updated)
    }
}
