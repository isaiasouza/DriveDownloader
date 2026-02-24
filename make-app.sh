#!/bin/bash
# Build release and create .app bundle for DriveDownloader
set -e

APP_NAME="Iris Downloader"
BUNDLE_ID="com.irismedia.DriveDownloader"
EXECUTABLE="DriveDownloader"

echo "Building release..."
swift build -c release

echo "Creating .app bundle..."
APP_DIR="$APP_NAME.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp .build/release/$EXECUTABLE "$APP_DIR/Contents/MacOS/$EXECUTABLE"

cat > "$APP_DIR/Contents/Info.plist" << PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>pt-BR</string>
    <key>CFBundleExecutable</key>
    <string>$EXECUTABLE</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_ID</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.3</string>
    <key>CFBundleVersion</key>
    <string>4</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.utilities</string>
</dict>
</plist>
PLIST

echo "Done! Created '$APP_DIR'"
echo "You can now:"
echo "  open '$APP_DIR'           # Run the app"
echo "  cp -r '$APP_DIR' /Applications/  # Install to Applications"
