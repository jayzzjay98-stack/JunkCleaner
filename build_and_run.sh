#!/bin/bash
set -e
echo "🔨 Building NeoClean..."
swift build -c release 2>&1

APP="NeoClean.app"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
mkdir -p "$APP/Contents/Resources"

cp ".build/release/JunkCleaner" "$APP/Contents/MacOS/JunkCleaner"
cp "Info.plist" "$APP/Contents/Info.plist"
cp "AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns" 2>/dev/null || true
chmod +x "$APP/Contents/MacOS/JunkCleaner"

echo "✅ Done → $APP"
open "$APP"
