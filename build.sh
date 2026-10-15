#!/bin/zsh
set -euo pipefail

APP="outputs/Clair.app"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources" /private/tmp/clair-clang-cache
cp Resources/Info.plist "$APP/Contents/Info.plist"
CLANG_MODULE_CACHE_PATH=/private/tmp/clair-clang-cache clang -fobjc-arc -framework Cocoa Sources/ClairObjectiveC/main.m -o "$APP/Contents/MacOS/Clair"
xattr -cr "$APP"
codesign --force --deep --sign - "$APP"
echo "Application prête : $APP"
