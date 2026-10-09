import Foundation

/// Represents an installation of Adobe InDesign discovered on macOS.
public struct InDesignInstallation: Identifiable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let appPath: URL
    public let bundleIdentifier: String
    public let version: String?

    public init(name: String, appPath: URL, bundleIdentifier: String, version: String? = nil) {
        self.id = bundleIdentifier.isEmpty ? appPath.path : bundleIdentifier
        self.name = name
        self.appPath = appPath
        self.bundleIdentifier = bundleIdentifier
        self.version = version
    }
}

/// The state of an individual conversion item in the queue.
public enum ConversionStatus: Equatable, Sendable {
    case queued
    case converting
    case completed(outputURL: URL, duration: TimeInterval)
    case failed(error: String)

    public var title: String {
        switch self {
        case .queued: return "Queued"
        case .converting: return "Converting..."
        case .completed: return "Done"
        case .failed: return "Failed"
        }
    }
}

/// A task representing an INDD file to be converted to IDML.
public struct ConversionItem: Identifiable, Sendable {
    public let id: UUID
    public let inputURL: URL
    public let expectedOutputURL: URL
    public var status: ConversionStatus

    public init(id: UUID = UUID(), inputURL: URL, outputURL: URL? = nil, status: ConversionStatus = .queued) {
        self.id = id
        self.inputURL = inputURL
        if let outputURL = outputURL {
            self.expectedOutputURL = outputURL
        } else {
            // Default to same directory with .idml extension
            let destination = inputURL.deletingPathExtension().appendingPathExtension("idml")
            self.expectedOutputURL = destination
        }
        self.status = status
    }

    public var fileName: String {
        inputURL.lastPathComponent
    }

    public var fileSizeDescription: String {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: inputURL.path),
              let size = attrs[.size] as? Int64 else {
            return "Unknown size"
        }
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: size)
    }
}

/// Overall batch conversion configuration options.
public struct ConversionOptions: Sendable {
    public var customOutputDirectory: URL?
    public var overwriteExisting: Bool
    public var timeoutSeconds: TimeInterval

    public init(
        customOutputDirectory: URL? = nil,
        overwriteExisting: Bool = true,
        timeoutSeconds: TimeInterval = 120.0
    ) {
        self.customOutputDirectory = customOutputDirectory
        self.overwriteExisting = overwriteExisting
        self.timeoutSeconds = timeoutSeconds
    }
}

/// Represents an INDD file discovered during a computer search.
public struct DiscoveredFile: Identifiable, Sendable, Equatable, Hashable {
    public let id: String
    public let url: URL
    public let fileName: String
    public let directoryPath: String
    public let fileSize: Int64
    public let modificationDate: Date?

    public init(url: URL) {
        self.id = url.path
        self.url = url
        self.fileName = url.lastPathComponent
        self.directoryPath = url.deletingLastPathComponent().path
        let attrs = try? FileManager.default.attributesOfItem(atPath: url.path)
        self.fileSize = attrs?[.size] as? Int64 ?? 0
        self.modificationDate = attrs?[.modificationDate] as? Date
    }

    public var fileSizeDescription: String {
        let formatter = ByteCountFormatter()
        formatter.allowedUnits = [.useKB, .useMB, .useGB]
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}

