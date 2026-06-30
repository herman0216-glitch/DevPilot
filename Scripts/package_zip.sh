#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DevPilot"
VERSION="0.1.0"
APP_BUNDLE="$ROOT_DIR/dist/$APP_NAME.app"
ZIP_PATH="$ROOT_DIR/dist/$APP_NAME-v$VERSION-macOS.zip"

if [[ ! -d "$APP_BUNDLE" ]]; then
  echo "Missing $APP_BUNDLE" >&2
  echo "Run ./Scripts/build_release.sh first." >&2
  exit 1
fi

echo "==> Packaging $ZIP_PATH"
rm -f "$ZIP_PATH"
cd "$ROOT_DIR/dist"
/usr/bin/ditto -c -k --sequesterRsrc --keepParent "$APP_NAME.app" "$ZIP_PATH"

echo "==> ZIP ready:"
echo "$ZIP_PATH"
