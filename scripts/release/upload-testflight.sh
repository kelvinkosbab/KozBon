#!/bin/bash
#
# Archive, export, and upload one platform to TestFlight.
#
#   scripts/release/upload-testflight.sh ios|macos|visionos [--dry-run]
#
# Every platform is its own archive, its own export, and its own
# upload — a single archive cannot serve more than one. Build
# numbers are tracked per platform by App Store Connect, so they
# don't collide across them.
#
# Requires, none of which this script can create for you:
#   - An Apple Distribution certificate in the login keychain.
#   - An App Store provisioning profile for the platform.
#   - macOS only: a Mac Installer Distribution certificate. A Mac
#     App Store submission is a signed .pkg, not an .app.
#   - An App Store Connect API key at
#     ~/.appstoreconnect/private_keys/AuthKey_<KEY_ID>.p8, with
#     ASC_KEY_ID and ASC_ISSUER_ID exported.

set -euo pipefail

PLATFORM="${1:-}"
DRY_RUN="${2:-}"

case "$PLATFORM" in
    ios)      DESTINATION="generic/platform=iOS";      ALTOOL_TYPE="ios" ;;
    macos)    DESTINATION="generic/platform=macOS";    ALTOOL_TYPE="macos" ;;
    visionos) DESTINATION="generic/platform=visionOS"; ALTOOL_TYPE="visionos" ;;
    *)
        echo "usage: $0 ios|macos|visionos [--dry-run]" >&2
        exit 2
        ;;
esac

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BUILD_DIR="$REPO_ROOT/build/$PLATFORM"
ARCHIVE_PATH="$BUILD_DIR/KozBon.xcarchive"
EXPORT_OPTIONS="$REPO_ROOT/scripts/release/ExportOptions-$PLATFORM.plist"

cd "$REPO_ROOT"

# A TestFlight build you later have to debug must trace back to a
# known commit, so refuse to ship from a dirty tree.
if [ -n "$(git status --porcelain)" ]; then
    echo "error: working tree is dirty — commit or stash first." >&2
    git status --short >&2
    exit 1
fi

COMMIT="$(git rev-parse --short HEAD)"
echo "==> $PLATFORM from $COMMIT using $(xcodebuild -version | head -1)"

rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

echo "==> Archiving"
xcodebuild archive \
    -workspace KozBon.xcworkspace \
    -scheme KozBon \
    -destination "$DESTINATION" \
    -archivePath "$ARCHIVE_PATH" \
    -allowProvisioningUpdates

echo "==> Exporting"
xcodebuild -exportArchive \
    -archivePath "$ARCHIVE_PATH" \
    -exportOptionsPlist "$EXPORT_OPTIONS" \
    -exportPath "$BUILD_DIR" \
    -allowProvisioningUpdates

# iOS and visionOS export an .ipa; the Mac App Store takes a .pkg.
ARTIFACT="$(find "$BUILD_DIR" -maxdepth 1 \( -name '*.ipa' -o -name '*.pkg' \) | head -1)"
if [ -z "$ARTIFACT" ]; then
    echo "error: export produced no .ipa or .pkg in $BUILD_DIR" >&2
    exit 1
fi
echo "==> Built $(basename "$ARTIFACT")"

if [ "$DRY_RUN" = "--dry-run" ]; then
    echo "==> Dry run: validating instead of uploading"
    xcrun altool --validate-app \
        --type "$ALTOOL_TYPE" \
        --file "$ARTIFACT" \
        --apiKey "${ASC_KEY_ID:?set ASC_KEY_ID}" \
        --apiIssuer "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"
    exit 0
fi

echo "==> Uploading to App Store Connect"
xcrun altool --upload-app \
    --type "$ALTOOL_TYPE" \
    --file "$ARTIFACT" \
    --apiKey "${ASC_KEY_ID:?set ASC_KEY_ID}" \
    --apiIssuer "${ASC_ISSUER_ID:?set ASC_ISSUER_ID}"

echo "==> Uploaded. Processing usually takes 5-30 minutes."
