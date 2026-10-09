import Foundation
import INDDConverterEngine

@main
struct CLI {
    static func main() async {
        let args = CommandLine.arguments

        if args.contains("-h") || args.contains("--help") || args.count < 2 {
            printUsage()
            exit(0)
        }

        if args.contains("--list-indesign") {
            let apps = InDesignDetector.shared.detectInstallations()
            if apps.isEmpty {
                print("No Adobe InDesign installation detected in /Applications or LaunchServices.")
            } else {
                print("Found \(apps.count) Adobe InDesign installation(s):")
                for app in apps {
                    let versionInfo = app.version.map { " (v\($0))" } ?? ""
                    print("  • \(app.name)\(versionInfo) at \(app.appPath.path)")
                }
            }
            exit(0)
        }

        var customOutPath: String?
        var inputPaths: [String] = []
        var shouldScan = false
        var shouldConvertScan = false
        var idx = 1

        while idx < args.count {
            let arg = args[idx]
            if arg == "-o" || arg == "--output" {
                if idx + 1 < args.count {
                    customOutPath = args[idx + 1]
                    idx += 2
                    continue
                } else {
                    fputs("Error: Missing argument for \(arg)\n", stderr)
                    exit(1)
                }
            } else if arg == "--find" || arg == "--scan" {
                shouldScan = true
            } else if arg == "--convert" {
                shouldConvertScan = true
            } else if !arg.hasPrefix("-") {
                inputPaths.append(arg)
            }
            idx += 1
        }

        // Handle computer scan option
        if shouldScan {
            print("Scanning computer for InDesign (.indd / .indt) files in user folders...")
            let found = await INDDSearcher.shared.search(scope: .commonFolders)
            if found.isEmpty {
                print("No InDesign files found in common user locations (Downloads, Documents, Desktop).")
                exit(0)
            } else {
                print("Discovered \(found.count) InDesign document(s):")
                for f in found {
                    print("  • \(f.fileName) (\(f.fileSizeDescription)) in \(f.directoryPath)")
                }
            }

            if !shouldConvertScan {
                print("\nTip: Pass '--find --convert' to convert all discovered files.")
                exit(0)
            }

            // Append found paths for batch processing
            inputPaths.append(contentsOf: found.map { $0.url.path })
        }

        guard !inputPaths.isEmpty else {
            fputs("Error: No input .indd files or directories specified.\n", stderr)
            exit(1)
        }

        let installedApps = InDesignDetector.shared.detectInstallations()
        guard let defaultApp = installedApps.first else {
            fputs("Error: Adobe InDesign is not installed on this Mac.\n", stderr)
            fputs("Please install Adobe InDesign before running conversion.\n", stderr)
            exit(1)
        }

        print("Using engine: \(defaultApp.name)")

        var options = ConversionOptions()
        if let outPath = customOutPath {
            options.customOutputDirectory = URL(fileURLWithPath: outPath)
            print("Output directory: \(outPath)")
        } else {
            print("Output mode: Saved alongside each source file (.idml in same folder as .indd)")
        }

        let batch = BatchConverter(options: options)
        let urls = inputPaths.map { URL(fileURLWithPath: $0) }
        batch.addInputs(urls)

        guard !batch.items.isEmpty else {
            fputs("No valid .indd or .indt files found at specified input path(s).\n", stderr)
            exit(1)
        }

        print("Found \(batch.items.count) document(s) to convert.")

        await batch.run(
            installation: defaultApp,
            onItemUpdated: { item, current, total in
                switch item.status {
                case .converting:
                    print("[\(current)/\(total)] Converting \(item.fileName)...", terminator: "")
                    fflush(stdout)
                case .completed(_, let duration):
                    print(" Done (\(String(format: "%.1f", duration))s) -> \(item.expectedOutputURL.path)")
                case .failed(let err):
                    print(" FAILED")
                    fputs("  Error: \(err)\n", stderr)
                case .queued:
                    break
                }
            },
            onCompleted: { items in
                let successful = items.filter { if case .completed = $0.status { return true }; return false }.count
                let failed = items.count - successful
                print("\nBatch Complete: \(successful) succeeded, \(failed) failed.")
                exit(failed > 0 ? 1 : 0)
            }
        )
    }

    static func printUsage() {
        print("""
        INDD to IDML Native macOS Converter CLI
        Usage: indd2idml-cli [options] <input.indd | input_folder> ...

        Options:
          -o, --output <dir>    Specify custom destination directory (default: same folder as source file)
          --find, --scan        Scan computer (Downloads, Documents, Desktop) for all .indd files
          --convert             Convert files discovered during scan (use with --find)
          --list-indesign       List detected Adobe InDesign installations on this Mac
          -h, --help            Show this help information

        Examples:
          # Convert file and save .idml in the exact same folder as the .indd file:
          indd2idml-cli brochure.indd

          # Find all InDesign documents across the computer:
          indd2idml-cli --find

          # Find and convert all InDesign documents on the computer:
          indd2idml-cli --find --convert
        """)
    }
}
