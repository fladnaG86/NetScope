#!/bin/bash
# Build NetScope.app (proper macOS bundle), ad-hoc codesign with entitlements, and run.
#
# IMPORTANT: do NOT run the bare SPM executable (.build/debug/NetScope or
# .build/out/Products/Debug/NetScope) directly. A bare executable launched
# from Terminal is not registered as a key GUI app, so the window appears
# but keystrokes never reach TextFields (cursor enters, zero characters).
# Always build the .app bundle and launch via `open` (LaunchServices activation).
set -e
cd "$(dirname "$0")"

# Regenerate Xcode project from project.yml (idempotent)
xcodegen generate >/dev/null

# Build .app bundle (unsigned during build; sign the bundle after)
xcodebuild -project NetScope.xcodeproj -scheme NetScope -configuration Debug \
  -derivedDataPath ./DerivedData -destination 'platform=macOS' \
  build CODE_SIGNING_ALLOWED=NO >/dev/null

APP=./DerivedData/Build/Products/Debug/NetScope.app

# Ad-hoc sign the bundle with entitlements (sandbox off + network.client/server)
codesign --force --entitlements NetScope/Resources/NetScope.entitlements --sign - "$APP"

echo ""
echo "✅ Build complete: $APP"
echo "Run with: open \"$APP\""