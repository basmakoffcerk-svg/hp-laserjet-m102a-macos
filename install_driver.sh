#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PPD_FILE="$DIR/HP_LaserJet_Pro_M102a.ppd"
TARGET_PPD="/Library/Printers/PPDs/Contents/Resources/HP_LaserJet_Pro_M102a.ppd"
PRINTER_NAME="HP_LaserJet_Pro_M102a"
DISPLAY_NAME="HP LaserJet Pro M102a"

echo "=== Установка кастомного драйвера для HP LaserJet Pro M102a ==="

# 1. Проверка PPD файла
if [ ! -f "$PPD_FILE" ]; then
    echo "Ошибка: Файл PPD не найден в $PPD_FILE"
    exit 1
fi

echo "1. Проверка PPD через cupstestppd..."
cupstestppd "$PPD_FILE"

# 2. Копирование PPD в системную директорию (если есть права) или использование напрямую
if [ "$EUID" -eq 0 ] || sudo -n true 2>/dev/null; then
    echo "2. Копирование PPD в /Library/Printers/PPDs/Contents/Resources/..."
    sudo mkdir -p /Library/Printers/PPDs/Contents/Resources
    sudo cp "$PPD_FILE" "$TARGET_PPD"
    sudo chmod 644 "$TARGET_PPD"
    ACTIVE_PPD="$TARGET_PPD"
else
    ACTIVE_PPD="$PPD_FILE"
fi

# 3. Определение URI принтера
DEVICE_URI="ippusb://HP%20LaserJet%20M102a%20(000001)._ipp._tcp.local./?uuid=564e4333-5438-3337-3934-000000000001"

echo "3. Настройка очереди CUPS ($PRINTER_NAME)..."
lpadmin -p "$PRINTER_NAME" -E -v "$DEVICE_URI" -P "$ACTIVE_PPD" -D "$DISPLAY_NAME" -o printer-is-shared=false
lpadmin -p "$PRINTER_NAME" -o PageSize=A4 -o Resolution=600dpi -o HPTonerSave=False
cupsenable "$PRINTER_NAME"
cupsaccept "$PRINTER_NAME"
lpadmin -d "$PRINTER_NAME"

echo ""
echo "=== Установка успешно завершена! ==="
echo "Принтер '$PRINTER_NAME' установлен по умолчанию."
echo "Проверка очереди: lpstat -p $PRINTER_NAME"
lpstat -p "$PRINTER_NAME"
