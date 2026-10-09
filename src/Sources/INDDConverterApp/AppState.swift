import SwiftUI
import AppKit
import INDDConverterEngine

@MainActor
public final class AppState: ObservableObject {
    // Queue and conversion states
    @Published public var items: [ConversionItem] = []
    @Published public var isConverting: Bool = false
    @Published public var overallProgress: Double = 0.0
    @Published public var currentItemName: String = ""
    @Published public var detectedInstallations: [InDesignInstallation] = []
    @Published public var selectedInstallation: InDesignInstallation?
    @Published public var useCustomOutputDirectory: Bool = false
    @Published public var customOutputDirectory: URL?
    @Published public var statusMessage: String = ""

    // InDesign Search feature states
    @Published public var showSearchSheet: Bool = false
    @Published public var isSearching: Bool = false
    @Published public var searchResults: [DiscoveredFile] = []
    @Published public var selectedDiscoveredFileIDs: Set<String> = []
    @Published public var searchStatusText: String = ""
    @Published public var currentSearchScope: SearchScope = .commonFolders

    private let batchConverter = BatchConverter()

    public init() {
        refreshInstallations()
    }

    public func refreshInstallations() {
        let list = InDesignDetector.shared.detectInstallations()
        self.detectedInstallations = list
        self.selectedInstallation = list.first
        if list.isEmpty {
            self.statusMessage = "Adobe InDesign not found. Please install InDesign to run conversions."
        } else {
            self.statusMessage = "Ready with \(list.first?.name ?? "InDesign")"
        }
    }

    public func addFiles(_ urls: [URL]) {
        // By default, useCustomOutputDirectory is false, so each file is converted
        // directly alongside its source file in the exact same folder!
        batchConverter.options.customOutputDirectory = useCustomOutputDirectory ? customOutputDirectory : nil
        batchConverter.addInputs(urls)
        self.items = batchConverter.items
    }

    public func removeItem(id: UUID) {
        items.removeAll { $0.id == id }
    }

    public func clearQueue() {
        batchConverter.clear()
        self.items = []
        self.overallProgress = 0.0
        self.currentItemName = ""
    }

    public func startConversion() {
        guard !items.isEmpty, !isConverting else { return }
        guard let app = selectedInstallation else {
            statusMessage = "Cannot start: No Adobe InDesign installation detected."
            return
        }

        isConverting = true
        statusMessage = "Converting..."
        overallProgress = 0.0

        batchConverter.options.customOutputDirectory = useCustomOutputDirectory ? customOutputDirectory : nil

        Task {
            await batchConverter.run(
                installation: app,
                onItemUpdated: { [weak self] updatedItem, current, total in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        if let idx = self.items.firstIndex(where: { $0.id == updatedItem.id }) {
                            self.items[idx] = updatedItem
                        }
                        self.currentItemName = updatedItem.fileName
                        self.overallProgress = Double(current) / Double(total)
                    }
                },
                onCompleted: { [weak self] finalItems in
                    Task { @MainActor [weak self] in
                        guard let self = self else { return }
                        self.items = finalItems
                        self.isConverting = false
                        let successCount = finalItems.filter { if case .completed = $0.status { return true }; return false }.count
                        let failCount = finalItems.count - successCount
                        self.statusMessage = "Completed: \(successCount) succeeded\(failCount > 0 ? ", \(failCount) failed" : "")."
                    }
                }
            )
        }
    }

    public func cancelConversion() {
        batchConverter.cancel()
        isConverting = false
        statusMessage = "Conversion cancelled."
    }

    public func selectCustomOutputFolder() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose Destination"
        if panel.runModal() == .OK, let url = panel.url {
            self.customOutputDirectory = url
            self.useCustomOutputDirectory = true
        }
    }

    // MARK: - InDesign Computer Search
    public func startSearch(scope: SearchScope) {
        self.currentSearchScope = scope
        self.isSearching = true
        self.searchResults = []
        self.selectedDiscoveredFileIDs = []
        self.searchStatusText = "Scanning for .indd files..."

        Task {
            let found = await INDDSearcher.shared.search(scope: scope) { [weak self] file in
                Task { @MainActor [weak self] in
                    guard let self = self else { return }
                    self.searchResults.append(file)
                    // Auto-select discovered file by default
                    self.selectedDiscoveredFileIDs.insert(file.id)
                    self.searchStatusText = "Found \(self.searchResults.count) InDesign document(s)..."
                }
            }

            self.isSearching = false
            self.searchStatusText = "Scan complete. Found \(found.count) document(s)."
        }
    }

    public func cancelSearch() {
        INDDSearcher.shared.cancel()
        self.isSearching = false
        self.searchStatusText = "Scan cancelled."
    }

    public func toggleFileSelection(id: String) {
        if selectedDiscoveredFileIDs.contains(id) {
            selectedDiscoveredFileIDs.remove(id)
        } else {
            selectedDiscoveredFileIDs.insert(id)
        }
    }

    public func selectAllSearchResults() {
        selectedDiscoveredFileIDs = Set(searchResults.map { $0.id })
    }

    public func deselectAllSearchResults() {
        selectedDiscoveredFileIDs.removeAll()
    }

    public func addSelectedSearchResultsToQueue() {
        let selectedURLs = searchResults
            .filter { selectedDiscoveredFileIDs.contains($0.id) }
            .map { $0.url }
        if !selectedURLs.isEmpty {
            addFiles(selectedURLs)
        }
        showSearchSheet = false
    }
}
