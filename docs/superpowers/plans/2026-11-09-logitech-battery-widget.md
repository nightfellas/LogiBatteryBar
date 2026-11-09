# Logitech MX Battery Menu Bar Widget Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS Menu Bar application that continuously monitors and displays live battery percentages and charging states for the Logitech MX Master 3S and MX Mechanical Mini via the Logi Bolt USB Receiver.

**Architecture:** A native Swift application running as an `LSUIElement` (menu bar status item) powered by an IOKit `IOHIDManager` service communicating via Logitech's HID++ 2.0 protocol over the Logi Bolt receiver, feeding an observable view model that renders a status bar item and a SwiftUI popover detail view.

**Tech Stack:** Swift 6, SwiftUI, AppKit, IOKit (`IOHIDManager`), Swift Package Manager (SPM).

**Spec:** `docs/superpowers/specs/2026-11-09-logitech-battery-widget-design.md`

## Global Constraints

- Platform: macOS 13.0+ (Ventura, Sonoma, Sequoia).
- Peripheral Target: Logitech MX Master 3S and MX Mechanical Mini paired via Logi Bolt USB Receiver (`VID 0x046D`, `PID 0xC548`).
- Non-exclusive access: Must open IOHIDDevice with `kIOHIDOptionsTypeNone` so mouse and keyboard input and Logi Options+ are never blocked.
- Packaging: Standalone `.app` bundle with `LSUIElement = true` (no Dock icon).
- Communication Protocol: Logitech HID++ 2.0 (Reports `0x10` short, `0x11` long; Features `0x0000`, `0x0005`, `0x1004`, `0x1000`).

## Review Focus

1. **Receiver Unplugged / Re-plugged:** App should not crash when the Logi Bolt receiver is disconnected; it should display `Receiver Disconnected` in the popover and automatically resume when plugged back in.
2. **Device in Deep Sleep:** When mouse or keyboard enters sleep mode, the query will timeout; the app must display the last known percentage with an inactive indicator rather than zero or an error.
3. **Feature 0x1004 vs. 0x1000 Fallback:** Some firmware revisions use Feature `0x1004` (Unified Battery) while older ones use Feature `0x1000` (Battery Level Status); parser must gracefully fallback if `0x1004` returns feature index 0.
4. **Charging State Transitions:** Device transitioning from Discharging to Charging (plugged in via USB-C cable) must accurately toggle the charging lightning bolt badge (`⚡`).
5. **Multiple Paired Slots:** Bolt receiver has slots 1–6; inactive/unpaired slots must be cleanly ignored without producing ghost devices.

---

## File Structure

```
widget/
├── Package.swift
├── build.sh
├── Sources/
│   └── LogiBatteryBar/
│       ├── main.swift
│       ├── App/
│       │   └── AppDelegate.swift
│       ├── Models/
│       │   └── LogiDevice.swift
│       ├── Services/
│       │   ├── HIDPlusPlusProtocol.swift
│       │   └── LogiBoltHIDService.swift
│       ├── ViewModels/
│       │   └── BatteryStatusViewModel.swift
│       └── Views/
│           ├── DeviceRowView.swift
│           └── PopoverView.swift
└── Tests/
    └── LogiBatteryBarTests/
        ├── HIDPlusPlusProtocolTests.swift
        └── BatteryStatusViewModelTests.swift
```

---

### Task 1: Project Scaffolding & Package Configuration

**Files:**
- Create: `Package.swift`
- Create: `build.sh`
- Create: `Sources/LogiBatteryBar/main.swift`
- Create: `Tests/LogiBatteryBarTests/SanityTests.swift`

**Interfaces:**
- Produces: Executable target `LogiBatteryBar` and test target `LogiBatteryBarTests`.

- [ ] **Step 1: Write the failing test**

```swift
// Tests/LogiBatteryBarTests/SanityTests.swift
import Testing

@Suite("Sanity Tests")
struct SanityTests {
    @Test("Package builds and test harness runs")
    func testSanity() {
        #expect(1 + 1 == 2)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test`  
Expected: FAIL (No Package.swift found)

- [ ] **Step 3: Implement `Package.swift` and initial entry points**

