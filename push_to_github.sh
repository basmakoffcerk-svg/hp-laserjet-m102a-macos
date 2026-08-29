#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "=== Отправка проекта на GitHub ==="
git remote set-url origin https://github.com/basmakoffcerk-svg/hp-laserjet-m102a-macos.git
git branch -M main

echo "Выполняю git push -u origin main..."
git push -u origin main

echo ""
echo "=== Успешно отправлено в репозиторий: ==="
echo "https://github.com/basmakoffcerk-svg/hp-laserjet-m102a-macos"
