#!/bin/bash
PRINTER="HP_LaserJet_Pro_M102a"

echo "Отправка тестовой страницы на $PRINTER..."
if lpstat -p "$PRINTER" >/dev/null 2>&1; then
    lp -d "$PRINTER" /usr/share/cups/data/testprint
    echo "Задание отправлено в очередь!"
else
    echo "Принтер $PRINTER не найден в CUPS. Сначала запустите ./install_driver.sh"
fi
