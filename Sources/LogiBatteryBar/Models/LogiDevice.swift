import Foundation
import SwiftUI

public enum LogiDeviceType: String, Codable, Sendable {
    case mouse
    case keyboard
    case unknown

    public var defaultIconName: String {
        switch self {
        case .mouse:
            return "computermouse.fill"
        case .keyboard:
            return "keyboard.fill"
        case .unknown:
            return "computermouse.fill"
        }
    }
}

public enum LogiChargingStatus: String, Codable, Sendable {
    case discharging
    case charging
    case full
    case error
    case unknown

    public var isCharging: Bool {
        return self == .charging
    }

    public var displayText: String {
        switch self {
        case .discharging:
            return "On Battery"
        case .charging:
            return "Charging"
        case .full:
            return "Fully Charged"
        case .error:
            return "Charge Error"
        case .unknown:
            return "Standby"
        }
    }
}

public struct LogiDevice: Identifiable, Sendable, Equatable {
    public let id: String
    public let slot: UInt8
    public var name: String
    public var deviceType: LogiDeviceType
    public var batteryLevel: Int?
    public var chargingStatus: LogiChargingStatus
    public var isOnline: Bool
    public var lastSeen: Date

    public init(
        id: String,
        slot: UInt8,
        name: String,
        deviceType: LogiDeviceType,
        batteryLevel: Int? = nil,
        chargingStatus: LogiChargingStatus = .unknown,
        isOnline: Bool = true,
        lastSeen: Date = Date()
    ) {
        self.id = id
        self.slot = slot
        self.name = name
        self.deviceType = deviceType
        self.batteryLevel = batteryLevel
        self.chargingStatus = chargingStatus
        self.isOnline = isOnline
        self.lastSeen = lastSeen
    }

    public var displayName: String {
        if name.hasPrefix("MX Mechanical Mi") && !name.hasSuffix("Mini") {
            return "MX Mechanical Mini"
        }
        return name
    }

    public var batteryText: String {
        if let level = batteryLevel {
            return "\(level)%"
        }
        return "--"
    }

    public var iconName: String {
        return deviceType.defaultIconName
    }

    public var batterySymbolName: String {
        guard let level = batteryLevel else { return "battery.0" }
        if chargingStatus.isCharging {
            return "battery.100.bolt"
        }
        if level >= 90 {
            return "battery.100"
        } else if level >= 65 {
            return "battery.75"
        } else if level >= 40 {
            return "battery.50"
        } else if level >= 15 {
            return "battery.25"
        } else {
            return "battery.0"
        }
    }
}
