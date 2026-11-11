#!/bin/bash
set -e

# Change to app directory and build release app
echo "Building TodoCat macOS Release..."
cd "$(dirname "$0")/../app"
flutter build macos --release

APP_PATH="build/macos/Build/Products/Release/TodoCat.app"
STAGING_DIR="build/dmg_staging"
VERSION=$(grep 'version:' pubspec.yaml | head -n1 | cut -d' ' -f2 | cut -d'+' -f1)
OUTPUT_DMG="../TodoCat-${VERSION}-macos.dmg"

echo "Packaging DMG for version ${VERSION}..."
rm -rf "$STAGING_DIR" "$OUTPUT_DMG"
mkdir -p "$STAGING_DIR"
cp -R "$APP_PATH" "$STAGING_DIR/"
ln -s /Applications "$STAGING_DIR/Applications"

hdiutil create -volname "TodoCat" -srcfolder "$STAGING_DIR" -ov -format UDZO "$OUTPUT_DMG"
rm -rf "$STAGING_DIR"

echo "Verifying DMG..."
hdiutil verify "$OUTPUT_DMG"

echo "Done! DMG created at: ${OUTPUT_DMG}"
