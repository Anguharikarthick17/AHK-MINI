#!/usr/bin/env bash
set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="AHKMini"
BUILD_DIR="${PROJECT_DIR}/build/Release"
APP_BUNDLE="${BUILD_DIR}/${APP_NAME}.app"
CONTENTS_DIR="${APP_BUNDLE}/Contents"
MACOS_DIR="${CONTENTS_DIR}/MacOS"
RESOURCES_DIR="${CONTENTS_DIR}/Resources"

echo "=== Building AHK Mini (Release) ==="

# Clean build directory
rm -rf "${BUILD_DIR}"
mkdir -p "${MACOS_DIR}"
mkdir -p "${RESOURCES_DIR}"

# Find all Swift source files in AHKMini
SOURCES=()
while IFS= read -r file; do
    SOURCES+=("$file")
done < <(find "${PROJECT_DIR}/AHKMini" -name "*.swift" | sort)

# Compile optimized Release binary
echo "Compiling ${#SOURCES[@]} Swift sources with optimizations (-O)..."
swiftc \
    -O \
    -target arm64-apple-macos12.0 \
    -framework AppKit \
    -framework SpriteKit \
    "${SOURCES[@]}" \
    -o "${MACOS_DIR}/${APP_NAME}"

# Copy Info.plist
cp "${PROJECT_DIR}/AHKMini/App/Info.plist" "${CONTENTS_DIR}/Info.plist"

# Copy entitlements if present
if [ -f "${PROJECT_DIR}/AHKMini/App/AHKMini.entitlements" ]; then
    cp "${PROJECT_DIR}/AHKMini/App/AHKMini.entitlements" "${CONTENTS_DIR}/"
fi

# Copy Assets if present
if [ -d "${PROJECT_DIR}/AHKMini/Resources/Assets.xcassets" ]; then
    cp -R "${PROJECT_DIR}/AHKMini/Resources/Assets.xcassets" "${RESOURCES_DIR}/"
fi

# Copy AppIcon.icns if present
if [ -f "${PROJECT_DIR}/AHKMini/Resources/AppIcon.icns" ]; then
    cp "${PROJECT_DIR}/AHKMini/Resources/AppIcon.icns" "${RESOURCES_DIR}/"
fi

# Ad-hoc code signing
echo "Signing application bundle..."
codesign --force --deep --sign - "${APP_BUNDLE}"

echo "=== Build Successful ==="
echo "Application created at: ${APP_BUNDLE}"

# If requested to launch
if [ "$1" == "--launch" ] || [ "$1" == "run" ]; then
    echo "Launching ${APP_NAME}..."
    open "${APP_BUNDLE}"
fi
