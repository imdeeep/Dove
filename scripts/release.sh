#!/usr/bin/env bash
# Dove release helper — archive, export .dmg, sign, and notarize.
#
# Prerequisites:
#   - Xcode with Developer ID Application certificate installed
#   - App Store Connect API key for notarytool (or Apple ID credentials)
#   - Environment variables (see docs/release.md)
#
# Usage:
#   ./scripts/release.sh 1.0.0

set -euo pipefail

VERSION="${1:?Usage: ./scripts/release.sh <version>}"
BUILD="${2:-1}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="Dove"
PROJECT="$ROOT/Dove.xcodeproj"
ARCHIVE_PATH="$ROOT/build/Dove.xcarchive"
EXPORT_DIR="$ROOT/build/export"
DMG_PATH="$ROOT/build/Dove-${VERSION}.dmg"
APP_NAME="Dove.app"

echo "==> Bumping version to ${VERSION} (${BUILD})"
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString ${VERSION}" "$ROOT/app/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion ${BUILD}" "$ROOT/app/Info.plist"

# Sync website version manifest and marketing site config
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
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  CODE_SIGN_STYLE=Manual \
  DEVELOPMENT_TEAM="${DEVELOPMENT_TEAM:?Set DEVELOPMENT_TEAM}" \
  CODE_SIGN_IDENTITY="${CODE_SIGN_IDENTITY:-Developer ID Application}" \
  | tail -5

echo "==> Exporting .app"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_DIR" \
  -exportOptionsPlist "$ROOT/scripts/ExportOptions.plist" \
  | tail -5

APP_PATH="$EXPORT_DIR/$APP_NAME"

echo "==> Creating .dmg"
hdiutil create -volname Dove -srcfolder "$APP_PATH" -ov -format UDZO "$DMG_PATH"

if [[ -n "${DEVELOPER_ID:-}" ]]; then
  echo "==> Signing .dmg"
  codesign --force --sign "$DEVELOPER_ID" "$DMG_PATH"
fi

if [[ -n "${NOTARY_PROFILE:-}" ]]; then
  echo "==> Notarizing (this may take a few minutes)"
  xcrun notarytool submit "$DMG_PATH" --keychain-profile "$NOTARY_PROFILE" --wait
  xcrun stapler staple "$DMG_PATH"
fi

echo ""
echo "Done: $DMG_PATH"
echo ""
echo "Next steps:"
echo "  1. Test the .dmg on a clean Mac"
echo "  2. git tag v${VERSION} && git push origin v${VERSION}"
echo "  3. gh release create v${VERSION} \"$DMG_PATH\" --title \"Dove ${VERSION}\""
