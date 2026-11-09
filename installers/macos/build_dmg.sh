#!/usr/bin/env bash
set -euo pipefail

# BC Launcher's macOS installer (.dmg).
#
# Packages the built macOS app into a beautifully styled .dmg modeled after modern
# macOS installers (like Discord / Slack):
# - Clean branded background with top-left logo and drag arrow
# - Large 128px icons positioned on the left (App) and right (Applications)
# - Hidden toolbar and status bar with centered window bounds
# - Custom volume icon on the mounted volume and Finder icon on the .dmg file
#
# Prerequisites:
#   flutter build macos --release --dart-define-from-file=.env
#
# Usage:
#   installers/macos/build_dmg.sh [version]
#
# Output:
#   dist/installers/BC Launcher.dmg

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

APP_NAME="BC Launcher"
APP_PATH="${APP_PATH:-build/macos/Build/Products/Release/${APP_NAME}.app}"
ICNS_PATH="installers/macos/AppIcon.icns"
PNG_ICON_PATH="macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_512.png"
BG_SVG="installers/macos/background.svg"
BG_PNG="installers/macos/background.png"

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  if [ -f pubspec.yaml ]; then
    VERSION=$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}' | cut -d'+' -f1 | tr -d '[:space:]')
  fi
fi

if [ -z "$VERSION" ]; then
  echo "Error: Version not specified and could not be determined from pubspec.yaml." >&2
  echo "Usage: $0 [version]" >&2
  exit 1
fi

if [ ! -d "$APP_PATH" ]; then
  echo "Error: App bundle not found at '$APP_PATH'." >&2
  echo "Build the release app first with:" >&2
  echo "  flutter build macos --release --dart-define-from-file=.env" >&2
  exit 1
fi

OUTPUT_DIR="dist/installers"
OUTPUT_NAME="${OUTPUT_NAME:-BC Launcher.dmg}"
OUTPUT_DMG="${OUTPUT_DIR}/${OUTPUT_NAME}"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_DMG"

STAGING_DIR="$(mktemp -d "/tmp/bc-launcher-dmg.XXXXXX")"
TMP_DMG="$(mktemp "/tmp/bc-launcher-rw.XXXXXX").dmg"
rm -f "$TMP_DMG"

cleanup() {
  if [ -n "${MOUNT_DIR:-}" ] && [ -d "$MOUNT_DIR" ]; then
    hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  fi
  rm -rf "$STAGING_DIR" "$TMP_DMG"
}
trap cleanup EXIT

echo "Staging '$APP_NAME' v${VERSION}..."
cp -R "$APP_PATH" "$STAGING_DIR/${APP_NAME}.app"
ln -s /Applications "$STAGING_DIR/Applications"

# Ensure ad-hoc code signature
echo "Ad-hoc signing app bundle..."
codesign --force --deep --sign - "$STAGING_DIR/${APP_NAME}.app"

# Volume icon
if [ -f "$ICNS_PATH" ]; then
  cp "$ICNS_PATH" "$STAGING_DIR/.VolumeIcon.icns"
  SetFile -c icnC "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
  SetFile -a V "$STAGING_DIR/.VolumeIcon.icns" 2>/dev/null || true
fi

# Ensure background image is rendered
if [ ! -f "$BG_PNG" ] && [ -f "$BG_SVG" ] && command -v swift >/dev/null 2>&1; then
  echo "Rendering background image..."
  swift -e '
import AppKit
guard let svg = NSImage(contentsOfFile: "'"$BG_SVG"'") else { exit(1) }
guard let bitmap = NSBitmapImageRep(
  bitmapDataPlanes: nil, pixelsWide: 1320, pixelsHigh: 840,
  bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
  colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0) else { exit(1) }
bitmap.size = NSSize(width: 660, height: 420)
NSGraphicsContext.saveGraphicsState()
let ctx = NSGraphicsContext(bitmapImageRep: bitmap)!
NSGraphicsContext.current = ctx
ctx.shouldAntialias = true
svg.draw(in: NSRect(x: 0, y: 0, width: 660, height: 420))
NSGraphicsContext.restoreGraphicsState()
guard let png = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try png.write(to: URL(fileURLWithPath: "'"$BG_PNG"'"))
' 2>/dev/null || true
fi

if [ -f "$BG_PNG" ]; then
  mkdir -p "$STAGING_DIR/.background"
  cp "$BG_PNG" "$STAGING_DIR/.background/background.png"
  SetFile -a V "$STAGING_DIR/.background" 2>/dev/null || true
fi

echo "Creating disk image..."
hdiutil create \
  -srcfolder "$STAGING_DIR" \
  -volname "$APP_NAME" \
  -fs HFS+ \
  -format UDRW \
  -ov \
  "$TMP_DMG" >/dev/null

echo "Applying Finder window layout & styling..."
MOUNT_INFO=$(hdiutil attach -noverify -noautoopen "$TMP_DMG")
MOUNT_DIR=$(echo "$MOUNT_INFO" | grep "/Volumes/" | sed 's/.*\/Volumes/\/Volumes/')

if [ -n "$MOUNT_DIR" ] && [ -d "$MOUNT_DIR" ]; then
  SetFile -a C "$MOUNT_DIR" 2>/dev/null || true

  osascript << EOF >/dev/null 2>&1 || true
tell application "Finder"
  tell disk "$APP_NAME"
    open
    delay 0.5
    set current view of container window to icon view
    set toolbar visible of container window to false
    set statusbar visible of container window to false
    set the bounds of container window to {300, 150, 960, 570}
    set theViewOptions to the icon view options of container window
    set arrangement of theViewOptions to not arranged
    set icon size of theViewOptions to 128
    try
      set background picture of theViewOptions to file ".background:background.png"
    end try
    set position of item "${APP_NAME}.app" of container window to {175, 215}
    set position of item "Applications" of container window to {485, 215}
    close
    delay 0.5
    open
    delay 0.5
    update without registering applications
  end tell
end tell
EOF

  sleep 1
  hdiutil detach "$MOUNT_DIR" >/dev/null 2>&1 || true
  unset MOUNT_DIR
fi

echo "Compressing DMG..."
hdiutil convert "$TMP_DMG" \
  -format UDZO \
  -imagekey zlib-level=9 \
  -ov \
  -o "$OUTPUT_DMG" >/dev/null

if [ -f "$PNG_ICON_PATH" ] && command -v swift >/dev/null 2>&1; then
  swift -e '
import AppKit
let args = CommandLine.arguments
guard args.count >= 3,
      let image = NSImage(contentsOfFile: args[1]) else { exit(0) }
_ = NSWorkspace.shared.setIcon(image, forFile: args[2], options: [])
' "$PNG_ICON_PATH" "$OUTPUT_DMG" 2>/dev/null || true
fi

echo "Installer created successfully:"
echo "  $OUTPUT_DMG ($(du -h "$OUTPUT_DMG" | cut -f1))"
