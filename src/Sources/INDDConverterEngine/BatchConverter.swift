import Foundation

/// Coordinates batch conversion of multiple INDD files with progress updates.
public final class BatchConverter: @unchecked Sendable {
    public private(set) var items: [ConversionItem] = []
    public var options: ConversionOptions

    private var isCancelled = false
    private let lock = NSLock()

    public init(options: ConversionOptions = ConversionOptions()) {
        self.options = options
    }

    /// Appends INDD files from individual URLs or recursively from directories.
    public func addInputs(_ urls: [URL]) {
        lock.lock()
        defer { lock.unlock() }

        var collected: [URL] = []
        let fileManager = FileManager.default

        for url in urls {
            var isDir: ObjCBool = false
            if fileManager.fileExists(atPath: url.path, isDirectory: &isDir) {
                if isDir.boolValue {
                    if let enumerator = fileManager.enumerator(at: url, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                        for case let fileURL as URL in enumerator {
                            let ext = fileURL.pathExtension.lowercased()
                            if ext == "indd" || ext == "indt" {
                                collected.append(fileURL)
                            }
                        }
                    }
                } else {
                    let ext = url.pathExtension.lowercased()
                    if ext == "indd" || ext == "indt" {
                        collected.append(url)
                    }
                }
            }
        }

        for fileURL in collected {
            // Avoid duplicates
            if !items.contains(where: { $0.inputURL.path == fileURL.path }) {
                let dest: URL
                if let customDir = options.customOutputDirectory {
                    dest = customDir.appendingPathComponent(fileURL.deletingPathExtension().lastPathComponent).appendingPathExtension("idml")
                } else {
                    dest = fileURL.deletingPathExtension().appendingPathExtension("idml")
                }
                items.append(ConversionItem(inputURL: fileURL, outputURL: dest))
            }
        }
    }

    /// Clears the current queue.
    public func clear() {
        lock.lock()
        defer { lock.unlock() }
        items.removeAll()
        isCancelled = false
    }

    /// Cancels ongoing batch processing.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
    }

    private func checkIsCancelled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }

    private func updateItemStatus(at index: Int, status: ConversionStatus) -> ConversionItem {
        lock.lock()
        defer { lock.unlock() }
        var item = items[index]
        item.status = status
        items[index] = item
        return item
    }

    private func getSnapshot() -> [ConversionItem] {
        lock.lock()
        defer { lock.unlock() }
        return items
    }

    private func resetAndGetTotal() -> Int {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = false
        return items.count
    }

    /// Processes all queued items in sequence.
    ///
    /// - Parameters:
    ///   - onItemUpdated: Callback invoked whenever an item's status changes.
    ///   - onCompleted: Callback invoked when the entire batch finishes.
    public func run(
        installation: InDesignInstallation? = nil,
        onItemUpdated: @Sendable @escaping (ConversionItem, Int, Int) -> Void,
        onCompleted: @Sendable @escaping ([ConversionItem]) -> Void
    ) async {
        let total = resetAndGetTotal()

        for i in 0..<total {
            if checkIsCancelled() {
                break
            }

            let item = updateItemStatus(at: i, status: .converting)
            onItemUpdated(item, i + 1, total)

            let startTime = Date()
            do {
                let out = try await InDesignBridge.shared.convert(
                    inputURL: item.inputURL,
                    outputURL: item.expectedOutputURL,
                    installation: installation,
                    timeoutSeconds: options.timeoutSeconds
                )
                let duration = Date().timeIntervalSince(startTime)
                let completedItem = updateItemStatus(at: i, status: .completed(outputURL: out, duration: duration))
                onItemUpdated(completedItem, i + 1, total)
            } catch {
                let failedItem = updateItemStatus(at: i, status: .failed(error: error.localizedDescription))
                onItemUpdated(failedItem, i + 1, total)
            }
        }

        onCompleted(getSnapshot())
    }
}
