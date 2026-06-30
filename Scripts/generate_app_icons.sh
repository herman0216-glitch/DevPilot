#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RESOURCES_DIR="$ROOT_DIR/Sources/DevPilot/Resources"
ASSETS_DIR="$RESOURCES_DIR/Assets.xcassets"
APPICON_SET="$ASSETS_DIR/AppIcon.appiconset"
MENUBAR_SET="$ASSETS_DIR/MenuBarIcon.imageset"
SOURCE_ICON="$RESOURCES_DIR/AppIcon-1024.png"
ICNS_FILE="$RESOURCES_DIR/AppIcon.icns"
TEMP_DIR="$(mktemp -d)"

cleanup() {
  rm -rf "$TEMP_DIR"
}
trap cleanup EXIT

echo "==> Preparing asset catalog"
mkdir -p "$APPICON_SET" "$MENUBAR_SET"

DRAW_SWIFT="$TEMP_DIR/draw_devpilot_icons.swift"
cat >"$DRAW_SWIFT" <<'SWIFT'
import AppKit
import Foundation

let args = CommandLine.arguments
guard args.count == 4 else {
  fputs("usage: draw_devpilot_icons <app-icon-1024.png> <menu-icon-1x.png> <menu-icon-2x.png>\n", stderr)
  exit(2)
}

func savePNG(_ image: NSImage, to path: String) throws {
  guard
    let tiff = image.tiffRepresentation,
    let bitmap = NSBitmapImageRep(data: tiff),
    let data = bitmap.representation(using: .png, properties: [:])
  else {
    throw NSError(domain: "DevPilotIconGenerator", code: 1, userInfo: [
      NSLocalizedDescriptionKey: "Unable to render PNG at \(path)"
    ])
  }
  try data.write(to: URL(fileURLWithPath: path))
}

func appIcon(size: CGFloat) -> NSImage {
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  defer { image.unlockFocus() }

  let rect = NSRect(x: 0, y: 0, width: size, height: size)
  let corner = size * 0.225
  let clip = NSBezierPath(roundedRect: rect, xRadius: corner, yRadius: corner)
  clip.addClip()

  let background = NSGradient(colors: [
    NSColor(calibratedRed: 0.10, green: 0.25, blue: 0.96, alpha: 1.0),
    NSColor(calibratedRed: 0.36, green: 0.17, blue: 0.86, alpha: 1.0),
    NSColor(calibratedRed: 0.06, green: 0.10, blue: 0.28, alpha: 1.0)
  ])!
  background.draw(in: rect, angle: 42)

  NSColor(calibratedWhite: 1.0, alpha: 0.14).setStroke()
  for index in 0..<8 {
    let offset = CGFloat(index) * size * 0.11
    let line = NSBezierPath()
    line.move(to: NSPoint(x: -size * 0.2 + offset, y: size * 0.08))
    line.line(to: NSPoint(x: size * 0.24 + offset, y: size * 0.92))
    line.lineWidth = size * 0.006
    line.stroke()
  }

  func scaled(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    NSPoint(x: x * size, y: y * size)
  }

  let glow = NSBezierPath()
  glow.move(to: scaled(0.19, 0.47))
  glow.line(to: scaled(0.80, 0.74))
  glow.line(to: scaled(0.60, 0.23))
  glow.line(to: scaled(0.49, 0.45))
  glow.line(to: scaled(0.19, 0.47))
  NSColor(calibratedRed: 0.52, green: 0.88, blue: 1.0, alpha: 0.24).setFill()
  glow.fill()

  NSColor(calibratedRed: 0.42, green: 0.88, blue: 1.0, alpha: 0.35).setStroke()
  for (start, end, width) in [
    (scaled(0.18, 0.31), scaled(0.40, 0.38), size * 0.025),
    (scaled(0.16, 0.61), scaled(0.37, 0.55), size * 0.021),
    (scaled(0.22, 0.22), scaled(0.34, 0.26), size * 0.014)
  ] {
    let trail = NSBezierPath()
    trail.move(to: start)
    trail.line(to: end)
    trail.lineWidth = width
    trail.lineCapStyle = .round
    trail.stroke()
  }

  let plane = NSBezierPath()
  plane.move(to: scaled(0.20, 0.49))
  plane.line(to: scaled(0.81, 0.75))
  plane.line(to: scaled(0.61, 0.24))
  plane.line(to: scaled(0.50, 0.46))
  plane.line(to: scaled(0.20, 0.49))
  plane.close()
  NSColor.white.setFill()
  plane.fill()

  let fold = NSBezierPath()
  fold.move(to: scaled(0.50, 0.46))
  fold.line(to: scaled(0.81, 0.75))
  fold.line(to: scaled(0.42, 0.52))
  fold.lineWidth = size * 0.018
  fold.lineJoinStyle = .round
  NSColor(calibratedRed: 0.14, green: 0.24, blue: 0.68, alpha: 0.34).setStroke()
  fold.stroke()

  NSColor(calibratedWhite: 1.0, alpha: 0.18).setStroke()
  let border = NSBezierPath(roundedRect: rect.insetBy(dx: size * 0.018, dy: size * 0.018), xRadius: corner * 0.92, yRadius: corner * 0.92)
  border.lineWidth = size * 0.018
  border.stroke()

  return image
}

