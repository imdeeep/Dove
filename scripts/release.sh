#!/usr/bin/env bash
# Dove release helper — archive, export .dmg, sign, and notarize.
#
# Prerequisites (public release):
#   - Apple Developer Program membership
#   - Developer ID Application certificate in Keychain
#
# Usage:
#   ./scripts/release.sh 1.0.0              # public .dmg (Developer ID required)
#   ./scripts/release.sh 1.0.0 --local      # local test .dmg (Apple Development cert OK)
#   ./scripts/release.sh 1.0.0 2            # version + build number
#
# Optional environment variables:
#   DEVELOPMENT_TEAM   Apple Team ID (auto-detected from Dove.xcodeproj if unset)
#   CODE_SIGN_IDENTITY Override signing identity (only if using manual signing)
#   DEVELOPER_ID       Signs the .dmg (optional)
#   NOTARY_PROFILE     Keychain profile for notarytool (optional)

set -euo pipefail

LOCAL=0
POSITIONAL=()
for arg in "$@"; do
  case "$arg" in
    --local) LOCAL=1 ;;
    *) POSITIONAL+=("$arg") ;;
  esac
done

VERSION="${POSITIONAL[0]:?Usage: ./scripts/release.sh <version> [build] [--local]
Example: ./scripts/release.sh 1.0.0
         ./scripts/release.sh 1.0.0 --local   # test build on this Mac only}"
BUILD="${POSITIONAL[1]:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Dove"
PROJECT="$ROOT/Dove.xcodeproj"
ARCHIVE_PATH="$ROOT/build/Dove.xcarchive"
EXPORT_DIR="$ROOT/build/export"
if [[ "$LOCAL" -eq 1 ]]; then
  DMG_PATH="$ROOT/build/Dove-${VERSION}-local.dmg"
else
  DMG_PATH="$ROOT/build/Dove-${VERSION}.dmg"
fi
APP_NAME="Dove.app"
PBXPROJ="$PROJECT/project.pbxproj"

detect_development_team() {
  if [[ -n "${DEVELOPMENT_TEAM:-}" ]]; then
    echo "$DEVELOPMENT_TEAM"
    return
  fi

  if [[ -f "$PBXPROJ" ]]; then
    local team
    team="$(grep -m1 'DEVELOPMENT_TEAM = ' "$PBXPROJ" | sed -E 's/.*DEVELOPMENT_TEAM = ([^;]+);/\1/' | tr -d '[:space:]')"
    if [[ -n "$team" && "$team" != "YOUR_TEAM_ID" ]]; then
      echo "$team"
      return
    fi
  fi

  echo ""
}

has_developer_id_certificate() {
  security find-identity -v -p codesigning 2>/dev/null | grep -q 'Developer ID Application'
}

print_developer_id_help() {
  cat >&2 <<'EOF'

No "Developer ID Application" certificate found in your Keychain.

Public releases (GitHub, website download) require this certificate.
Create one in Xcode:

  1. Xcode → Settings → Accounts → select your Apple ID
  2. Select your Developer team → Manage Certificates…
  3. Click + → Developer ID Application
  4. Re-run: ./scripts/release.sh VERSION

For testing on this Mac only (no public distribution):

  ./scripts/release.sh VERSION --local

EOF
}

DEVELOPMENT_TEAM="$(detect_development_team)"
if [[ -z "$DEVELOPMENT_TEAM" ]]; then
  echo "error: DEVELOPMENT_TEAM is not set and could not be read from Dove.xcodeproj" >&2
  echo "Set it manually: export DEVELOPMENT_TEAM=YOUR_TEAM_ID" >&2
  exit 1
fi

if [[ "$LOCAL" -eq 0 ]] && ! has_developer_id_certificate; then
  echo "error: Developer ID Application certificate required for public release" >&2
  print_developer_id_help
  exit 1
fi

if [[ "$LOCAL" -eq 1 ]]; then
  echo "==> Local test build (not for public distribution)"
else
  echo "==> Public release build"
fi
echo "==> Using development team ${DEVELOPMENT_TEAM}"

echo "==> Bumping version to ${VERSION} (${BUILD})"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$ROOT/app/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD}" "$ROOT/app/Info.plist"

