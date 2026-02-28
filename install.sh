#!/bin/bash
set -e

echo "🧹 Building JunkCleaner..."
swift build -c release

APP_NAME="JunkCleaner"
BUILD_PATH=".build/release/$APP_NAME"
APP_DIR="/Applications/$APP_NAME.app"
CONTENTS="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS/MacOS"
RESOURCES_DIR="$CONTENTS/Resources"

mkdir -p "$MACOS_DIR" "$RESOURCES_DIR"
cp "$BUILD_PATH" "$MACOS_DIR/"
cp Info.plist "$CONTENTS/"
[ -f AppIcon.icns ] && cp AppIcon.icns "$RESOURCES_DIR/"

# Sign for local use
codesign --force --deep --sign - "$APP_DIR" 2>/dev/null || true

echo "✅ Installed to $APP_DIR"
echo "🚀 Launching..."
open "$APP_DIR"
