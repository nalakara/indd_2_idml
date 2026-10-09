import SwiftUI
import INDDConverterEngine

struct QueueListView: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 0) {
            // Queue Table Header / Summary
            HStack {
                Text("\(state.items.count) document(s) in queue")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)

                Spacer()

                if !state.isConverting {
                    Button("Clear All", action: state.clearQueue)
                        .buttonStyle(.plain)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.6))

            Divider()

            // List of Conversion Items
            ScrollView {
                LazyVStack(spacing: 8) {
                    ForEach(state.items) { item in
                        QueueItemRow(item: item, state: state)
                    }
                }
                .padding(16)
            }

            Divider()

            // Bottom Control Toolbar
            BottomControlBar(state: state)
        }
    }
}

struct QueueItemRow: View {
    let item: ConversionItem
    @ObservedObject var state: AppState

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.fill")
                .foregroundColor(.accentColor)
                .font(.system(size: 20))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.fileName)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text("\(item.fileSizeDescription) • \(item.inputURL.deletingLastPathComponent().path)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            // Status Indicator
            statusBadge(for: item.status)

            // Actions
            if case .completed(let outputURL, _) = item.status {
                Button(action: { NSWorkspace.shared.activateFileViewerSelecting([outputURL]) }) {
                    Image(systemName: "magnifyingglass.circle.fill")
                        .font(.system(size: 16))
                }
                .buttonStyle(.plain)
                .help("Show converted IDML in Finder")
            } else if !state.isConverting {
                Button(action: { state.removeItem(id: item.id) }) {
                    Image(systemName: "xmark.circle")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(10)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
    }

    @ViewBuilder
    private func statusBadge(for status: ConversionStatus) -> some View {
        switch status {
        case .queued:
            Text("Waiting")
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(6)

        case .converting:
            HStack(spacing: 4) {
                ProgressView()
                    .controlSize(.small)
                Text("Exporting")
                    .font(.caption2)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.orange.opacity(0.15))
            .foregroundColor(.orange)
            .cornerRadius(6)

        case .completed(_, let duration):
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                Text(String(format: "%.1fs", duration))
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.green.opacity(0.15))
            .foregroundColor(.green)
            .cornerRadius(6)

        case .failed(let err):
            HStack(spacing: 4) {
                Image(systemName: "exclamationmark.triangle.fill")
                Text("Failed")
            }
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.red.opacity(0.15))
            .foregroundColor(.red)
            .cornerRadius(6)
            .help(err)
        }
    }
}

struct BottomControlBar: View {
    @ObservedObject var state: AppState

    var body: some View {
        VStack(spacing: 12) {
            // Output Directory Preference
            HStack(spacing: 10) {
                if !state.useCustomOutputDirectory {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        Text("Output: Same folder as source file (alongside each .indd)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Button("Use Custom Folder...") {
                        state.selectCustomOutputFolder()
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.accentColor)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "folder.badge.gearshape")
                            .foregroundColor(.accentColor)
                            .font(.caption)
                        Text("Custom folder: \(state.customOutputDirectory?.path ?? "None")")
                            .font(.caption)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button("Change...", action: state.selectCustomOutputFolder)
                        .buttonStyle(.bordered)
                        .controlSize(.small)

                    Button("Reset to Source Folder") {
                        state.useCustomOutputDirectory = false
                        state.customOutputDirectory = nil
                    }
                    .buttonStyle(.plain)
                    .font(.caption)
                    .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 4)

            if state.isConverting {
                VStack(alignment: .leading, spacing: 4) {
                    ProgressView(value: state.overallProgress)
                        .progressViewStyle(.linear)

                    HStack {
                        Text(state.currentItemName.isEmpty ? "Preparing..." : "Converting: \(state.currentItemName)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(Int(state.overallProgress * 100))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // Action Buttons
            HStack {
                Text(state.statusMessage)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if state.isConverting {
                    Button("Cancel", action: state.cancelConversion)
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.cancelAction)
                } else {
                    Button(action: state.startConversion) {
                        Label("Convert All", systemImage: "arrow.triangle.2.circlepath")
                            .frame(minWidth: 100)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(state.items.isEmpty || state.detectedInstallations.isEmpty)
                    .keyboardShortcut(.defaultAction)
                }
            }
        }
        .padding(16)
        .background(Color(NSColor.windowBackgroundColor))
    }
}
