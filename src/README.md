# INDD to IDML Native macOS Engine & Application

This directory contains the production implementation of the native macOS **INDD to IDML** converter suite, built in Swift using the Apple Events / InDesign automation bridge architecture.

## Architecture

The project consists of three layers:

1. **`INDDConverterEngine` (Core Library)**
   - `InDesignDetector.swift`: Automatically discovers installed InDesign versions across `/Applications`, Spotlight, and LaunchServices.
   - `InDesignBridge.swift`: Manages silent, non-blocking document export (`showing window false`, `user interaction level = never interact`) with watchdog timeout control.
   - `BatchConverter.swift`: Thread-safe batch queue coordinator supporting recursive folders and asynchronous progress reporting.
   - `INDDSearcher.swift`: High-speed scanner that searches the Mac for all `.indd` and `.indt` files across user folders.
   - `Models.swift`: Domain models for conversion items, statuses, options, and discovered search files.

2. **`indd2idml-cli` (Command-Line Tool)**
   - High-performance CLI tool for single-file or batch conversion.
   - Run `--list-indesign` to inspect detected InDesign engines.
   - Run `--find` to scan the computer for all InDesign documents.
   - Run `--find --convert` to find and convert all InDesign files automatically.
   - **Default Destination**: Saved in the exact same folder as each source `.indd` file.

3. **`INDD2IDML.app` (Native SwiftUI macOS App)**
   - Native macOS application with Apple Human Interface Guidelines aesthetics.
   - **Computer Search Sheet**: One-click "Scan Mac for .indd" feature that searches the computer and lets users select files to add directly to the queue.
   - **Output Location**: Saved right alongside the source file by default (with optional custom override).
   - Drag & drop zone for individual `.indd`/`.indt` files or entire folders.
   - Real-time queue view with status badges (Waiting, Exporting, Done, Failed).
   - InDesign health indicator pill.
   - Finder reveal button for converted `.idml` files.

## Building & Testing

### Run Tests
```bash
cd src
swift test
```

### Build CLI Tool
```bash
cd src
swift build -c release --product indd2idml-cli
./.build/release/indd2idml-cli --help
```

### Build Installers (.dmg and .pkg)
```bash
cd src
./create_installer.sh
```

Output artifacts generated in `src/dist/`:
- `src/dist/INDD2IDML-1.0.0.dmg` (Standard macOS Drag-and-Drop Disk Image Installer)
- `src/dist/INDD2IDML-1.0.0.pkg` (macOS 1-Click Installer Package)
- `src/dist/INDD2IDML.app` (macOS Application bundle)
- `src/dist/bin/indd2idml-cli` (Standalone executable CLI)
