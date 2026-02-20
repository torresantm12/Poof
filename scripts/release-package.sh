#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VERSION="${1:-}"
BUILD_OVERRIDE="${BUILD_OVERRIDE:-}"
NOTARYTOOL_PROFILE="${NOTARYTOOL_PROFILE:-TunaNotary}"
SKIP_NOTARIZE="${SKIP_NOTARIZE:-}"

die() {
  echo "$*" >&2
  exit 1
}

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    die "Missing required command: $1"
  fi
}

PBXPROJ="$ROOT/Poof.xcodeproj/project.pbxproj"
if [[ ! -f "$PBXPROJ" ]]; then
  die "Missing project file: $PBXPROJ"
fi

if [[ -z "$VERSION" ]]; then
  CURRENT_VERSION="$(rg -m1 "MARKETING_VERSION = " "$PBXPROJ" | sed 's/.*= //; s/;//')"
  IFS='.' read -r MAJOR MINOR PATCH REST <<< "$CURRENT_VERSION"
  if [[ -z "$MAJOR" || -z "$MINOR" || -z "$PATCH" || -n "$REST" ]]; then
    die "Expected semantic MARKETING_VERSION (x.y.z), got: $CURRENT_VERSION"
  fi
  if [[ ! "$MAJOR" =~ ^[0-9]+$ || ! "$MINOR" =~ ^[0-9]+$ || ! "$PATCH" =~ ^[0-9]+$ ]]; then
    die "Expected numeric semantic MARKETING_VERSION (x.y.z), got: $CURRENT_VERSION"
  fi
  VERSION="${MAJOR}.${MINOR}.$((PATCH + 1))"
fi

if [[ ! "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  die "VERSION must be semantic (x.y.z), got: $VERSION"
fi

BUILD="$(git -C "$ROOT" rev-list --count HEAD 2>/dev/null || true)"
if [[ -z "$BUILD" ]]; then
  die "Unable to compute build number from git history."
fi
if [[ -n "$BUILD_OVERRIDE" ]]; then
  if [[ ! "$BUILD_OVERRIDE" =~ ^[0-9]+$ ]]; then
    die "BUILD_OVERRIDE must be an integer."
  fi
  BUILD="$BUILD_OVERRIDE"
fi

VERSION="$VERSION" BUILD="$BUILD" ruby -pi -e '
  gsub(/MARKETING_VERSION = [^;]+;/, "MARKETING_VERSION = #{ENV.fetch("VERSION")};")
  gsub(/CURRENT_PROJECT_VERSION = [^;]+;/, "CURRENT_PROJECT_VERSION = #{ENV.fetch("BUILD")};")
' "$PBXPROJ"

require_cmd xcodebuild
require_cmd xcrun
require_cmd codesign
require_cmd ditto

ARCHIVE_DIR="$ROOT/build/Poof.xcarchive"
rm -rf "$ARCHIVE_DIR"

xcodebuild \
  -project "$ROOT/Poof.xcodeproj" \
  -scheme "Poof" \
  -configuration Release \
  -destination "generic/platform=macOS" \
  -archivePath "$ARCHIVE_DIR" \
  ARCHS="arm64 x86_64" \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGNING_ALLOWED=NO \
  clean archive

APP="$ARCHIVE_DIR/Products/Applications/Poof.app"
if [[ ! -d "$APP" ]]; then
  die "Missing built app: $APP"
fi

resolve_signing_identity() {
  if [[ -n "${DEVELOPER_ID_APPLICATION:-}" ]]; then
    echo "$DEVELOPER_ID_APPLICATION"
    return 0
  fi

  local identity_line=""
  identity_line="$(security find-identity -v -p codesigning 2>/dev/null | rg -m1 "Developer ID Application:" || true)"
  if [[ -z "$identity_line" ]]; then
    return 1
  fi

  echo "$identity_line" | awk '{print $2}'
}

resign_nested() {
  local identity="$1"
  local sparkle="$APP/Contents/Frameworks/Sparkle.framework"

  local sign=(
    /usr/bin/codesign
    --force
    --options runtime
    --timestamp
    --preserve-metadata=entitlements
    --sign "$identity"
  )

  if [[ -d "$sparkle" ]]; then
    local sparkle_ver="$sparkle/Versions/Current"
    local xpc_dir="$sparkle_ver/XPCServices"
    local sign_targets=(
      "$xpc_dir/Downloader.xpc"
      "$xpc_dir/Installer.xpc"
      "$sparkle_ver/Updater.app"
      "$sparkle_ver/Autoupdate"
      "$sparkle_ver/Sparkle"
    )

    for item in "${sign_targets[@]}"; do
      [[ -e "$item" ]] && "${sign[@]}" "$item"
    done

    "${sign[@]}" "$sparkle"
  fi

  "${sign[@]}" "$APP"
}

SIGNING_IDENTITY="$(resolve_signing_identity || true)"
if [[ -z "$SIGNING_IDENTITY" ]]; then
  die "Developer ID Application identity not found. Set DEVELOPER_ID_APPLICATION."
fi

resign_nested "$SIGNING_IDENTITY"

if [[ -z "$SKIP_NOTARIZE" ]]; then
  TMPDIR="$(mktemp -d)"
  trap 'rm -rf "$TMPDIR"' EXIT
  SUBMIT_ZIP="$TMPDIR/Poof-notary-${VERSION}-${BUILD}.zip"
  ditto -c -k --sequesterRsrc --keepParent "$APP" "$SUBMIT_ZIP"
  xcrun notarytool submit "$SUBMIT_ZIP" --wait --keychain-profile "$NOTARYTOOL_PROFILE"
  xcrun stapler staple "$APP"
fi

OUTDIR="$ROOT/dist"
mkdir -p "$OUTDIR"
ZIP="$OUTDIR/Poof-${VERSION}-${BUILD}.zip"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
SHA256="$(shasum -a 256 "$ZIP" | awk '{print $1}')"

META="$OUTDIR/release.json"
printf '{ "version": "%s", "build": "%s", "zip": "%s", "sha256": "%s", "tag": "%s" }\n' \
  "$VERSION" "$BUILD" "$ZIP" "$SHA256" "v${VERSION}" > "$META"

echo "Release metadata: $META"
echo "Release package ready: $ZIP"
