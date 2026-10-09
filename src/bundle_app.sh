#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/.build/release"
DIST_DIR="$SCRIPT_DIR/dist"
APP_NAME="INDD2IDML.app"
APP_BUNDLE="$DIST_DIR/$APP_NAME"

echo "==> Building release binaries with Swift..."
cd "$SCRIPT_DIR"
swift build -c release --product INDD2IDML
swift build -c release --product indd2idml-cli

echo "==> Creating macOS App bundle structure at $APP_BUNDLE..."
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"
mkdir -p "$DIST_DIR/bin"

# Copy App binary
cp "$BUILD_DIR/INDD2IDML" "$APP_BUNDLE/Contents/MacOS/INDD2IDML"
chmod +x "$APP_BUNDLE/Contents/MacOS/INDD2IDML"

# Copy CLI binary to dist/bin for convenience
cp "$BUILD_DIR/indd2idml-cli" "$DIST_DIR/bin/indd2idml-cli"
chmod +x "$DIST_DIR/bin/indd2idml-cli"

# Write Info.plist
cat << 'EOF' > "$APP_BUNDLE/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>INDD2IDML</string>
    <key>CFBundleIdentifier</key>
    <string>com.antigravity.indd2idml</string>
    <key>CFBundleName</key>
    <string>INDD2IDML</string>
    <key>CFBundleDisplayName</key>
    <string>INDD to IDML</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppleEventsUsageDescription</key>
    <string>INDD to IDML requires permission to automate Adobe InDesign for silent batch document export.</string>
</dict>
</plist>
EOF

echo "==> Packaging complete!"
echo "    App bundle: $APP_BUNDLE"
echo "    CLI tool:   $DIST_DIR/bin/indd2idml-cli"
