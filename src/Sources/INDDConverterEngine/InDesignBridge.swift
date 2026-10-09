import Foundation

public enum InDesignBridgeError: LocalizedError {
    case inDesignNotInstalled
    case fileNotFound(URL)
    case outputCreationFailed(String)
    case scriptExecutionFailed(String)
    case executionTimeout
    case unexpectedResponse(String)

    public var errorDescription: String? {
        switch self {
        case .inDesignNotInstalled:
            return "Adobe InDesign is not installed on this Mac. Please install Adobe InDesign to enable conversion."
        case .fileNotFound(let url):
            return "Source INDD file does not exist at: \(url.path)"
        case .outputCreationFailed(let msg):
            return "Failed to prepare output destination: \(msg)"
        case .scriptExecutionFailed(let msg):
            return "InDesign export failed: \(msg)"
        case .executionTimeout:
            return "Conversion timed out while waiting for InDesign to process the document."
        case .unexpectedResponse(let res):
            return "Unexpected response from InDesign bridge: \(res)"
        }
    }
}

/// Executes silent conversion from INDD to IDML through Adobe InDesign automation.
public final class InDesignBridge: Sendable {
    public static let shared = InDesignBridge()

    public init() {}

    /// Converts a single INDD document to IDML format.
    ///
    /// - Parameters:
    ///   - inputURL: The source .indd file URL.
    ///   - outputURL: The destination .idml file URL.
    ///   - installation: An optional specific InDesign installation to use.
    ///   - timeoutSeconds: Maximum seconds before aborting.
    /// - Returns: A URL pointing to the created .idml file.
    @discardableResult
    public func convert(
        inputURL: URL,
        outputURL: URL,
        installation: InDesignInstallation? = nil,
        timeoutSeconds: TimeInterval = 120.0
    ) async throws -> URL {
        guard FileManager.default.fileExists(atPath: inputURL.path) else {
            throw InDesignBridgeError.fileNotFound(inputURL)
        }

        // Determine target InDesign application
        let targetApp: InDesignInstallation
        if let inst = installation {
            targetApp = inst
        } else {
            let detected = InDesignDetector.shared.detectInstallations()
            guard let first = detected.first else {
                throw InDesignBridgeError.inDesignNotInstalled
            }
            targetApp = first
        }

        // Ensure parent directory for output exists
        let outputDir = outputURL.deletingLastPathComponent()
        do {
            try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
        } catch {
            throw InDesignBridgeError.outputCreationFailed(error.localizedDescription)
        }

        // Clean existing destination file if present
        if FileManager.default.fileExists(atPath: outputURL.path) {
            try? FileManager.default.removeItem(at: outputURL)
        }

        let script = generateExtendScriptPayload(
            appName: targetApp.name,
            inputPath: inputURL.path,
            outputPath: outputURL.path
        )

        try await executeScript(script: script, timeoutSeconds: timeoutSeconds)

        // Verify output file exists and is not empty
        guard FileManager.default.fileExists(atPath: outputURL.path) else {
            throw InDesignBridgeError.scriptExecutionFailed("Output IDML was not created by InDesign.")
        }

        let attributes = try? FileManager.default.attributesOfItem(atPath: outputURL.path)
        let size = attributes?[.size] as? Int64 ?? 0
        guard size > 100 else {
            throw InDesignBridgeError.scriptExecutionFailed("Generated IDML is empty or truncated (\(size) bytes).")
        }

        return outputURL
    }

    /// Generates an AppleScript wrapper calling InDesign ExtendScript.
    /// This method guarantees silent opening, dialog suppression, and clean exit.
    public func generateExtendScriptPayload(appName: String, inputPath: String, outputPath: String) -> String {
        let escapedInput = inputPath
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")

        let escapedOutput = outputPath
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "'", with: "\\'")
            .replacingOccurrences(of: "\"", with: "\\\"")

        // InDesign ExtendScript DOM provides universal cross-version support
        let jsBody = """
        app.scriptPreferences.userInteractionLevel = UserInteractionLevels.NEVER_INTERACT;
        var srcFile = new File("\(escapedInput)");
        if (!srcFile.exists) {
            throw new Error("Input file does not exist: " + "\(escapedInput)");
        }
        var doc = app.open(srcFile, false);
        var destFile = new File("\(escapedOutput)");
        doc.exportFile(ExportFormat.INDESIGN_XML, destFile, false);
        doc.close(SaveOptions.NO);
        app.scriptPreferences.userInteractionLevel = UserInteractionLevels.INTERACT_WITH_ALL;
        "SUCCESS";
        """

        // Wrap into AppleScript tell block
        let escapedJS = jsBody
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")

        return """
        tell application "\(appName)"
            try
                set jsCode to "\(escapedJS)"
                set scriptResult to do script jsCode language javascript
                return scriptResult
            on error errMsg number errNum
                try
                    do script "app.scriptPreferences.userInteractionLevel = UserInteractionLevels.INTERACT_WITH_ALL;" language javascript
                end try
                error errMsg number errNum
            end try
        end tell
        """
    }

    private func executeScript(script: String, timeoutSeconds: TimeInterval) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
            process.arguments = ["-e", script]

            let outPipe = Pipe()
            let errPipe = Pipe()
            process.standardOutput = outPipe
            process.standardError = errPipe

            final class CompletionBox: @unchecked Sendable {
                private var completed = false
                private let lock = NSLock()
                func executeOnce(_ action: () -> Void) {
                    lock.lock()
                    defer { lock.unlock() }
                    if !completed {
                        completed = true
                        action()
                    }
                }
            }

            let box = CompletionBox()

            // Setup watchdog timer for timeout
            let timer = DispatchSource.makeTimerSource(queue: .global())
            timer.schedule(deadline: .now() + timeoutSeconds)
            timer.setEventHandler {
                box.executeOnce {
                    process.terminate()
                    continuation.resume(throwing: InDesignBridgeError.executionTimeout)
                }
            }
            timer.resume()

            process.terminationHandler = { proc in
                timer.cancel()
                box.executeOnce {
                    let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
                    let errString = String(data: errData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    let outData = outPipe.fileHandleForReading.readDataToEndOfFile()
                    let outString = String(data: outData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                    if proc.terminationStatus == 0 && (outString.contains("SUCCESS") || errString.isEmpty) {
                        continuation.resume()
                    } else {
                        let message = errString.isEmpty ? outString : errString
                        continuation.resume(throwing: InDesignBridgeError.scriptExecutionFailed(message.isEmpty ? "Process exited with code \(proc.terminationStatus)" : message))
                    }
                }
            }

            do {
                try process.run()
            } catch {
                timer.cancel()
                box.executeOnce {
                    continuation.resume(throwing: InDesignBridgeError.scriptExecutionFailed(error.localizedDescription))
                }
            }
        }
    }
}
