import SwiftUI
import AppKit

public final class AppDelegate: NSObject, NSApplicationDelegate {
    public static var isUserQuitting = false

    public func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        if Self.isUserQuitting {
            return .terminateNow
        }
        return .terminateCancel
    }
}

@main
struct LogiBatteryBarApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var viewModel = BatteryStatusViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.menuBarTitle, isInserted: .constant(true)) {
            PopoverView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
