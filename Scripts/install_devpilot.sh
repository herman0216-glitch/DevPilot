#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_NAME="DevPilot"
APPLICATIONS_DIR="/Applications"
TARGET_APP="$APPLICATIONS_DIR/$APP_NAME.app"
CONFIGURATION="debug"

usage() {
  echo "usage: $0 [--debug|--release]"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --debug|debug)
      CONFIGURATION="debug"
      shift
      ;;
    --release|release)
      CONFIGURATION="release"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      usage >&2
      exit 2
      ;;
  esac
done

echo "==> DevPilot local installer"
echo "==> Build configuration: $CONFIGURATION"

if [[ "$TARGET_APP" != "/Applications/DevPilot.app" ]]; then
  echo "Refusing to replace unexpected path: $TARGET_APP" >&2
  exit 1
fi

echo "==> Building $APP_NAME.app"
"$ROOT_DIR/script/build_and_run.sh" --build-only --configuration "$CONFIGURATION" >/dev/null

echo "==> Locating generated app bundle"
BUILT_APP="$(find "$ROOT_DIR/dist" -maxdepth 2 -type d -name "$APP_NAME.app" -print -quit)"
if [[ -z "$BUILT_APP" || ! -d "$BUILT_APP" ]]; then
  echo "Could not find generated $APP_NAME.app under $ROOT_DIR/dist" >&2
  exit 1
fi
echo "==> Found: $BUILT_APP"

if [[ -e "$TARGET_APP" ]]; then
  echo "==> Existing installation found: $TARGET_APP"
  read -r -p "Replace /Applications/DevPilot.app? [y/N] " ANSWER
  case "$ANSWER" in
    y|Y|yes|YES)
      echo "==> Replacing only $TARGET_APP"
      rm -rf "$TARGET_APP"
      ;;
    *)
      echo "==> Install cancelled; existing app was not changed."
      exit 0
      ;;
  esac
fi

echo "==> Copying DevPilot.app to /Applications"
cp -R "$BUILT_APP" "$APPLICATIONS_DIR/"

echo "==> Opening /Applications/DevPilot.app"
open "$TARGET_APP"

echo "==> Install complete"
