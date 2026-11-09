import Foundation
import IOKit
import IOKit.hid

public enum BatteryFeatureType: Sendable {
    case unified // Feature 0x1004
    case legacy  // Feature 0x1000
}

@MainActor
public final class LogiBoltHIDService {
    public var onDevicesUpdated: (([LogiDevice]) -> Void)?
    public var onConnectionStateChanged: ((Bool) -> Void)?

    private var hidManager: IOHIDManager?
    private var isMonitoring = false

    // Cached known devices indexed by slot
    private var cachedDevices: [UInt8: LogiDevice] = [:]
    // Slot -> (Battery feature index, feature type)
    private var batteryFeatureIndices: [UInt8: (index: UInt8, type: BatteryFeatureType)] = [:]
    // Slot -> Name feature index
    private var nameFeatureIndices: [UInt8: UInt8] = [:]

    public init() {}

    public func startMonitoring() {
        guard !isMonitoring else { return }
        isMonitoring = true
        setupHIDManager()
        refreshDevices()
    }

    public func stopMonitoring() {
        guard isMonitoring else { return }
        isMonitoring = false

        if let manager = hidManager {
            IOHIDManagerClose(manager, IOOptionBits(kIOHIDOptionsTypeNone))
            IOHIDManagerUnscheduleFromRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)
            hidManager = nil
        }
        onConnectionStateChanged?(false)
    }

    private func setupHIDManager() {
        let manager = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
        self.hidManager = manager

        // Match Logitech Bolt Receiver (50504 / 0xC548) and Unifying Receiver (50475 / 0xC52B)
        let matchingCriteria: [[String: Any]] = [
            [
                kIOHIDVendorIDKey: 1133,
                kIOHIDProductIDKey: 50504,
                kIOHIDPrimaryUsagePageKey: 0xFF00,
                kIOHIDPrimaryUsageKey: 0x0001
            ],
            [
                kIOHIDVendorIDKey: 1133,
                kIOHIDProductIDKey: 50475,
                kIOHIDPrimaryUsagePageKey: 0xFF00,
                kIOHIDPrimaryUsageKey: 0x0001
            ]
        ]
        IOHIDManagerSetDeviceMatchingMultiple(manager, matchingCriteria as CFArray)
        IOHIDManagerScheduleWithRunLoop(manager, CFRunLoopGetMain(), CFRunLoopMode.defaultMode.rawValue)

        let context = Unmanaged.passUnretained(self).toOpaque()

        let reportCallback: IOHIDReportCallback = { context, result, sender, type, reportId, report, reportLength in
            guard let context = context else { return }
            let service = Unmanaged<LogiBoltHIDService>.fromOpaque(context).takeUnretainedValue()
            let data = Array(UnsafeBufferPointer(start: report, count: reportLength))
            Task { @MainActor in
                service.handleIncomingReport(reportId: UInt8(reportId), data: data)
            }
        }

        IOHIDManagerRegisterInputReportCallback(manager, reportCallback, context)

        let matchCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let service = Unmanaged<LogiBoltHIDService>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                service.refreshDevices()
            }
        }

        let removalCallback: IOHIDDeviceCallback = { context, result, sender, device in
            guard let context = context else { return }
            let service = Unmanaged<LogiBoltHIDService>.fromOpaque(context).takeUnretainedValue()
            Task { @MainActor in
                service.handleDeviceRemoval()
            }
        }

        IOHIDManagerRegisterDeviceMatchingCallback(manager, matchCallback, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, removalCallback, context)

        IOHIDManagerOpen(manager, IOOptionBits(kIOHIDOptionsTypeNone))
    }

    public func refreshDevices() {
        guard let manager = hidManager else { return }
        let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> ?? []

        if devices.isEmpty {
            onConnectionStateChanged?(false)
            return
        }

        onConnectionStateChanged?(true)
        guard let boltDevice = devices.first else { return }

        // Enumerate slots 1 through 6
        for slot in UInt8(1)...UInt8(6) {
            // 1. Query device name feature index if missing
            if nameFeatureIndices[slot] == nil {
                let nameQuery = HIDPlusPlusProtocol.makeFeatureQuery(
                    deviceIndex: slot,
                    featureId: HIDPlusPlusProtocol.featureDeviceNameAndType,
                    softwareId: HIDPlusPlusProtocol.swIdDeviceName
                )
                sendReport(to: boltDevice, report: nameQuery)
            } else if let nameIdx = nameFeatureIndices[slot], (cachedDevices[slot]?.name.isEmpty ?? true) {
                let getName = HIDPlusPlusProtocol.makeDeviceNameQuery(deviceIndex: slot, nameFeatureIndex: nameIdx, offset: 0)
                sendReport(to: boltDevice, report: getName)
            }

            // 2. Query battery feature index if missing (starts with Unified Battery 0x1004)
            if batteryFeatureIndices[slot] == nil {
                let batQuery = HIDPlusPlusProtocol.makeFeatureQuery(
                    deviceIndex: slot,
                    featureId: HIDPlusPlusProtocol.featureUnifiedBattery,
                    softwareId: HIDPlusPlusProtocol.swIdUnifiedBattery
                )
                sendReport(to: boltDevice, report: batQuery)
            } else if let batInfo = batteryFeatureIndices[slot] {
                let reqBat = HIDPlusPlusProtocol.makeBatteryStatusQuery(
                    deviceIndex: slot,
                    batteryFeatureIndex: batInfo.index,
                    functionId: 0x10
                )
                sendReport(to: boltDevice, report: reqBat)
            }
        }
    }

    private func sendReport(to device: IOHIDDevice, report: [UInt8]) {
        guard !report.isEmpty else { return }
        IOHIDDeviceSetReport(device, kIOHIDReportTypeOutput, CFIndex(report[0]), report, report.count)
    }

    private func handleDeviceRemoval() {
        cachedDevices.removeAll()
        batteryFeatureIndices.removeAll()
        nameFeatureIndices.removeAll()
        onConnectionStateChanged?(false)
        emitDevices()
    }

    private func handleIncomingReport(reportId: UInt8, data: [UInt8]) {
        guard data.count >= 4 else { return }
        let slot = data[1]

        // Error report (0x8F)
        if (reportId == HIDPlusPlusProtocol.reportIDShort && data[2] == 0x8F) ||
           (reportId == HIDPlusPlusProtocol.reportIDLong && data[2] == 0x8F) {
            // Device is asleep or offline
            if var existing = cachedDevices[slot] {
                existing.isOnline = false
                cachedDevices[slot] = existing
                emitDevices()
            }
            return
        }

        let featureIndex = data[2]
        let swId = data[3] & 0x0F

        // 1. Root Feature (0x00) Response: Feature Discovery correlated via software ID
        if featureIndex == 0x00 && data.count >= 5 {
            let foundIndex = data[4]

            if swId == HIDPlusPlusProtocol.swIdDeviceName {
                if foundIndex > 0 {
                    nameFeatureIndices[slot] = foundIndex
                    queryDeviceName(slot: slot, nameIdx: foundIndex, offset: 0)
                }
            } else if swId == HIDPlusPlusProtocol.swIdUnifiedBattery {
                if foundIndex > 0 {
                    batteryFeatureIndices[slot] = (index: foundIndex, type: .unified)
                    queryBattery(slot: slot, batIdx: foundIndex)
                } else {
                    // Unified battery unsupported -> fallback query to Legacy Battery (0x1000)
                    queryLegacyBatteryRoot(slot: slot)
                }
            } else if swId == HIDPlusPlusProtocol.swIdLegacyBattery {
                if foundIndex > 0 {
                    batteryFeatureIndices[slot] = (index: foundIndex, type: .legacy)
                    queryBattery(slot: slot, batIdx: foundIndex)
                }
            }
            return
        }

        // 2. Name Feature Response
        if let nameIdx = nameFeatureIndices[slot], featureIndex == nameIdx {
            if let chunk = HIDPlusPlusProtocol.parseDeviceNameChunk(response: data) {
                let deviceName = chunk.nameChunk.trimmingCharacters(in: .whitespacesAndNewlines)
                var current = cachedDevices[slot] ?? LogiDevice(
                    id: "bolt-slot-\(slot)",
                    slot: slot,
                    name: deviceName,
                    deviceType: inferDeviceType(name: deviceName),
                    batteryLevel: nil,
                    chargingStatus: .unknown,
                    isOnline: true,
                    lastSeen: Date()
                )

                if current.name.isEmpty || current.name.hasPrefix("Logitech Device") {
                    current.name = deviceName
                } else if current.name.count == 16 && !current.name.contains(deviceName) {
                    current.name += deviceName
                }

                if deviceName.count == 16 && current.name.count == 16 {
                    queryDeviceName(slot: slot, nameIdx: nameIdx, offset: 16)
                }

                current.deviceType = inferDeviceType(name: current.displayName)
                current.isOnline = true
                current.lastSeen = Date()
                cachedDevices[slot] = current
                emitDevices()
            }
            return
        }

        // 3. Battery Feature Response
        if let batInfo = batteryFeatureIndices[slot], featureIndex == batInfo.index {
            let parsed: (percentage: Int, status: LogiChargingStatus)?
            switch batInfo.type {
            case .unified:
                parsed = HIDPlusPlusProtocol.parseUnifiedBattery(response: data)
            case .legacy:
                parsed = HIDPlusPlusProtocol.parseLegacyBattery(response: data)
            }

            if let result = parsed {
                var current = cachedDevices[slot] ?? LogiDevice(
                    id: "bolt-slot-\(slot)",
                    slot: slot,
                    name: "Logitech Device \(slot)",
                    deviceType: .unknown,
                    batteryLevel: result.percentage,
                    chargingStatus: result.status,
                    isOnline: true,
                    lastSeen: Date()
                )
                current.batteryLevel = result.percentage
                current.chargingStatus = result.status
                current.isOnline = true
                current.lastSeen = Date()
                cachedDevices[slot] = current
                emitDevices()
            }
            return
        }
    }

    private func queryLegacyBatteryRoot(slot: UInt8) {
        guard let manager = hidManager,
              let dev = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first else { return }
        let query = HIDPlusPlusProtocol.makeFeatureQuery(
            deviceIndex: slot,
            featureId: HIDPlusPlusProtocol.featureBatteryLevelStatus,
            softwareId: HIDPlusPlusProtocol.swIdLegacyBattery
        )
        sendReport(to: dev, report: query)
    }

    private func queryDeviceName(slot: UInt8, nameIdx: UInt8, offset: UInt8 = 0) {
        guard let manager = hidManager,
              let dev = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first else { return }
        let query = HIDPlusPlusProtocol.makeDeviceNameQuery(deviceIndex: slot, nameFeatureIndex: nameIdx, offset: offset)
        sendReport(to: dev, report: query)
    }

    private func queryBattery(slot: UInt8, batIdx: UInt8) {
        guard let manager = hidManager,
              let dev = (IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice>)?.first else { return }
        let reqBat = HIDPlusPlusProtocol.makeBatteryStatusQuery(
            deviceIndex: slot,
            batteryFeatureIndex: batIdx,
            functionId: 0x10
        )
        sendReport(to: dev, report: reqBat)
    }

    private func inferDeviceType(name: String) -> LogiDeviceType {
        let lower = name.lowercased()
        if lower.contains("mouse") || lower.contains("master") || lower.contains("anywhere") || lower.contains("lift") {
            return .mouse
        } else if lower.contains("keyboard") || lower.contains("mechanical") || lower.contains("keys") || lower.contains("craft") || lower.contains("k") {
            return .keyboard
        }
        return .unknown
    }

    private func emitDevices() {
        let list = cachedDevices.values.sorted { $0.slot < $1.slot }
        onDevicesUpdated?(list)
    }
}
