import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var model: MoneyMonitorModel
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var isImporting = false

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "sterlingsign.circle")
                .font(.system(size: 64))
                .foregroundStyle(.blue)

            Text("Welcome to Money Monitor")
                .font(.title.bold())

            Text("Track and categorize your spending from the menu bar. Import your Halifax bank transactions as CSV to get started.")
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 8) {
                Label("Log into Halifax online banking", systemImage: "1.circle")
                Label("Go to your account and click \"Download\"", systemImage: "2.circle")
                Label("Select CSV format and download", systemImage: "3.circle")
                Label("Import the file below", systemImage: "4.circle")
            }
            .font(.callout)
            .padding()
            .background(.secondary.opacity(0.1))
            .cornerRadius(8)

            HStack(spacing: 12) {
                Button("Import CSV") {
                    isImporting = true
                }
                .buttonStyle(.borderedProminent)

                Button("Skip for Now") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding(32)
        .frame(width: 460, height: 420)
        .fileImporter(
            isPresented: $isImporting,
            allowedContentTypes: [.commaSeparatedText],
            allowsMultipleSelection: false
        ) { result in
            if case .success(let urls) = result, let url = urls.first {
                guard url.startAccessingSecurityScopedResource() else { return }
                defer { url.stopAccessingSecurityScopedResource() }
                model.importCSV(url: url)
                hasCompletedOnboarding = true
            }
        }
    }
}
