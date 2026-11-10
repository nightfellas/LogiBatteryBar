# 🔋 LogiBatteryBar for macOS

<p align="center">
  <b>A lightweight native macOS Menu Bar widget to monitor battery levels of Logitech devices (MX Master 3S & MX Mechanical Mini) in real time via the Logi Bolt USB Receiver.</b>
</p>

---

## 📌 Problem Background

On macOS (Ventura, Sonoma, Sequoia, and later), Apple's built-in battery widget only displays standard Bluetooth devices (such as AirPods, Magic Mouse, and Magic Keyboard). When connecting Logitech peripherals through a **Logi Bolt USB Receiver**, macOS **cannot read or display battery percentages** on the desktop or in Control Center.

The official Logitech Options+ software is resource-heavy, consumes significant background memory, and lacks a compact, persistent percentage indicator directly in the Menu Bar.

**LogiBatteryBar** solves this problem: a 100% native, ultra-lightweight macOS application (zero external frameworks or dependencies) communicating directly with the Logi Bolt receiver hardware via the **HID++ 2.0** protocol.

---

## ✨ Key Features

- 🖱️ **Glanceable Menu Bar Indicator:**
  Always visible without interrupting your workflow:
!([https://github.com](https://i.ibb.co.com/4w3k4g5h/Screenshot-2026-11-10-at-11-39-50.png))

  ```
  🖱️ 75%   ⌨️ 80%
  ```
- ⚡ **Charging Detection:**
  Automatically displays a lightning icon `⚡` when a mouse or keyboard is charging via USB-C cable.
- 💤 **Smart Sleep / Idle Detection:**
  Detects when peripherals enter RF deep sleep mode to conserve battery. The last known valid battery percentage is retained and marked with `(zZ)` / `Standby (Idle)`. The moment a key or button is pressed, the status instantly returns to active.
- 🫧 **Native SwiftUI Popover Bubble Window:**
  Clicking the menu bar indicator opens a clean, modern macOS popover card showing:
  - **Full Device Names:** e.g., `MX Master 3S` and `MX Mechanical Mini`.
  - **Logi Bolt Slot Assignment:** Slot identification (`Slot 1 • Logi Bolt`, `Slot 5 • Logi Bolt`).
  - **Dynamic Battery Badges:** Adaptive battery level icon and color coding (*Green > 30%*, *Orange 15–30%*, *Red < 15%*).
  - **Visual Progress Bars.**
  - **Power & Connection State:** `⚡ Charging via USB`, `✓ Connected`, or `💤 Standby (Idle)`.
  - **Telemetry Timestamp:** Last updated time (`Updated 10:50:35`).
- 🚀 **Built-in "Start at Login" Toggle:**
  Enable or disable auto-start directly inside the popover UI with one click, utilizing modern macOS `ServiceManagement` (`SMAppService`).
- 🔄 **Quick Refresh Options:**
  - Click the **Refresh** button inside the popover window.
  - Right-click the menu bar text to trigger a silent background poll.
- 🌿 **Ultra-Low Battery & Resource Footprint:**
  Scheduled background polling every 60 seconds with instant wake updates (`NSWorkspace.didWakeNotification`).
- 🔒 **Safe Shared Access (`kIOHIDOptionsTypeNone`):**
  Uses non-exclusive IOKit access, allowing input events and companion tools (like Logi Options+) to coexist smoothly without hardware contention.
- 🎨 **macOS Retina App Icon:**
  Includes a native high-resolution squircle application icon compatible with Finder, Launchpad, and System Settings.

---

## 🖥️ System Requirements

| Component | Minimum Specification |
| :--- | :--- |
| **Operating System** | macOS 13.0 (Ventura), macOS 14.0 (Sonoma), macOS 15.0 (Sequoia), macOS Tahoe, or later |
| **Architecture** | Apple Silicon (M1, M2, M3, M4) & Intel (`x86_64`) / Hackintosh |
| **Hardware** | **Logi Bolt USB Receiver** (Product ID `0xC548` / Vendor ID `0x046D`) |
| **Supported Devices** | Logitech MX Master 3S, MX Mechanical / Mini, MX Keys S, MX Anywhere 3S, and all Bolt-compatible devices |
| **Build Tools** | Xcode Command Line Tools (`swift`, `clang`) |

---

## 🛠️ Build & Installation Guide

### Step 1: Compile the App Bundle

1. Open **Terminal** on your Mac.
2. Navigate to the project directory:
   ```bash
   cd /Users/nightwalker/Documents/Projects/widget
   ```
3. Run the automated build script:
   ```bash
   ./build.sh
   ```
   *This compiles the Swift code with release optimization (`swift build -c release`), constructs the `LogiBatteryBar.app` bundle, sets up `AppIcon.icns`, configures `Info.plist`, and applies ad-hoc code signing.*

---

### Step 2: Install to `/Applications`

To install the app alongside your system applications:
```bash
cp -R LogiBatteryBar.app /Applications/
```

Launch the application:
```bash
open /Applications/LogiBatteryBar.app
```
The battery indicators will appear immediately on the top-right Menu Bar.

---

### Step 3: Enable "Start at Login"

You can enable auto-start when your Mac turns on in two ways:

1. **In-App (Recommended):**
   - Click the battery indicator in the menu bar to open the popover card.
   - Simply check the **"Start at Login"** checkbox.
2. **Via macOS System Settings:**
   - Go to **System Settings > General > Login Items**.
   - Under **Open at Login**, ensure `LogiBatteryBar` is listed.

---

## 🧭 Daily Usage Tips

- **Quick Glance:** View percentages at a glance on the Menu Bar (e.g., `🖱️ 75%  ⌨️ 80%`).
- **Detailed Card:** Click on the percentage text to open the details bubble.
- **Fast Manual Refresh:** Right-click the menu bar text or click the **Refresh** button inside the card.
- **Quit Application:** Click the **Quit** button at the bottom-right corner of the popover card.

---

## 🏗️ Architecture Overview

```
widget/
├── Package.swift                         # Swift Package Manager manifest (macOS 13+)
├── build.sh                              # Release build, icon packaging & bundle script
├── README.md                             # Comprehensive documentation (English)
├── Resources/
│   └── AppIcon.icns                      # Retina macOS app icon (16x16 to 1024x1024)
├── scripts/
│   └── generate_icon.swift               # CoreGraphics/AppKit iconset generator script
├── Sources/
│   └── LogiBatteryBar/
│       ├── App/
│       │   └── LogiBatteryBarApp.swift   # SwiftUI @main entry point with MenuBarExtra (.window)
│       ├── Models/
│       │   └── LogiDevice.swift          # Device model, types, and battery/charging state
│       ├── Services/
│       │   ├── HIDPlusPlusProtocol.swift # Logitech HID++ 2.0 packet serializer & parser
│       │   ├── LogiBoltHIDService.swift  # IOKit HIDManager Bolt dongle communication
│       │   └── LaunchAtLoginService.swift# Modern ServiceManagement (SMAppService) auto-start
│       ├── ViewModels/
│       │   └── BatteryStatusViewModel.swift # Observable State, periodic polling & formatters
│       └── Views/
│           ├── DeviceRowView.swift       # Individual device card with SF Symbols & progress bar
│           └── PopoverView.swift         # Popup bubble window container with settings
└── Tests/
    └── LogiBatteryBarTests/              # 14 automated unit tests (XCTest)
```

---

## ❓ Frequently Asked Questions (FAQ) & Troubleshooting

#### 1. Why does the menu bar display `⚡ Logi (Off)`?
This status indicates that the Logi Bolt USB Receiver dongle was not detected in any USB port.
- **Solution:** Ensure the Logi Bolt USB receiver is plugged into an active USB port or powered USB hub.

#### 2. Why does the keyboard show `Standby (Idle)` when not typing?
Wireless Logitech keyboards (such as the MX Mechanical Mini) feature an aggressive RF sleep timer to maximize battery life when keys are not pressed.
- **Solution:** This is normal and expected behavior. The app retains the last known battery level. The moment any key is pressed, the status automatically switches back to `Connected`.

#### 3. Does this app conflict with Logitech Options+?
Not at all. `LogiBatteryBar` accesses the device using non-exclusive shared IOKit flags (`kIOHIDOptionsTypeNone`). Official software like Logi Options+ continues to work seamlessly alongside it for custom button mapping, gesture controls, and DPI adjustment.

#### 4. Is this app compatible with Hackintosh?
Yes. The app runs completely in user space and utilizes Apple's standard `IOKit.hid` and `SwiftUI` APIs without requiring custom kexts, root privileges, or disabling SIP.

#### 5. How do I uninstall the app?
1. Uncheck "Start at Login" in the popover card (or remove it from **System Settings > General > Login Items**).
2. Click **Quit** in the popover card.
3. Delete `/Applications/LogiBatteryBar.app`.

---

## 📄 License

This project is licensed under the **MIT License** — free to use, modify, and distribute.
