#!/bin/bash
# Build and codesign NetScope with entitlements
set -e
cd "$(dirname "$0")"
swift build
codesign --force --entitlements NetScope/Resources/NetScope.entitlements --sign - .build/debug/NetScope
echo ""
echo "✅ Build complete. Run with: .build/debug/NetScope"