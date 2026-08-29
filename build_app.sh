#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_DIR="$DIR/HP LaserJet Manager.app"

echo "Building HP LaserJet Manager.app..."
mkdir -p "$APP_DIR/Contents/MacOS" "$APP_DIR/Contents/Resources"

swiftc -Onone "$DIR/src/main.swift" -o "$APP_DIR/Contents/MacOS/HP LaserJet Manager"
chmod +x "$APP_DIR/Contents/MacOS/HP LaserJet Manager"

cat <<'PLIST_EOF' > "$APP_DIR/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>HP LaserJet Manager</string>
    <key>CFBundleIdentifier</key>
    <string>com.custom.hp.laserjet.manager</string>
    <key>CFBundleName</key>
    <string>HP LaserJet Manager</string>
    <key>CFBundleDisplayName</key>
    <string>HP LaserJet Manager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>12.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
PLIST_EOF

echo "Build finished: $APP_DIR"
