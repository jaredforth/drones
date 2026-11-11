#!/bin/sh
# Builds build/Drones.app; run with `open build/Drones.app`.
set -e
cd "$(dirname "$0")"
app=build/Drones.app
rm -rf "$app" && mkdir -p "$app/Contents/MacOS"
swiftc -O -parse-as-library Drones/*.swift -o "$app/Contents/MacOS/Drones"
# App icon: render Logo to a PNG, then build the .icns from resized copies.
t=$(mktemp -d); mkdir "$t/i.iconset"
swiftc tools/main.swift Drones/Logo.swift -o "$t/icon"
"$t/icon" "$t/1024.png"
for s in 16 32 128 256 512; do
  sips -z $s $s "$t/1024.png" --out "$t/i.iconset/icon_${s}x${s}.png" >/dev/null
  sips -z $((s*2)) $((s*2)) "$t/1024.png" --out "$t/i.iconset/icon_${s}x${s}@2x.png" >/dev/null
done
mkdir -p "$app/Contents/Resources" && iconutil -c icns "$t/i.iconset" -o "$app/Contents/Resources/Drones.icns"
cp "$t/1024.png" build/icon.png; rm -rf "$t"
cat > "$app/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Drones</string>
<key>CFBundleIdentifier</key><string>dev.jaredforth.drones</string>
<key>CFBundleExecutable</key><string>Drones</string>
<key>CFBundleIconFile</key><string>Drones</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>LSMinimumSystemVersion</key><string>13.0</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
P
