import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var state: AppState
    @State private var isTargeted: Bool = false

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(isTargeted ? Color.accentColor.opacity(0.15) : Color.secondary.opacity(0.08))
                    .frame(width: 80, height: 80)

                Image(systemName: isTargeted ? "arrow.down.doc.fill" : "arrow.down.doc")
                    .font(.system(size: 34))
                    .foregroundColor(isTargeted ? .accentColor : .secondary)
            }
            .animation(.easeInOut(duration: 0.2), value: isTargeted)

            VStack(spacing: 6) {
                Text("Drag & Drop InDesign Files Here")
                    .font(.title3)
                    .fontWeight(.semibold)

                Text("Supports .indd and .indt documents or entire folders")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            HStack(spacing: 12) {
                Button(action: selectFiles) {
                    Label("Choose Files...", systemImage: "doc.badge.plus")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.borderedProminent)

                Button(action: selectFolder) {
                    Label("Choose Folder...", systemImage: "folder.badge.plus")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)

                Button(action: { state.showSearchSheet = true }) {
                    Label("Scan Computer...", systemImage: "magnifyingglass")
                        .padding(.horizontal, 6)
                        .padding(.vertical, 4)
                }
                .buttonStyle(.bordered)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(
                    isTargeted ? Color.accentColor : Color.secondary.opacity(0.3),
                    style: StrokeStyle(lineWidth: 2, dash: [8, 6])
                )
                .background(isTargeted ? Color.accentColor.opacity(0.04) : Color.clear)
        )
        .padding(20)
        .onDrop(of: [.fileURL], isTargeted: $isTargeted) { providers in
            handleDrop(providers: providers)
            return true
        }
    }

    private func handleDrop(providers: [NSItemProvider]) {
        for provider in providers {
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url = url {
                    DispatchQueue.main.async {
                        state.addFiles([url])
                    }
                }
            }
        }
    }

    private func selectFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        panel.allowedContentTypes = [UTType(filenameExtension: "indd") ?? .item, UTType(filenameExtension: "indt") ?? .item]
        panel.prompt = "Add to Queue"
        if panel.runModal() == .OK {
            state.addFiles(panel.urls)
        }
    }

    private func selectFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Scan Folder"
        if panel.runModal() == .OK, let url = panel.url {
            state.addFiles([url])
        }
    }
}
