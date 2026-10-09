import SwiftUI
import INDDConverterEngine

struct HeaderView: View {
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.badge.gearshape.fill")
                .font(.system(size: 28))
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 2) {
                Text("INDD to IDML Converter")
                    .font(.headline)
                    .fontWeight(.bold)

                Text("Native macOS InDesign Batch Bridge")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Scan Mac for INDD files button
            Button(action: { state.showSearchSheet = true }) {
                Label("Scan Mac for .indd", systemImage: "magnifyingglass")
                    .font(.caption)
            }
            .buttonStyle(.bordered)
            .help("Search computer for all .indd documents")

            // InDesign Engine Indicator Pill
            HStack(spacing: 6) {
                Circle()
                    .fill(state.detectedInstallations.isEmpty ? Color.red : Color.green)
                    .frame(width: 8, height: 8)

                if let app = state.selectedInstallation {
                    Text(app.name)
                        .font(.caption)
                        .fontWeight(.medium)
                } else {
                    Text("InDesign Not Found")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Button(action: { state.refreshInstallations() }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.caption2)
                }
                .buttonStyle(.plain)
                .help("Refresh detected InDesign installations")
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
