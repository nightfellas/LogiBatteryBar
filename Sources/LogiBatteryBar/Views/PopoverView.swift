import SwiftUI

public struct PopoverView: View {
    @ObservedObject public var viewModel: BatteryStatusViewModel

    public init(viewModel: BatteryStatusViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(viewModel.isReceiverConnected ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text("Logitech Battery")
                        .font(.system(size: 13, weight: .bold))
                }

                Spacer()

                Button(action: {
                    viewModel.refresh()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11, weight: .medium))
                            .rotationEffect(.degrees(viewModel.isRefreshing ? 360 : 0))
                            .animation(viewModel.isRefreshing ? Animation.linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: viewModel.isRefreshing)
                        Text("Refresh")
                            .font(.system(size: 11))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
                }
                .buttonStyle(.plain)
                .help("Refresh battery levels (Right-click menu bar icon also refreshes)")
            }

            Divider()

            // Content
            if !viewModel.isReceiverConnected {
                VStack(spacing: 8) {
                    Image(systemName: "bolt.horizontal.slash.fill")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)
                    Text("Bolt Receiver Not Found")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Please connect your Logi Bolt USB receiver.")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else if viewModel.devices.isEmpty {
                VStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Scanning paired devices...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 10) {
                    ForEach(viewModel.devices) { device in
                        DeviceRowView(device: device)
                    }
                }
            }

            Divider()

            // Options & Status
            HStack {
                Toggle(isOn: Binding(
                    get: { viewModel.launchAtLogin },
                    set: { viewModel.setLaunchAtLogin($0) }
                )) {
                    Text("Start at Login")
                        .font(.system(size: 11))
                }
                .toggleStyle(.checkbox)

                Spacer()

                if let lastUpdated = viewModel.lastUpdated {
                    Text("Updated \(timeFormatted(lastUpdated))")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Footer
            HStack {
                Text(viewModel.isReceiverConnected ? "Logi Bolt Active" : "Receiver Disconnected")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Quit") {
                    AppDelegate.isUserQuitting = true
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
                .font(.system(size: 11))
                .foregroundColor(.secondary)
            }
        }
        .padding(14)
        .frame(width: 330)
    }

    private func timeFormatted(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}
