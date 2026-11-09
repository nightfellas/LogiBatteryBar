import SwiftUI

@main
struct LogiBatteryBarApp: App {
    @StateObject private var viewModel = BatteryStatusViewModel()

    var body: some Scene {
        MenuBarExtra(viewModel.menuBarTitle) {
            PopoverView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}
