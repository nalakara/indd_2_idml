#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DIST_DIR="$SCRIPT_DIR/dist"
APP_NAME="INDD2IDML.app"
APP_BUNDLE="$DIST_DIR/$APP_NAME"
VERSION="1.0.0"
DMG_NAME="INDD2IDML-${VERSION}.dmg"
PKG_NAME="INDD2IDML-${VERSION}.pkg"

echo "==> Verifying application bundle..."
if [ ! -d "$APP_BUNDLE" ]; then
    echo "App bundle not found at $APP_BUNDLE. Running bundle_app.sh first..."
    "$SCRIPT_DIR/bundle_app.sh"
fi

# Ensure ad-hoc signature is applied
codesign --force --deep --sign - "$APP_BUNDLE" 2>/dev/null || true

echo "==> 1. Generating Apple Disk Image (.dmg) Installer..."
DMG_STAGE="$DIST_DIR/dmg_stage"
rm -rf "$DMG_STAGE" "$DIST_DIR/$DMG_NAME"
mkdir -p "$DMG_STAGE"

# Copy App to staging
cp -R "$APP_BUNDLE" "$DMG_STAGE/"

# Create symlink to Applications directory for drag-and-drop
ln -s /Applications "$DMG_STAGE/Applications"

# Include CLI binary and quick install instructions
mkdir -p "$DMG_STAGE/Terminal Tools"
if [ -f "$DIST_DIR/bin/indd2idml-cli" ]; then
    cp "$DIST_DIR/bin/indd2idml-cli" "$DMG_STAGE/Terminal Tools/"
fi
cat << 'EOF' > "$DMG_STAGE/Terminal Tools/INSTALL_CLI.txt"
To install the indd2idml-cli tool for use in Terminal:

Copy 'indd2idml-cli' to /usr/local/bin:
  sudo cp indd2idml-cli /usr/local/bin/

Then run:
  indd2idml-cli --help
EOF

# Build compressed DMG
hdiutil create -volname "INDD to IDML Installer" \
    -srcfolder "$DMG_STAGE" \
    -ov -format UDZO \
    "$DIST_DIR/$DMG_NAME"

rm -rf "$DMG_STAGE"
echo "    Created DMG: $DIST_DIR/$DMG_NAME"

echo "==> 2. Generating macOS Installer Package (.pkg)..."
rm -f "$DIST_DIR/$PKG_NAME"
pkgbuild --component "$APP_BUNDLE" \
    --install-location "/Applications" \
    --identifier "com.antigravity.indd2idml" \
    --version "$VERSION" \
    "$DIST_DIR/$PKG_NAME"

echo "    Created PKG: $DIST_DIR/$PKG_NAME"

echo ""
echo "=========================================================="
echo " Installer creation completed successfully!"
echo " Output files in $DIST_DIR:"
echo "   1. Drag-and-Drop DMG : $DIST_DIR/$DMG_NAME"
echo "   2. Installer Package : $DIST_DIR/$PKG_NAME"
echo "=========================================================="
