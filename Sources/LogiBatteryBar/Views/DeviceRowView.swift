import SwiftUI

public struct DeviceRowView: View {
    public let device: LogiDevice

    public init(device: LogiDevice) {
        self.device = device
    }

    private var batteryColor: Color {
        guard let level = device.batteryLevel else { return .secondary }
        if level <= 15 {
            return .red
        } else if level <= 30 {
            return .orange
        } else {
            return .green
        }
    }

    private var timeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: device.lastSeen)
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header Row: Icon + Name + Battery Pill
            HStack(alignment: .center, spacing: 10) {
                // Device Icon
                ZStack {
                    Circle()
                        .fill(Color.accentColor.opacity(0.12))
                        .frame(width: 32, height: 32)
                    Image(systemName: device.iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.accentColor)
                }

                // Name & Slot
                VStack(alignment: .leading, spacing: 2) {
                    Text(device.displayName)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.primary)

                    HStack(spacing: 5) {
                        Text("Slot \(device.slot)")
                            .font(.system(size: 10, weight: .medium))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(Color.secondary.opacity(0.15))
                            .cornerRadius(3)

                        Text("•")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)

                        Text("Logi Bolt")
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer(minLength: 8)

                // Battery Pill Badge
                HStack(spacing: 4) {
                    Image(systemName: device.batterySymbolName)
                        .font(.system(size: 12, weight: .medium))
                    Text(device.batteryText)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                }
                .foregroundColor(batteryColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(batteryColor.opacity(0.12))
                .cornerRadius(6)
            }

            // Battery Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.secondary.opacity(0.2))
                        .frame(height: 5)

                    if let level = device.batteryLevel {
                        Capsule()
                            .fill(batteryColor)
                            .frame(width: max(0, min(geometry.size.width * CGFloat(level) / 100.0, geometry.size.width)), height: 5)
                    }
                }
            }
            .frame(height: 5)

            // Status Sub-row
            HStack {
                if device.chargingStatus.isCharging {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("Charging via USB")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.primary)
                    }
                } else if !device.isOnline {
                    HStack(spacing: 4) {
                        Image(systemName: "moon.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                        Text("Standby (Idle)")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 9))
                            .foregroundColor(.green.opacity(0.8))
                        Text("Connected")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Text(device.isOnline ? "Active" : "Last seen \(timeString)")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.secondary.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