func menuIcon(size: CGFloat) -> NSImage {
  let image = NSImage(size: NSSize(width: size, height: size))
  image.lockFocus()
  defer { image.unlockFocus() }

  NSColor.clear.setFill()
  NSRect(x: 0, y: 0, width: size, height: size).fill()
  NSColor.black.setStroke()
  NSColor.black.setFill()

  func scaled(_ x: CGFloat, _ y: CGFloat) -> NSPoint {
    NSPoint(x: x * size, y: y * size)
  }

  let plane = NSBezierPath()
  plane.move(to: scaled(0.13, 0.52))
  plane.line(to: scaled(0.86, 0.79))
  plane.line(to: scaled(0.62, 0.17))
  plane.line(to: scaled(0.49, 0.43))
  plane.line(to: scaled(0.13, 0.52))
  plane.close()
  plane.lineWidth = max(1.6, size * 0.065)
  plane.lineJoinStyle = .round
  plane.stroke()

  let fold = NSBezierPath()
  fold.move(to: scaled(0.49, 0.43))
  fold.line(to: scaled(0.86, 0.79))
  fold.lineWidth = max(1.3, size * 0.055)
  fold.lineCapStyle = .round
  fold.stroke()

  for (start, end, width) in [
    (scaled(0.08, 0.28), scaled(0.31, 0.35), size * 0.065),
    (scaled(0.06, 0.72), scaled(0.27, 0.65), size * 0.055)
  ] {
    let trail = NSBezierPath()
    trail.move(to: start)
    trail.line(to: end)
    trail.lineWidth = max(1.2, width)
    trail.lineCapStyle = .round
    trail.stroke()
  }

  return image
}

try savePNG(appIcon(size: 1024), to: args[1])
try savePNG(menuIcon(size: 22), to: args[2])
try savePNG(menuIcon(size: 44), to: args[3])
SWIFT

echo "==> Drawing DevPilot source icons"
RAW_MENUBAR_1X="$TEMP_DIR/MenuBarIcon-1x-raw.png"
RAW_MENUBAR_2X="$TEMP_DIR/MenuBarIcon-2x-raw.png"
swift "$DRAW_SWIFT" "$SOURCE_ICON" "$RAW_MENUBAR_1X" "$RAW_MENUBAR_2X"
sips -z 22 22 "$RAW_MENUBAR_1X" --out "$MENUBAR_SET/MenuBarIcon.png" >/dev/null
sips -z 44 44 "$RAW_MENUBAR_2X" --out "$MENUBAR_SET/MenuBarIcon@2x.png" >/dev/null

echo "==> Generating AppIcon.appiconset PNGs"
sips -z 16 16 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-16.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-16@2x.png" >/dev/null
sips -z 32 32 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-32.png" >/dev/null
sips -z 64 64 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-32@2x.png" >/dev/null
sips -z 128 128 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-128.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-128@2x.png" >/dev/null
sips -z 256 256 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-256.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-256@2x.png" >/dev/null
sips -z 512 512 "$SOURCE_ICON" --out "$APPICON_SET/AppIcon-512.png" >/dev/null
cp "$SOURCE_ICON" "$APPICON_SET/AppIcon-512@2x.png"

cat >"$ASSETS_DIR/Contents.json" <<'JSON'
{
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

cat >"$MENUBAR_SET/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "MenuBarIcon.png",
      "idiom" : "universal",
      "scale" : "1x"
    },
    {
      "filename" : "MenuBarIcon@2x.png",
      "idiom" : "universal",
      "scale" : "2x"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  },
  "properties" : {
    "template-rendering-intent" : "template"
  }
}
JSON

cat >"$APPICON_SET/Contents.json" <<'JSON'
{
  "images" : [
    {
      "filename" : "AppIcon-16.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-16@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "16x16"
    },
    {
      "filename" : "AppIcon-32.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-32@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "32x32"
    },
    {
      "filename" : "AppIcon-128.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-128@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "128x128"
    },
    {
      "filename" : "AppIcon-256.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-256@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "256x256"
    },
    {
      "filename" : "AppIcon-512.png",
      "idiom" : "mac",
      "scale" : "1x",
      "size" : "512x512"
    },
    {
      "filename" : "AppIcon-512@2x.png",
      "idiom" : "mac",
      "scale" : "2x",
      "size" : "512x512"
    }
  ],
  "info" : {
    "author" : "xcode",
    "version" : 1
  }
}
JSON

echo "==> Generating AppIcon.icns"
ICONSET_DIR="$TEMP_DIR/AppIcon.iconset"
mkdir -p "$ICONSET_DIR"
cp "$APPICON_SET/AppIcon-16.png" "$ICONSET_DIR/icon_16x16.png"
cp "$APPICON_SET/AppIcon-16@2x.png" "$ICONSET_DIR/icon_16x16@2x.png"
cp "$APPICON_SET/AppIcon-32.png" "$ICONSET_DIR/icon_32x32.png"
cp "$APPICON_SET/AppIcon-32@2x.png" "$ICONSET_DIR/icon_32x32@2x.png"
cp "$APPICON_SET/AppIcon-128.png" "$ICONSET_DIR/icon_128x128.png"
cp "$APPICON_SET/AppIcon-128@2x.png" "$ICONSET_DIR/icon_128x128@2x.png"
cp "$APPICON_SET/AppIcon-256.png" "$ICONSET_DIR/icon_256x256.png"
cp "$APPICON_SET/AppIcon-256@2x.png" "$ICONSET_DIR/icon_256x256@2x.png"
cp "$APPICON_SET/AppIcon-512.png" "$ICONSET_DIR/icon_512x512.png"
cp "$APPICON_SET/AppIcon-512@2x.png" "$ICONSET_DIR/icon_512x512@2x.png"
iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"

echo "==> Icon assets ready"
echo "    $APPICON_SET"
echo "    $MENUBAR_SET"
echo "    $ICNS_FILE"
