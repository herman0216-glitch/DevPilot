#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DevPilot"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"

echo "==> Building $APP_NAME v0.1.0 release"
echo "==> Cleaning old distribution artifacts"
rm -rf "$APP_BUNDLE"
rm -f "$ROOT_DIR"/dist/DevPilot-v*.zip
rm -f "$ROOT_DIR"/dist/DevPilot-v*.dmg

echo "==> Running SwiftPM release build"
"$ROOT_DIR/script/build_and_run.sh" --build-only --release >/dev/null

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Release build did not produce $APP_BUNDLE" >&2
  exit 1
fi

if command -v codesign >/dev/null 2>&1 && [[ "${SKIP_ADHOC_SIGN:-0}" != "1" ]]; then
  echo "==> Applying local ad-hoc signature"
  codesign --force --deep --sign - "$APP_BUNDLE"
else
  echo "==> Skipping ad-hoc signature"
fi

echo "==> Validating app bundle"
test -x "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$APP_BUNDLE/Contents/Info.plist" >/dev/null

echo "==> Release app ready:"
echo "$APP_BUNDLE"
