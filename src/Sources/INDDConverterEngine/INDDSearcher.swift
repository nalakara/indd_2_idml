import Foundation

public enum SearchScope: Sendable, Equatable {
    case commonFolders
    case homeDirectory
    case custom(URL)

    public var title: String {
        switch self {
        case .commonFolders: return "Common Locations (Desktop, Documents, Downloads)"
        case .homeDirectory: return "Entire Home Folder"
        case .custom(let url): return "Folder: \(url.lastPathComponent)"
        }
    }
}

/// Searches the computer for Adobe InDesign (.indd / .indt) documents.
public final class INDDSearcher: @unchecked Sendable {
    public static let shared = INDDSearcher()

    private var isCancelled = false
    private let lock = NSLock()

    // Common directories that should be skipped to prevent slow traversals
    private let skippedDirectoryNames: Set<String> = [
        "Library", ".Trash", "node_modules", ".git", ".build", "Pods",
        "DerivedData", ".gradle", ".cargo", "Cache", "Caches", ".npm"
    ]

    public init() {}

    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = true
    }

    private func checkCancelled() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return isCancelled
    }

    private func resetSearchState() {
        lock.lock()
        defer { lock.unlock() }
        isCancelled = false
    }

    /// Performs a non-blocking asynchronous search for InDesign files.
    ///
    /// - Parameters:
    ///   - scope: The target area to search.
    ///   - onFileFound: Callback fired immediately whenever an INDD file is found.
    /// - Returns: Complete list of all discovered files.
    public func search(
        scope: SearchScope = .commonFolders,
        onFileFound: (@Sendable (DiscoveredFile) -> Void)? = nil
    ) async -> [DiscoveredFile] {
        resetSearchState()

        var results: [DiscoveredFile] = []
        var seenPaths = Set<String>()

        let rootURLs: [URL]
        switch scope {
        case .commonFolders:
            let home = FileManager.default.homeDirectoryForCurrentUser
            rootURLs = [
                home.appendingPathComponent("Downloads"),
                home.appendingPathComponent("Documents"),
                home.appendingPathComponent("Desktop"),
                home.appendingPathComponent("Creative Cloud Files")
            ].filter { FileManager.default.fileExists(atPath: $0.path) }

        case .homeDirectory:
            rootURLs = [FileManager.default.homeDirectoryForCurrentUser]

        case .custom(let url):
            rootURLs = [url]
        }

        for root in rootURLs {
            if checkCancelled() { break }
            scanDirectory(
                url: root,
                seenPaths: &seenPaths,
                results: &results,
                onFileFound: onFileFound
            )
        }

        return results.sorted { $0.fileName.localizedStandardCompare($1.fileName) == .orderedAscending }
    }

    private func scanDirectory(
        url: URL,
        seenPaths: inout Set<String>,
        results: inout [DiscoveredFile],
        onFileFound: (@Sendable (DiscoveredFile) -> Void)?
    ) {
        let fileManager = FileManager.default
        let resourceKeys: [URLResourceKey] = [.isDirectoryKey, .nameKey]

        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true }
        ) else {
            return
        }

        for case let fileURL as URL in enumerator {
            if checkCancelled() {
                enumerator.skipDescendants()
                break
            }

            // Check if we should skip heavy directory subtrees
            if let resourceValues = try? fileURL.resourceValues(forKeys: [.isDirectoryKey, .nameKey]),
               let isDir = resourceValues.isDirectory, isDir {
                if let name = resourceValues.name, skippedDirectoryNames.contains(name) {
                    enumerator.skipDescendants()
                }
                continue
            }

            let ext = fileURL.pathExtension.lowercased()
            if ext == "indd" || ext == "indt" {
                let standardPath = fileURL.standardizedFileURL.path
                if !seenPaths.contains(standardPath) {
                    seenPaths.insert(standardPath)
                    let discovered = DiscoveredFile(url: fileURL)
                    results.append(discovered)
                    onFileFound?(discovered)
                }
            }
        }
    }
}
