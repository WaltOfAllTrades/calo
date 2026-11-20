#!/bin/bash
# refresh-device.sh: rebuild, reinstall and launch the Calo install on your iPhone, renewing the
# 7-day Personal Team provisioning profile. Run whenever the app stops opening:
#     ios/scripts/refresh-device.sh
# Picks the first connected physical iPhone (cable or Wi-Fi). Override with DEVICE_ID=<udid>.
# Never changes the bundle ID or signing settings; on a signing error it stops and prints it.
set -euo pipefail

cd "$(dirname "$0")/.."
[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"

SCHEME="Calo"
BUNDLE_ID="com.waltofalltrades.calo"
DERIVED=".derivedData"
APP="$DERIVED/Build/Products/Debug-iphoneos/Calo.app"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

step() { printf '\n==> %s\n' "$*"; }
pretty() { if command -v xcbeautify >/dev/null; then xcbeautify --quiet; else cat; fi; }

step "1/5 Find your iPhone"
if [ -z "${DEVICE_ID:-}" ]; then
  xcrun devicectl list devices --json-output "$TMP/devices.json" >/dev/null
  DEVICE_ID="$(python3 - "$TMP/devices.json" <<'EOF'
import json, sys
devs = json.load(open(sys.argv[1]))["result"]["devices"]
for d in devs:
    hw, cp = d.get("hardwareProperties", {}), d.get("connectionProperties", {})
    if hw.get("reality") == "physical" and hw.get("platform") == "iOS" \
       and cp.get("pairingState") == "paired" and cp.get("tunnelState") != "unavailable":
        print(hw["udid"]); break
EOF
)"
fi
if [ -z "$DEVICE_ID" ]; then
  echo "No paired iPhone found. Plug it in (or join the same Wi-Fi), unlock it, then rerun." >&2
  exit 1
fi
echo "    Device: $DEVICE_ID"

step "2/5 Generate project"
xcodegen generate --quiet

step "3/5 Build and sign (Personal Team, automatic signing)"
xcodebuild -project Calo.xcodeproj -scheme "$SCHEME" -configuration Debug \
  -destination "id=$DEVICE_ID" -derivedDataPath "$DERIVED" \
  -allowProvisioningUpdates build 2>&1 | pretty

step "4/5 Install and launch"
xcrun devicectl device install app --device "$DEVICE_ID" "$APP"
xcrun devicectl device process launch --device "$DEVICE_ID" "$BUNDLE_ID" \
  || echo "    Installed. If launch was refused: unlock the phone, or trust the developer once in Settings > General > VPN & Device Management."

step "5/5 Profile dates (free profiles last 7 days)"
security cms -D -i "$APP/embedded.mobileprovision" > "$TMP/profile.plist" 2>/dev/null
python3 - "$TMP/profile.plist" <<'EOF'
import plistlib, sys
p = plistlib.load(open(sys.argv[1], "rb"))
print(f"    Issued:  {p['CreationDate']:%Y-%m-%d %H:%M} UTC")
print(f"    Expires: {p['ExpirationDate']:%Y-%m-%d %H:%M} UTC  <- rerun this script before then")
EOF
