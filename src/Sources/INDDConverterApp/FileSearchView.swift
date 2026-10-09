import SwiftUI
import INDDConverterEngine

struct FileSearchView: View {
    @ObservedObject var state: AppState
    @State private var filterQuery: String = ""
    @State private var selectedScope: SearchScope = .commonFolders

    var filteredResults: [DiscoveredFile] {
        if filterQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return state.searchResults
        }
        return state.searchResults.filter {
            $0.fileName.localizedCaseInsensitiveContains(filterQuery) ||
            $0.directoryPath.localizedCaseInsensitiveContains(filterQuery)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "magnifyingglass.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.accentColor)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Search InDesign Documents on Mac")
                        .font(.headline)
                        .fontWeight(.bold)
                    Text("Find all .indd and .indt files on your computer and add them to the conversion queue")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(action: { state.showSearchSheet = false }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))

            Divider()

            // Scope and Trigger Controls
            HStack(spacing: 12) {
                Menu {
                    Button("Common Locations (Downloads, Documents, Desktop)") {
                        selectedScope = .commonFolders
                        state.startSearch(scope: .commonFolders)
                    }
                    Button("Entire Home Folder (~/)") {
                        selectedScope = .homeDirectory
                        state.startSearch(scope: .homeDirectory)
                    }
                    Button("Choose Custom Folder...") {
                        selectCustomFolderToSearch()
                    }
                } label: {
                    Label(selectedScope.title, systemImage: "folder")
                        .lineLimit(1)
                }
                .frame(maxWidth: 320)

                if state.isSearching {
                    Button(action: state.cancelSearch) {
                        Label("Stop", systemImage: "stop.circle")
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button(action: { state.startSearch(scope: selectedScope) }) {
                        Label("Search Now", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.borderedProminent)
                }

                Spacer()

                // Filter textfield
                HStack {
                    Image(systemName: "line.3.horizontal.decrease.circle")
                        .foregroundColor(.secondary)
                    TextField("Filter results...", text: $filterQuery)
                        .textFieldStyle(.plain)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(6)
                .frame(width: 180)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(NSColor.controlBackgroundColor).opacity(0.5))

            Divider()

            // Status Bar
            HStack {
                if state.isSearching {
                    ProgressView()
                        .controlSize(.small)
                }
                Text(state.searchStatusText.isEmpty ? "Select a scope and click 'Search Now' to find INDD files." : state.searchStatusText)
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                if !state.searchResults.isEmpty {
                    Button("Select All", action: state.selectAllSearchResults)
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)

                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Button("Deselect All", action: state.deselectAllSearchResults)
                        .font(.caption2)
                        .buttonStyle(.plain)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 6)

            Divider()

            // Results List
            if state.searchResults.isEmpty && !state.isSearching {
                VStack(spacing: 12) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 40))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("No InDesign files discovered yet")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("Click 'Search Now' to scan your Mac")
                        .font(.caption)
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(32)
            } else {
                List {
                    ForEach(filteredResults) { file in
                        let isSelected = state.selectedDiscoveredFileIDs.contains(file.id)
                        HStack(spacing: 10) {
                            Button(action: { state.toggleFileSelection(id: file.id) }) {
                                Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                    .foregroundColor(isSelected ? .accentColor : .secondary)
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.plain)

                            Image(systemName: "doc.fill")
                                .foregroundColor(.orange)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(file.fileName)
                                    .font(.body)
                                    .fontWeight(.medium)

                                Text("\(file.fileSizeDescription) • \(file.directoryPath)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }

                            Spacer()

                            Button(action: {
                                NSWorkspace.shared.activateFileViewerSelecting([file.url])
                            }) {
                                Image(systemName: "arrow.up.right.square")
                                    .font(.system(size: 14))
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                            .help("Show in Finder")
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.inset)
            }

            Divider()

            // Footer Toolbar
            HStack {
                let count = state.selectedDiscoveredFileIDs.count
                Text("\(count) of \(state.searchResults.count) selected")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Spacer()

                Button("Cancel", action: { state.showSearchSheet = false })
                    .buttonStyle(.bordered)

                Button(action: state.addSelectedSearchResultsToQueue) {
                    Label("Add to Queue (\(count))", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
                .disabled(count == 0)
            }
            .padding(16)
            .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 640, minHeight: 460)
        .onAppear {
            if state.searchResults.isEmpty {
                state.startSearch(scope: .commonFolders)
            }
        }
    }

    private func selectCustomFolderToSearch() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Folder to Scan"
        if panel.runModal() == .OK, let url = panel.url {
            selectedScope = .custom(url)
            state.startSearch(scope: selectedScope)
        }
    }
}
