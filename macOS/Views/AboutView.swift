import SwiftUI

struct AboutView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "sterlingsign.circle")
                .font(.system(size: 48))
                .foregroundStyle(.blue)

            Text("Money Monitor")
                .font(.title2.bold())

            Text("Version 1.0.0")
                .font(.caption)
                .foregroundStyle(.secondary)

            Text("Track and categorize your Halifax spending from the menu bar.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)

            Divider()

            Text("Copyright \u{00A9} 2026 bkawk")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(24)
        .frame(width: 300)
    }
}