VERSION_JSON="$ROOT/website/public/version.json"
SITE_CONFIG="$ROOT/website/lib/site-config.ts"
if command -v python3 &>/dev/null; then
  python3 - <<PY
import json
import re
from pathlib import Path

version = "$VERSION"
build = "$BUILD"

version_json = Path("$VERSION_JSON")
data = json.loads(version_json.read_text())
data["version"] = version
data["build"] = build
version_json.write_text(json.dumps(data, indent=2) + "\n")

site_config = Path("$SITE_CONFIG")
text = site_config.read_text()
text, count = re.subn(
    r'version: "v[^"]+"',
    f'version: "v{version}"',
    text,
    count=1,
)
if count != 1:
    raise SystemExit("Could not update site-config.ts version")
site_config.write_text(text)
PY
fi

echo "==> Cleaning build folder"
rm -rf "$ROOT/build"
mkdir -p "$ROOT/build"

echo "==> Archiving"
ARCHIVE_ARGS=(
  -project "$PROJECT"
  -scheme "$SCHEME"
  -configuration Release
  -destination "generic/platform=macOS"
  -archivePath "$ARCHIVE_PATH"
  DEVELOPMENT_TEAM="$DEVELOPMENT_TEAM"
)

if [[ -n "${CODE_SIGN_IDENTITY:-}" ]]; then
  ARCHIVE_ARGS+=(CODE_SIGN_IDENTITY="$CODE_SIGN_IDENTITY")
fi

if ! xcodebuild archive "${ARCHIVE_ARGS[@]}"; then
  echo "error: archive failed — open Dove.xcodeproj and confirm Signing & Capabilities is set up" >&2
  exit 1
fi

echo "==> Exporting .app"
EXPORT_OPTIONS="$ROOT/build/ExportOptions.plist"
if [[ "$LOCAL" -eq 1 ]]; then
  cat > "$EXPORT_OPTIONS" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>method</key>
	<string>debugging</string>
	<key>teamID</key>
	<string>${DEVELOPMENT_TEAM}</string>
	<key>signingStyle</key>
	<string>automatic</string>
</dict>
</plist>
EOF
else
  cp "$ROOT/scripts/ExportOptions.plist" "$EXPORT_OPTIONS"
  /usr/libexec/PlistBuddy -c "Set :teamID ${DEVELOPMENT_TEAM}" "$EXPORT_OPTIONS"
fi

if ! xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$EXPORT_OPTIONS"; then
  if [[ "$LOCAL" -eq 0 ]]; then
    print_developer_id_help
  fi
  echo "error: export failed" >&2
  exit 1
fi

APP_PATH="$EXPORT_DIR/$APP_NAME"
if [[ ! -d "$APP_PATH" ]]; then
  APP_PATH="$(find "$EXPORT_DIR" -maxdepth 1 -name '*.app' -type d | head -1)"
fi
if [[ -z "$APP_PATH" || ! -d "$APP_PATH" ]]; then
  echo "error: no .app found in $EXPORT_DIR (expected $APP_NAME)" >&2
  exit 1
fi

echo "==> Creating .dmg"
hdiutil create -volname Dove -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

if [[ "$LOCAL" -eq 0 && -n "${DEVELOPER_ID:-}" ]]; then
  echo "==> Signing .dmg"
  codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"
fi

if [[ "$LOCAL" -eq 0 && -n "${NOTARY_PROFILE:-}" ]]; then
  echo "==> Notarizing (this may take a few minutes)"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo ""
echo "Done: $DMG_PATH"
if [[ "$LOCAL" -eq 1 ]]; then
  echo ""
  echo "This is a LOCAL test build — not notarized, not for GitHub Releases."
  echo "For public release, create a Developer ID Application certificate, then:"
  echo "  ./scripts/release.sh ${VERSION}"
else
  echo ""
  echo "Next steps:"
  echo "  1. Test the .dmg on a clean Mac"
  echo "  2. git tag v${VERSION} && git push origin v${VERSION}"
  echo "  3. gh release create v${VERSION} \"$DMG_PATH\" --title \"Dove ${VERSION}\""
fi
