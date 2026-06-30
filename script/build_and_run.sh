#!/usr/bin/env bash
set -euo pipefail

MODE="run"
CONFIGURATION="${CONFIGURATION:-debug}"
APP_NAME="DevPilot"
BUNDLE_ID="com.herman.DevPilot"
MIN_SYSTEM_VERSION="14.0"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIST_DIR="$ROOT_DIR/dist"
APP_BUNDLE="$DIST_DIR/$APP_NAME.app"
APP_CONTENTS="$APP_BUNDLE/Contents"
APP_MACOS="$APP_CONTENTS/MacOS"
APP_RESOURCES="$APP_CONTENTS/Resources"
APP_BINARY="$APP_MACOS/$APP_NAME"
INFO_PLIST="$APP_CONTENTS/Info.plist"
SOURCE_RESOURCES="$ROOT_DIR/Sources/DevPilot/Resources"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --release|release)
      CONFIGURATION="release"
      shift
      ;;
    --debug|debug)
      if [[ "$MODE" == "run" ]]; then
        MODE="debug"
      else
        CONFIGURATION="debug"
      fi
      shift
      ;;
    --configuration)
      CONFIGURATION="${2:-}"
      if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
        echo "configuration must be debug or release" >&2
        exit 2
      fi
      shift 2
      ;;
    --build-only|build-only)
      MODE="build-only"
      shift
      ;;
    --logs|logs)
      MODE="logs"
      shift
      ;;
    --telemetry|telemetry)
      MODE="telemetry"
      shift
      ;;
    --verify|verify)
      MODE="verify"
      shift
      ;;
    run)
      MODE="run"
      shift
      ;;
    *)
      echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify] [--release|--configuration debug|release]" >&2
      exit 2
      ;;
  esac
done

pkill -x "$APP_NAME" >/dev/null 2>&1 || true

if [[ ! -f "$SOURCE_RESOURCES/AppIcon.icns" || ! -f "$SOURCE_RESOURCES/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon.png" ]]; then
  "$ROOT_DIR/Scripts/generate_app_icons.sh"
fi

swift build --configuration "$CONFIGURATION" --product "$APP_NAME"
BUILD_DIR="$(swift build --configuration "$CONFIGURATION" --show-bin-path)"
BUILD_BINARY="$BUILD_DIR/$APP_NAME"

rm -rf "$APP_BUNDLE"
mkdir -p "$APP_MACOS" "$APP_RESOURCES"
cp "$BUILD_BINARY" "$APP_BINARY"
chmod +x "$APP_BINARY"

cp "$SOURCE_RESOURCES/AppIcon.icns" "$APP_RESOURCES/AppIcon.icns"
cp "$SOURCE_RESOURCES/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon.png" "$APP_RESOURCES/MenuBarIcon.png"
cp "$SOURCE_RESOURCES/Assets.xcassets/MenuBarIcon.imageset/MenuBarIcon@2x.png" "$APP_RESOURCES/MenuBarIcon@2x.png"

cat >"$INFO_PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleExecutable</key>
  <string>$APP_NAME</string>
  <key>CFBundleIdentifier</key>
  <string>$BUNDLE_ID</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIconName</key>
  <string>AppIcon</string>
  <key>CFBundleDisplayName</key>
  <string>$APP_NAME</string>
  <key>CFBundleName</key>
  <string>$APP_NAME</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>0.1.0</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>$MIN_SYSTEM_VERSION</string>
  <key>NSHighResolutionCapable</key>
  <true/>
  <key>NSPrincipalClass</key>
  <string>NSApplication</string>
</dict>
</plist>
PLIST

open_app() {
  /usr/bin/open -n "$APP_BUNDLE"
}

case "$MODE" in
  run)
    open_app
    ;;
  build-only)
    echo "$APP_BUNDLE"
    ;;
  debug)
    lldb -- "$APP_BINARY"
    ;;
  logs)
    open_app
    /usr/bin/log stream --info --style compact --predicate "process == \"$APP_NAME\""
    ;;
  telemetry)
    open_app
    /usr/bin/log stream --info --style compact --predicate "subsystem == \"$BUNDLE_ID\""
    ;;
  verify)
    open_app
    sleep 1
    pgrep -x "$APP_NAME" >/dev/null
    ;;
  *)
    echo "usage: $0 [run|--build-only|--debug|--logs|--telemetry|--verify] [--release|--configuration debug|release]" >&2
    exit 2
    ;;
esac
