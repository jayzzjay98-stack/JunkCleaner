#!/bin/bash
set -e

echo "🔨 Building JunkCleaner (Window App)..."
swift build -c release 2>&1

BINARY=".build/release/JunkCleaner"

echo ""
echo "📦 Creating .app bundle..."

APP_DIR="JunkCleaner.app/Contents/MacOS"
RES_DIR="JunkCleaner.app/Contents/Resources"

mkdir -p "$APP_DIR"
mkdir -p "$RES_DIR"

cp "$BINARY" "$APP_DIR/JunkCleaner"
cp "Info.plist" "JunkCleaner.app/Contents/Info.plist"
cp "AppIcon.icns" "$RES_DIR/AppIcon.icns" 2>/dev/null || true

echo "✅ Done! Running app..."
open "JunkCleaner.app"