Create `Package.swift` configured for macOS 13+ with executable target `LogiBatteryBar` linking `IOKit` and SwiftUI, plus test target `LogiBatteryBarTests`. Create placeholder `Sources/LogiBatteryBar/main.swift` and `build.sh`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test`  
Expected: PASS (1 test passed)

- [ ] **Step 5: Commit**

```bash
git add Package.swift build.sh Sources/ Tests/
git commit -m "chore: scaffold Swift package and build script"
```

---

### Task 2: Data Models (`LogiDevice`)

**Files:**
- Create: `Sources/LogiBatteryBar/Models/LogiDevice.swift`
- Create: `Tests/LogiBatteryBarTests/LogiDeviceTests.swift`

**Interfaces:**
- Produces:
  - `enum LogiDeviceType: String, Codable, Sendable` (`.mouse`, `.keyboard`, `.unknown`)
  - `enum LogiChargingStatus: String, Codable, Sendable` (`.discharging`, `.charging`, `.full`, `.error`, `.unknown`)
  - `struct LogiDevice: Identifiable, Sendable, Equatable` properties:
    - `id: String` (slot identifier)
    - `slot: UInt8` (1...6)
    - `name: String`
    - `deviceType: LogiDeviceType`
    - `batteryLevel: Int?` (0-100)
    - `chargingStatus: LogiChargingStatus`
    - `isOnline: Bool`
    - `lastSeen: Date`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/LogiBatteryBarTests/LogiDeviceTests.swift
import Testing
@testable import LogiBatteryBar
import Foundation

@Suite("LogiDevice Model Tests")
struct LogiDeviceTests {
    @Test("LogiDevice initializes and formats display properties")
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
        #expect(device.name == "MX Master 3S")
        #expect(device.batteryLevel == 85)
        #expect(device.chargingStatus == .discharging)
        #expect(device.deviceType == .mouse)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LogiDeviceTests`  
Expected: FAIL (`cannot find 'LogiDevice' in scope`)

- [ ] **Step 3: Implement `LogiDevice.swift`**

