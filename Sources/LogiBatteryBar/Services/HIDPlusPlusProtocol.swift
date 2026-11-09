import Foundation

public struct HIDPlusPlusProtocol: Sendable {
    public static let reportIDShort: UInt8 = 0x10
    public static let reportIDLong: UInt8 = 0x11
    public static let longReportLength: Int = 20
    public static let shortReportLength: Int = 7

    // Known Feature IDs
    public static let featureRoot: UInt16 = 0x0000
    public static let featureFeatureSet: UInt16 = 0x0001
    public static let featureDeviceNameAndType: UInt16 = 0x0005
    public static let featureBatteryLevelStatus: UInt16 = 0x1000
    public static let featureUnifiedBattery: UInt16 = 0x1004

    // Software IDs for correlated request-response matching
    public static let swIdDeviceName: UInt8 = 0x01
    public static let swIdUnifiedBattery: UInt8 = 0x02
    public static let swIdLegacyBattery: UInt8 = 0x03

    /// Generate a 20-byte HID++ 2.0 query to locate the feature index of a given feature ID
    public static func makeFeatureQuery(deviceIndex: UInt8, featureId: UInt16, softwareId: UInt8 = 0x00) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: longReportLength)
        report[0] = reportIDLong
        report[1] = deviceIndex
        report[2] = 0x00 // Root feature index is always 0
        report[3] = softwareId & 0x0F // Echoed back by device
        report[4] = UInt8((featureId >> 8) & 0xFF)
        report[5] = UInt8(featureId & 0xFF)
        return report
    }

    /// Generate a query to get device name chunk starting at given character offset
    public static func makeDeviceNameQuery(deviceIndex: UInt8, nameFeatureIndex: UInt8, offset: UInt8 = 0) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: longReportLength)
        report[0] = reportIDLong
        report[1] = deviceIndex
        report[2] = nameFeatureIndex
        report[3] = 0x10 // Function 1: getDeviceName(charIndex)
        report[4] = offset
        return report
    }

    /// Generate a battery status query
    public static func makeBatteryStatusQuery(deviceIndex: UInt8, batteryFeatureIndex: UInt8, functionId: UInt8 = 0x10) -> [UInt8] {
        var report = [UInt8](repeating: 0, count: longReportLength)
        report[0] = reportIDLong
        report[1] = deviceIndex
        report[2] = batteryFeatureIndex
        report[3] = functionId
        return report
    }

    /// Parse the returned feature index from a Root Feature (0x0000) response
    public static func parseFeatureIndex(response: [UInt8]) -> UInt8? {
        guard response.count >= 5 else { return nil }
        guard response[0] == reportIDLong || response[0] == reportIDShort else { return nil }
        let featureIdx = response[4]
        return featureIdx > 0 ? featureIdx : nil
    }

    /// Parse a chunk of device name from Feature 0x0005 response (characters start at byte 4)
    public static func parseDeviceNameChunk(response: [UInt8]) -> (nameChunk: String, nextOffset: UInt8)? {
        guard response.count >= 5 else { return nil }
        // In Function 1 (getDeviceName), character bytes begin at index 4 (up to 16 bytes)
        let rawBytes = Array(response[4..<min(response.count, 20)])
        let cleanBytes = rawBytes.filter { $0 >= 32 && $0 <= 126 }
        guard let chunk = String(bytes: cleanBytes, encoding: .utf8), !chunk.isEmpty else {
            return nil
        }
        return (nameChunk: chunk, nextOffset: UInt8(cleanBytes.count))
    }

    /// Parse Feature 0x1004 (Unified Battery)
    public static func parseUnifiedBattery(response: [UInt8]) -> (percentage: Int, status: LogiChargingStatus)? {
        guard response.count >= 7 else { return nil }
        let percentage = Int(response[4])
        guard percentage <= 100 else { return nil }

        let chargeCode = response[6]
        let status: LogiChargingStatus
        switch chargeCode {
        case 0x00:
            status = .discharging
        case 0x01, 0x02, 0x04:
            // 0x01 = Recharging, 0x02 = Nearly full (trickle charging), 0x04 = Slow recharge
            status = .charging
        case 0x03:
            status = .full
        case 0x05, 0x06, 0x07:
            status = .error
        default:
            status = .unknown
        }
        return (percentage: percentage, status: status)
    }

    /// Parse Feature 0x1000 (Battery Level Status - Legacy)
    public static func parseLegacyBattery(response: [UInt8]) -> (percentage: Int, status: LogiChargingStatus)? {
        guard response.count >= 7 else { return nil }
        let percentage = Int(response[4])
        guard percentage <= 100 else { return nil }

        // response[5] is NextLevel threshold; response[6] is status code
        let statusCode = response[6]
        let status: LogiChargingStatus
        switch statusCode {
        case 0x00:
            status = .discharging
        case 0x01, 0x02, 0x04:
            status = .charging
        case 0x03:
            status = .full
        default:
            status = .unknown
        }
        return (percentage: percentage, status: status)
    }
}
