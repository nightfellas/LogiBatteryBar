# Design Document: Logitech MX Battery Menu Bar Widget for macOS

**Date:** 2026-11-09  
**Status:** Approved by Reviewer & Ready for User Sign-off  
**Author:** Pair programming session (Antigravity & nightwalker)  

---

## 1. Intent & Context

The user operates a Mac workstation equipped with Logitech peripherals:
- **Mouse:** Logitech MX Master 3S
- **Keyboard:** Logitech MX Mechanical Mini
- **Connectivity:** Both devices are connected via a single **Logi Bolt USB Receiver** (VID `0x046D`, PID `0xC548`).

macOS native desktop battery widgets and control center do not display battery telemetry from devices connected via proprietary USB receivers like the Logi Bolt. While the official Logi Options+ application is installed, it lacks a lightweight, persistent status bar indicator showing real-time battery percentages without opening the main window.

The intent of this project is to create a lightweight, native macOS Menu Bar application that continuously monitors and displays the precise battery percentages, charging states, and connection statuses of the user's Logitech devices directly from the Logi Bolt receiver.

---

## 2. Goals, Non-Goals, & Anti-Goals

### Goals
- **Real-Time Menu Bar Display:** Show concise battery indicators for both mouse and keyboard directly in the macOS menu bar (e.g. `🖱️ 85%  ⌨️ 90%`).
- **Interactive Detail Popover:** Clicking the status item reveals a SwiftUI popover showing:
  - Device names and models (MX Master 3S, MX Mechanical Mini).
  - Visual battery gauges (color-coded: green > 20%, yellow 10-20%, red < 10%).
  - Power/Charging state (Discharging, Charging, Fully Charged).
  - Connection mode: Logi Bolt Receiver (paired slot number).
  - Manual "Refresh Now" button and quick quit option.
- **Native Direct Communication:** Query battery telemetry directly using Logitech's **HID++ 2.0** protocol via macOS IOKit (`IOHIDManager`) targeting the Logi Bolt receiver interface.
- **Low Overhead:** Zero perceptible CPU/RAM footprint, event-driven report listening combined with low-frequency polling (every 60 seconds).
- **Zero Config Setup:** Automatically detects paired devices on the Logi Bolt receiver on launch without requiring manual pairing or Bluetooth TCC permissions.

### Non-Goals
- Direct Bluetooth Low Energy (BLE) connection in v1 (both devices are confirmed connected via Logi Bolt).
- Device configuration, button remapping, DPI customization, or macro management (these remain handled by Logi Options+).
- Cloud synchronization, accounts, or telemetry reporting.
- Non-Logitech third-party devices.

### Anti-Goals
- Exclusive device seizing: The app must NEVER seize or lock the HID devices (`kIOHIDOptionsTypeNone`), ensuring keyboard and mouse input as well as Logi Options+ function normally without interference.
- High battery drain or aggressive polling loops.

---

## 3. Approaches Considered & Selected

1. **Approach 1: Native macOS Menu Bar App (Swift & SwiftUI with IOKit HID++) [SELECTED]**
   - *Description:* A native menu bar utility (`NSStatusItem`) that queries the Bolt receiver interface using IOKit HID++ protocols.
   - *Trade-offs:* Sits in the menu bar rather than on the desktop surface, but offers zero-friction constant visibility, minimal battery consumption, and native system integration.
   - *Selection Reason:* Picked by user for convenience, direct visibility, and accessibility during daily workflow.

2. **Approach 2: Native Desktop Widget (WidgetKit + Background Helper)**
   - *Description:* A WidgetKit widget for macOS Desktop/Notification Center backed by a background daemon.
   - *Trade-offs:* Requires a background daemon anyway because WidgetKit cannot open USB/HID interfaces directly; widgets are frequently covered by open app windows.

3. **Approach 3: Floating Desktop HUD / Overlay Window**
   - *Description:* A transparent floating window pinned to desktop corners.
   - *Trade-offs:* Clutters workspace and feels less native to macOS compared to standard menu bar items.

---

## 4. Architecture & Technical Design

### 4.1 System Overview
```
┌────────────────────────────────────────────────────────┐
│                      macOS App                         │
│                                                        │
│  ┌───────────────────────┐  ┌───────────────────────┐  │
│  │   MenuBarController   │  │    PopoverView (UI)   │  │
│  │    (NSStatusItem)     │  │       (SwiftUI)       │  │
│  └───────────┬───────────┘  └───────────┬───────────┘  │
│              │                          │              │
│              ▼                          ▼              │
│  ┌──────────────────────────────────────────────────┐  │
│  │             BatteryStatusViewModel               │  │
│  └──────────────────────────┬───────────────────────┘  │
│                             │                          │
│                             ▼                          │
│  ┌──────────────────────────────────────────────────┐  │
│  │             LogiBoltHIDService                   │  │
│  │       (IOKit IOHIDManager & HID++ 2.0)           │  │
│  └──────────────────────────┬───────────────────────┘  │
└─────────────────────────────┼──────────────────────────┘
                              │ IOKit HID Reports
                              ▼
        ┌───────────────────────────────────────────┐
        │  Logitech Bolt USB Receiver (VID 0x046D)  │
        │               (PID 0xC548)                │
        └───────────────────────────────────────────┘
```

### 4.2 HID++ 2.0 Protocol Specifications for Logi Bolt
- **Vendor ID:** `0x046D` (Logitech)
- **Logi Bolt Receiver Product ID:** `0xC548`
- **Usage Page:** `0xFF00` (Vendor-defined HID++) / Usage `0x0001`
- **Device Indexing:** The Logi Bolt receiver maps paired wireless devices to indices `1` through `6`.
- **HID++ Report Format:**
  - Short report (Report ID `0x10`, 7 bytes)
  - Long report (Report ID `0x11`, 20 bytes)
  - Structure: `[Report ID, Device Index, Feature Index, Function ID | Software ID, Params...]`
- **HID++ Features Used:**
  - `0x0000` (Root Feature): Enumerate feature tables per device index.
  - `0x0005` (`DEVICE_NAME_AND_TYPE`): Retrieve product friendly name (e.g. "MX Master 3S", "MX Mechanical Mini") and device type (keyboard, mouse).
  - `0x1004` (`UNIFIED_BATTERY`) / fallback `0x1000` (`BATTERY_LEVEL_STATUS`):
    - Exact percentage (0–100%)
    - Charging Status (Discharging, Charging, Full, Charge Error)
    - External power connection flag

### 4.3 App Lifecycle & Packaging
- Built with **Swift Package Manager (SPM)** into a native macOS app bundle (`.app`).
- Configured as an `LSUIElement = true` (agent application with no Dock icon, menu bar only).
- Background polling timer: updates every 60 seconds, plus immediate updates on system wake or user-triggered refresh.

---

## 5. Implementation Details & Decisions Made

1. **Scope Boundary:** v1 strictly targets the **Logi Bolt USB Receiver** (`0xC548`), avoiding unnecessary Bluetooth permission dialogs and GATT complexity.
2. **Device State Handling:** If a device is in sleep mode, the UI displays the last-known battery percentage with a subtle inactive/dimmed badge and last-seen timestamp.
3. **Menu Bar Representation:** Formatted as `🖱️ [X]%  ⌨️ [Y]%` with an option in the popover to toggle between emoji and compact SF Symbols.
4. **Build & Run Convenience:** A lightweight build script (`./build.sh`) will compile the Swift package and generate a ready-to-run `LogiBatteryBar.app` inside the project root, which can also be copied directly to `/Applications`.