Implement `LogiDeviceType`, `LogiChargingStatus`, and `LogiDevice` struct with helper computed properties (e.g., `batteryText: String`, `iconName: String`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LogiDeviceTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/LogiBatteryBar/Models/LogiDevice.swift Tests/LogiBatteryBarTests/LogiDeviceTests.swift
git commit -m "feat: implement LogiDevice model and status enums"
```

---

### Task 3: HID++ 2.0 Protocol Serialization & Parsing (`HIDPlusPlusProtocol`)

**Files:**
- Create: `Sources/LogiBatteryBar/Services/HIDPlusPlusProtocol.swift`
- Create: `Tests/LogiBatteryBarTests/HIDPlusPlusProtocolTests.swift`

**Interfaces:**
- Produces:
  - `struct HIDPlusPlusProtocol`:
    - `static func makeFeatureQuery(deviceIndex: UInt8, featureId: UInt16) -> [UInt8]`
    - `static func makeDeviceNameQuery(deviceIndex: UInt8, nameFeatureIndex: UInt8, offset: UInt8) -> [UInt8]`
    - `static func makeBatteryStatusQuery(deviceIndex: UInt8, batteryFeatureIndex: UInt8) -> [UInt8]`
    - `static func parseFeatureIndex(response: [UInt8]) -> UInt8?`
    - `static func parseDeviceNameChunk(response: [UInt8]) -> (nameChunk: String, nextOffset: UInt8)?`
    - `static func parseUnifiedBattery(response: [UInt8]) -> (percentage: Int, status: LogiChargingStatus)?`
    - `static func parseLegacyBattery(response: [UInt8]) -> (percentage: Int, status: LogiChargingStatus)?`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/LogiBatteryBarTests/HIDPlusPlusProtocolTests.swift
import Testing
@testable import LogiBatteryBar

@Suite("HID++ 2.0 Protocol Tests")
struct HIDPlusPlusProtocolTests {
    @Test("Make feature query request")
    func testMakeFeatureQuery() {
        let report = HIDPlusPlusProtocol.makeFeatureQuery(deviceIndex: 1, featureId: 0x1004)
        #expect(report.count == 20)
        #expect(report[0] == 0x11) // Long report ID
        #expect(report[1] == 1)    // Device index
        #expect(report[2] == 0x00) // Root feature
        #expect(report[3] == 0x00) // Function 0
        #expect(report[4] == 0x10) // Feature ID high
        #expect(report[5] == 0x04) // Feature ID low
    }

    @Test("Parse Unified Battery 0x1004 report")
    func testParseUnifiedBatteryReport() {
        // Mock response: reportId=0x11, devIndex=1, featureIdx=0x08, func=0x00, percentage=85, chargeStatus=1 (charging)
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x08
        response[4] = 85 // 85%
        response[6] = 0x01 // Charging
        
        let result = HIDPlusPlusProtocol.parseUnifiedBattery(response: response)
        #expect(result?.percentage == 85)
        #expect(result?.status == .charging)
    }

    @Test("Parse Legacy Battery 0x1000 report fallback")
    func testParseLegacyBatteryReport() {
        var response = [UInt8](repeating: 0, count: 20)
        response[0] = 0x11
        response[1] = 1
        response[2] = 0x07
        response[4] = 70 // 70%
        response[5] = 0x00 // Discharging
        
        let result = HIDPlusPlusProtocol.parseLegacyBattery(response: response)
        #expect(result?.percentage == 70)
        #expect(result?.status == .discharging)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter HIDPlusPlusProtocolTests`  
Expected: FAIL (`cannot find 'HIDPlusPlusProtocol' in scope`)

- [ ] **Step 3: Implement `HIDPlusPlusProtocol.swift`**

Implement HID++ 2.0 packet generators and parser functions according to the Logitech HID++ specifications for 20-byte long reports (`0x11`) and 7-byte short reports (`0x10`).

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter HIDPlusPlusProtocolTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/LogiBatteryBar/Services/HIDPlusPlusProtocol.swift Tests/LogiBatteryBarTests/HIDPlusPlusProtocolTests.swift
git commit -m "feat: implement HID++ 2.0 report generation and parsing"
```

---

### Task 4: IOKit HID Communication Service (`LogiBoltHIDService`)

**Files:**
- Create: `Sources/LogiBatteryBar/Services/LogiBoltHIDService.swift`
- Create: `Tests/LogiBatteryBarTests/LogiBoltHIDServiceTests.swift`

**Interfaces:**
- Produces:
  - `class LogiBoltHIDService`:
    - `var onDevicesUpdated: (([LogiDevice]) -> Void)?`
    - `var onConnectionStateChanged: ((Bool) -> Void)?`
    - `func startMonitoring()`
    - `func stopMonitoring()`
    - `func refreshDevices()`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/LogiBatteryBarTests/LogiBoltHIDServiceTests.swift
import Testing
@testable import LogiBatteryBar

@Suite("LogiBoltHIDService Tests")
struct LogiBoltHIDServiceTests {
    @Test("LogiBoltHIDService can be instantiated and managed")
    func testServiceInit() {
        let service = LogiBoltHIDService()
        #expect(service != nil)
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter LogiBoltHIDServiceTests`  
Expected: FAIL (`cannot find 'LogiBoltHIDService' in scope`)

- [ ] **Step 3: Implement `LogiBoltHIDService.swift`**

Implement `LogiBoltHIDService` using `IOHIDManager`:
- Match Logitech Bolt Receiver: `kIOHIDVendorIDKey: 0x046D`, `kIOHIDProductIDKey: 0xC548`, `kIOHIDPrimaryUsagePageKey: 0xFF00`, `kIOHIDPrimaryUsageKey: 0x0001`.
- Set matching and removal callbacks for USB plug/unplug events.
- Open device non-exclusively with `kIOHIDOptionsTypeNone`.
- For each paired slot index (1 to 6):
  - Send feature query for `0x0005` (`DEVICE_NAME_AND_TYPE`). If unresponsive or slot empty, skip.
  - Send feature query for `0x1004` (`UNIFIED_BATTERY`) or fallback `0x1000` (`BATTERY_LEVEL_STATUS`).
  - Send battery query to feature index, parse percentage and charging state.
  - Emit populated `[LogiDevice]` list on the main thread via `onDevicesUpdated`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter LogiBoltHIDServiceTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/LogiBatteryBar/Services/LogiBoltHIDService.swift Tests/LogiBatteryBarTests/LogiBoltHIDServiceTests.swift
git commit -m "feat: implement LogiBoltHIDService with IOKit matching and HID++ querying"
```

---

### Task 5: View Model & State Management (`BatteryStatusViewModel`)

**Files:**
- Create: `Sources/LogiBatteryBar/ViewModels/BatteryStatusViewModel.swift`
- Create: `Tests/LogiBatteryBarTests/BatteryStatusViewModelTests.swift`

**Interfaces:**
- Consumes: `LogiDevice`, `LogiBoltHIDService`
- Produces:
  - `@MainActor class BatteryStatusViewModel: ObservableObject`:
    - `@Published var devices: [LogiDevice]`
    - `@Published var isReceiverConnected: Bool`
    - `@Published var isRefreshing: Bool`
    - `@Published var lastUpdated: Date?`
    - `var menuBarTitle: String`
    - `func refresh()`

- [ ] **Step 1: Write the failing test**

```swift
// Tests/LogiBatteryBarTests/BatteryStatusViewModelTests.swift
import Testing
@testable import LogiBatteryBar
import Foundation

@Suite("BatteryStatusViewModel Tests")
@MainActor
struct BatteryStatusViewModelTests {
    @Test("Menu bar title formats with both mouse and keyboard")
    func testMenuBarTitleWithTwoDevices() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = true
        vm.devices = [
            LogiDevice(id: "1", slot: 1, name: "MX Master 3S", deviceType: .mouse, batteryLevel: 85, chargingStatus: .discharging, isOnline: true, lastSeen: Date()),
            LogiDevice(id: "2", slot: 2, name: "MX Mechanical Mini", deviceType: .keyboard, batteryLevel: 90, chargingStatus: .discharging, isOnline: true, lastSeen: Date())
        ]
        #expect(vm.menuBarTitle == "🖱️ 85%  ⌨️ 90%")
    }

    @Test("Menu bar title shows charging indicator")
    func testMenuBarTitleCharging() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = true
        vm.devices = [
            LogiDevice(id: "1", slot: 1, name: "MX Master 3S", deviceType: .mouse, batteryLevel: 45, chargingStatus: .charging, isOnline: true, lastSeen: Date())
        ]
        #expect(vm.menuBarTitle.contains("⚡"))
    }

    @Test("Menu bar title indicates disconnected receiver")
    func testMenuBarTitleDisconnected() {
        let vm = BatteryStatusViewModel(autoStart: false)
        vm.isReceiverConnected = false
        #expect(vm.menuBarTitle == "⚡ Logi (Off)")
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `swift test --filter BatteryStatusViewModelTests`  
Expected: FAIL (`cannot find 'BatteryStatusViewModel' in scope`)

- [ ] **Step 3: Implement `BatteryStatusViewModel.swift`**

Implement `BatteryStatusViewModel` conforming to `ObservableObject`, wired to `LogiBoltHIDService`, managing the 60-second periodic timer, and computing `menuBarTitle`.

- [ ] **Step 4: Run test to verify it passes**

Run: `swift test --filter BatteryStatusViewModelTests`  
Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add Sources/LogiBatteryBar/ViewModels/BatteryStatusViewModel.swift Tests/LogiBatteryBarTests/BatteryStatusViewModelTests.swift
git commit -m "feat: implement BatteryStatusViewModel with menu bar formatting"
```

---

### Task 6: SwiftUI Popover & Device Card Views

**Files:**
- Create: `Sources/LogiBatteryBar/Views/DeviceRowView.swift`
- Create: `Sources/LogiBatteryBar/Views/PopoverView.swift`

**Interfaces:**
- Consumes: `BatteryStatusViewModel`, `LogiDevice`
- Produces:
  - `struct DeviceRowView: View`
  - `struct PopoverView: View`

- [ ] **Step 1: Implement `DeviceRowView.swift`**

Create `DeviceRowView` displaying:
- Device icon (`mouse.fill` or `keyboard.fill`)
- Device name (`MX Master 3S`, `MX Mechanical Mini`)
- Battery bar gauge (colored green/yellow/red depending on percentage)
- Exact percentage badge
- Charging status indicator (`⚡ Charging`, `On Battery`)

- [ ] **Step 2: Implement `PopoverView.swift`**

Create `PopoverView` hosting:
- Header: App Title ("Logi Bolt Devices"), manual refresh button with spinning state
- Content: `VStack` of `DeviceRowView` for connected devices, or empty state if receiver is unplugged
- Footer: Connection badge (Bolt Receiver), last updated timestamp, and "Quit" button (`NSApplication.shared.terminate(nil)`)
- Frame fixed width ~280pt for standard macOS popovers

- [ ] **Step 3: Verify build and compile**

Run: `swift build`  
Expected: Build succeeds with 0 errors.

- [ ] **Step 4: Commit**

```bash
git add Sources/LogiBatteryBar/Views/
git commit -m "feat: implement SwiftUI PopoverView and DeviceRowView"
```

---

### Task 7: macOS Menu Bar Controller & App Entry Point

**Files:**
- Create: `Sources/LogiBatteryBar/App/AppDelegate.swift`
- Modify: `Sources/LogiBatteryBar/main.swift`
- Modify: `build.sh`

**Interfaces:**
- Consumes: `BatteryStatusViewModel`, `PopoverView`
- Produces: Standalone macOS application bundle `LogiBatteryBar.app` with `NSStatusItem`.

- [ ] **Step 1: Implement `AppDelegate.swift`**

Create `AppDelegate` conforming to `NSApplicationDelegate`:
- Set up `NSStatusItem` in `NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)`
- Bind `viewModel.$menuBarTitle` to update `statusItem.button?.title`
- Configure `NSPopover` hosting `PopoverView(viewModel: viewModel)`
- Toggle popover visibility on `statusItem.button` click
- Start `viewModel.startMonitoring()`

- [ ] **Step 2: Implement `main.swift`**

Set up `NSApplication.shared`, attach delegate `AppDelegate()`, and run `app.run()`.

- [ ] **Step 3: Implement `build.sh`**

Script that:
1. Executes `swift build -c release`
2. Creates `.build/LogiBatteryBar.app/Contents/MacOS` and `Contents/Resources`
3. Generates `Info.plist` with `CFBundleIdentifier`, `CFBundleName`, `CFBundleVersion`, and `LSUIElement = true`
4. Copies compiled binary into `Contents/MacOS/LogiBatteryBar`
5. Codesigns ad-hoc with `codesign -s - --force LogiBatteryBar.app`
6. Copies `LogiBatteryBar.app` to `./LogiBatteryBar.app` for one-click launching

- [ ] **Step 4: Execute `build.sh` and verify live execution**

Run: `./build.sh`  
Expected: `Build succeeded! Generated LogiBatteryBar.app`

- [ ] **Step 5: Commit**

```bash
git add Sources/LogiBatteryBar/App/AppDelegate.swift Sources/LogiBatteryBar/main.swift build.sh
git commit -m "feat: implement NSStatusItem controller, app delegate, and build packaging script"
```

---

### Task 8: Live Hardware Verification & End-to-End Validation

**Files:**
- Test with connected hardware: Logi Bolt Receiver, MX Master 3S, MX Mechanical Mini

- [ ] **Step 1: Run all automated unit tests**

Run: `swift test`  
Expected: All tests PASS.

- [ ] **Step 2: Launch `LogiBatteryBar.app` and verify live telemetry**

Launch the application binary in background, query standard output or check status bar:
Verify:
1. `LogiBoltHIDService` detects Logi Bolt USB Receiver (`0xC548`).
2. Slot 1 and Slot 2 report "MX Master 3S" and "MX Mechanical Mini".
3. Battery percentages reflect actual levels matching Logi Options+.
4. Clicking status bar icon displays popover without errors.

- [ ] **Step 3: Document usage and instructions in `README.md`**

Create `README.md` explaining:
- Features
- How to build (`./build.sh`)
- How to run or add to Login Items
- Troubleshooting tips

- [ ] **Step 4: Final commit**

```bash
git add README.md
git commit -m "docs: add README with build and usage instructions"
```
