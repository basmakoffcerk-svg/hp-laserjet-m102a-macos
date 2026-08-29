#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

TAG="v1.0.0"
TITLE="HP LaserJet Pro M102a macOS Driver & Menu Bar Manager v1.0.0"
NOTES_FILE="$DIR/RELEASE_NOTES.md"
ASSET_PKG="$DIR/HP_LaserJet_Pro_M102a_Driver.pkg"
ASSET_ZIP="$DIR/HP_LaserJet_Manager_v1.0.0_macOS.zip"
ASSET_PPD="$DIR/HP_LaserJet_Pro_M102a.ppd"

echo "=== Создание релиза $TAG на GitHub ==="

if which gh >/dev/null 2>&1; then
    echo "Создаю релиз через GitHub CLI (gh)..."
    gh release create "$TAG" \
        "$ASSET_PKG" \
        "$ASSET_ZIP" \
        "$ASSET_PPD" \
        --title "$TITLE" \
        --notes-file "$NOTES_FILE"
    echo "Релиз $TAG успешно создан и опубликован!"
else
    echo "GitHub CLI не найден. Создайте релиз вручную на https://github.com/basmakoffcerk-svg/hp-laserjet-m102a-macos/releases/new"
fi
