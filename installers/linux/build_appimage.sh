#!/usr/bin/env bash
set -euo pipefail

# BC Launcher's Linux installer (.AppImage).
#
# Packages the built Linux bundle into a standalone, portable .AppImage with desktop
# integration, icon, and bclauncher:// deep link scheme registration.
#
# Prerequisites:
#   flutter build linux --release --dart-define-from-file=.env
#
# Usage:
#   installers/linux/build_appimage.sh [version]
#
# Output:
#   dist/installers/BC Launcher.AppImage

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$REPO_ROOT"

APP_NAME="BC Launcher"
BUNDLE_DIR="${BUNDLE_DIR:-build/linux/x64/release/bundle}"
DESKTOP_FILE="installers/linux/com.bcr.bc_launcher.desktop"
ICON_FILE="installers/linux/app_icon.png"

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

if [ ! -f "${BUNDLE_DIR}/bc_launcher" ]; then
  echo "Error: Linux executable not found at '${BUNDLE_DIR}/bc_launcher'." >&2
  echo "Build the release app first with:" >&2
  echo "  flutter build linux --release --dart-define-from-file=.env" >&2
  exit 1
fi

if [ ! -f "$DESKTOP_FILE" ] || [ ! -f "$ICON_FILE" ]; then
  echo "Error: Desktop file or icon missing in installers/linux/." >&2
  exit 1
fi

OUTPUT_DIR="dist/installers"
OUTPUT_NAME="${OUTPUT_NAME:-BC Launcher.AppImage}"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_NAME}"

mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_FILE"

APPDIR="$(mktemp -d "/tmp/bc-launcher-appdir.XXXXXX")"
TEMP_TOOL=""

cleanup() {
  rm -rf "$APPDIR"
  if [ -n "$TEMP_TOOL" ] && [ -f "$TEMP_TOOL" ]; then
    rm -f "$TEMP_TOOL"
  fi
}
trap cleanup EXIT

echo "Staging AppDir for '$APP_NAME' v${VERSION}..."
cp -R "${BUNDLE_DIR}/"* "$APPDIR/"
cp "$DESKTOP_FILE" "$APPDIR/com.bcr.bc_launcher.desktop"
cp "$ICON_FILE" "$APPDIR/com.bcr.bc_launcher.png"
ln -sf "com.bcr.bc_launcher.png" "$APPDIR/.DirIcon"

mkdir -p "$APPDIR/usr/share/applications"
cp "$DESKTOP_FILE" "$APPDIR/usr/share/applications/"

mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"
cp "$ICON_FILE" "$APPDIR/usr/share/icons/hicolor/512x512/apps/com.bcr.bc_launcher.png"

# AppRun launcher script
cat << 'EOF' > "$APPDIR/AppRun"
#!/usr/bin/env bash
set -e
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}:${PATH}"
export LD_LIBRARY_PATH="${HERE}/lib:${LD_LIBRARY_PATH:-}"
exec "${HERE}/bc_launcher" "$@"
EOF
chmod +x "$APPDIR/AppRun"

# Locate or download appimagetool
APPIMAGETOOL="${APPIMAGETOOL:-}"
if [ -z "$APPIMAGETOOL" ]; then
  if command -v appimagetool >/dev/null 2>&1; then
    APPIMAGETOOL="appimagetool"
  else
    echo "Downloading appimagetool..."
    TEMP_TOOL="$(mktemp "/tmp/appimagetool.XXXXXX")"
    curl -fsSL -o "$TEMP_TOOL" "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$TEMP_TOOL"
    APPIMAGETOOL="$TEMP_TOOL"
  fi
fi

echo "Building AppImage..."
export ARCH="x86_64"

# Use --appimage-extract-and-run if FUSE is not available (e.g. in Docker or GitHub Actions)
APPIMAGE_ARGS=()
if [ ! -e /dev/fuse ] || [ "${NO_FUSE:-0}" = "1" ]; then
  APPIMAGE_ARGS+=("--appimage-extract-and-run")
fi

"$APPIMAGETOOL" "${APPIMAGE_ARGS[@]}" "$APPDIR" "$OUTPUT_FILE"

echo "Installer created successfully:"
echo "  $OUTPUT_FILE ($(du -h "$OUTPUT_FILE" | cut -f1))"
