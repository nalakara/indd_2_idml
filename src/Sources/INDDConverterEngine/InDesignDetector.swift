import Foundation
import AppKit

/// Scans macOS for installed Adobe InDesign versions.
public final class InDesignDetector: Sendable {
    public static let shared = InDesignDetector()

    public init() {}

    /// Scans standard macOS directories and LaunchServices for Adobe InDesign installations.
    public func detectInstallations() -> [InDesignInstallation] {
        var results: [InDesignInstallation] = []
        var seenPaths = Set<String>()

        // 1. Direct search in /Applications and /Applications/Adobe InDesign [Year]
        let fileManager = FileManager.default
        let appDirs = [
            URL(fileURLWithPath: "/Applications", isDirectory: true),
            URL(fileURLWithPath: (NSHomeDirectory() as NSString).appendingPathComponent("Applications"), isDirectory: true)
        ]

        for baseDir in appDirs {
            guard let contents = try? fileManager.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) else {
                continue
            }

            for item in contents {
                // If it's directly an Adobe InDesign .app
                if item.pathExtension == "app" && item.lastPathComponent.localizedCaseInsensitiveContains("InDesign") {
                    addInstallation(from: item, into: &results, seenPaths: &seenPaths)
                }
                // If it's a folder like "/Applications/Adobe InDesign 2024"
                else if item.hasDirectoryPath && item.lastPathComponent.localizedCaseInsensitiveContains("InDesign") {
                    if let subContents = try? fileManager.contentsOfDirectory(at: item, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles]) {
                        for subItem in subContents where subItem.pathExtension == "app" && subItem.lastPathComponent.localizedCaseInsensitiveContains("InDesign") {
                            addInstallation(from: subItem, into: &results, seenPaths: &seenPaths)
                        }
                    }
                }
            }
        }

        // 2. Query Spotlight using mdfind for bundle identifier pattern
        let spotlightPaths = runMdfind()
        for path in spotlightPaths {
            let url = URL(fileURLWithPath: path)
            addInstallation(from: url, into: &results, seenPaths: &seenPaths)
        }

        // 3. Query LaunchServices for known bundle identifier
        if let defaultURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.adobe.InDesign") {
            addInstallation(from: defaultURL, into: &results, seenPaths: &seenPaths)
        }

        // Sort by version/name descending so newest appears first
        return results.sorted { $0.name > $1.name }
    }

    /// Checks if any InDesign process is currently running.
    public func isRunning(installation: InDesignInstallation? = nil) -> Bool {
        let runningApps = NSWorkspace.shared.runningApplications
        if let inst = installation, !inst.bundleIdentifier.isEmpty {
            return runningApps.contains { $0.bundleIdentifier == inst.bundleIdentifier }
        }
        return runningApps.contains { app in
            app.bundleIdentifier?.localizedCaseInsensitiveContains("indesign") == true ||
            app.localizedName?.localizedCaseInsensitiveContains("indesign") == true
        }
    }

    private func addInstallation(from appURL: URL, into list: inout [InDesignInstallation], seenPaths: inout Set<String>) {
        let standardPath = appURL.standardizedFileURL.path
        guard !seenPaths.contains(standardPath) else { return }
        guard FileManager.default.fileExists(atPath: standardPath) else { return }

        seenPaths.insert(standardPath)
        let bundle = Bundle(url: appURL)
        let bundleId = bundle?.bundleIdentifier ?? "com.adobe.InDesign"
        let version = bundle?.infoDictionary?["CFBundleShortVersionString"] as? String
        let displayName = bundle?.infoDictionary?["CFBundleDisplayName"] as? String
            ?? bundle?.infoDictionary?["CFBundleName"] as? String
            ?? appURL.deletingPathExtension().lastPathComponent

        list.append(InDesignInstallation(
            name: displayName,
            appPath: appURL,
            bundleIdentifier: bundleId,
            version: version
        ))
    }

    private func runMdfind() -> [String] {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/mdfind")
        process.arguments = ["kMDItemContentType == 'com.apple.application-bundle' && kMDItemFSName == '*InDesign*.app'"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                return output.components(separatedBy: .newlines).filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            }
        } catch {
            // Ignore mdfind failures
        }
        return []
    }
}
