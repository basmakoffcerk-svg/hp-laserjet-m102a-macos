# HP LaserJet Pro M102a (M101–M106) macOS Driver & Menu Bar Manager

[![macOS](https://img.shields.io/badge/macOS-12%20%7C%2013%20%7C%2014%20%7C%2015+-blue.svg)](https://apple.com/macos)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![CUPS Compliant](https://img.shields.io/badge/CUPS-PPD%20Passed-brightgreen.svg)](HP_LaserJet_Pro_M102a.ppd)

Кастомный рабочий драйвер и нативная утилита для строки меню macOS (Menu Bar App) для лазерного принтера **HP LaserJet Pro M102a** (серия HP LaserJet M101–M106).

> **Проблема, которую решает этот проект:**  
> На современных версиях macOS (macOS 12 Monterey, 13 Ventura, 14 Sonoma, 15 Sequoia и новее) официальный онлайн-установщик *HP Easy Start* не может загрузить устаревшие пакеты, а стандартный AirPrint/IPP-over-USB выдает ошибку **`URP Error`** или зависает в очереди из-за некорректных форматов растрирования.
> 
> Этот репозиторий предоставляет проверенный PPD-профиль с откалиброванным 8-битным растром **UNIRAST v1.4 / sGray (CUPS ColorSpace 18)**, готовый `.pkg` инсталлятор и нативное приложение для строки меню macOS.

---

## 🚀 Возможности

* 🖨 **Кастомный PPD-профиль**:
  * 100% соответствие спецификации CUPS (`cupstestppd` PASS).
  * Поддержка режимов качества: **Draft (EconoMode / Экономия тонера)**, **Normal (600 DPI)**, **High (FastRes 1200 DPI)**.
  * Точные аппаратные границы печати для A4, Letter, Legal, Executive, A5, A6, JIS B5 и конвертов (DL, C5, #10).
* 📦 **Готовый инсталлятор `.pkg`**:
  * Установка драйвера и автоматическая настройка очереди печати в один клик.
* 🖥 **Нативное приложение для строки меню (`HP LaserJet Manager.app`)**:
  * Светодиодный индикатор статуса в строке меню: 🟢 Готов / 🟠 Идет печать / 🔴 Отключен.
  * Мониторинг и управление очередью (просмотр активных заданий, отмена отдельного документа или очистка очереди).
  * Быстрая печать тестовой страницы в 1 клик.
  * Диагностика USB и состояния службы CUPS.
  * Функция «Запускать при входе в macOS».

---

## 📥 Установка

### Вариант 1: Через установщик `.pkg` (Рекомендуется)
1. Скачайте файл [`HP_LaserJet_Pro_M102a_Driver.pkg`](HP_LaserJet_Pro_M102a_Driver.pkg).
2. Запустите его двойным кликом и следуйте инструкциям установщика.
3. Принтер `HP_LaserJet_Pro_M102a` автоматически появится в системе и станет принтером по умолчанию.

### Вариант 2: Через терминал
Клонируйте репозиторий и запустите установочный скрипт:
```bash
git clone https://github.com/basmakoffcerk-svg/hp-laserjet-m102a-macos.git
cd hp-laserjet-m102a-macos
./install_driver.sh
```

---

## 🛠 Запуск утилиты строки меню

Для запуска утилиты управления принтером:
```bash
open "HP LaserJet Manager.app"
```
Приложение появится в правом верхнем углу строки меню macOS (рядом с часами). В выпадающем меню вы можете включить *«Запускать при входе в macOS»*.

---

## 🏗 Сборка из исходников

Если вы хотите пересобрать пакеты или приложение самостоятельно:

1. **Сборка `.pkg` инсталлятора:**
   ```bash
   ./build_pkg.sh
   ```

2. **Компиляция Menu Bar приложения из Swift:**
   ```bash
   ./build_app.sh
   ```

3. **Проверка PPD-файла:**
   ```bash
   cupstestppd HP_LaserJet_Pro_M102a.ppd
   ```

---

## 📄 Структура проекта

```text
├── HP_LaserJet_Pro_M102a.ppd         # Валидированный PPD-профиль для CUPS
├── HP_LaserJet_Pro_M102a_Driver.pkg  # Готовый установщик для macOS
├── HP LaserJet Manager.app          # Скомпилированное приложение для строки меню
├── src/
│   └── main.swift                   # Исходный код Menu Bar приложения на Swift/AppKit
├── install_driver.sh                # Скрипт быстрой установки и привязки к CUPS
├── build_pkg.sh                     # Скрипт генерации .pkg через pkgbuild
├── build_app.sh                     # Скрипт компиляции Swift-приложения
├── print_test_page.sh               # Утилита отправки тестовой печати
├── README.md                        # Документация проекта
└── LICENSE                          # MIT Лицензия
```

---

## 📜 Лицензия
Проект распространяется под свободной лицензией [MIT](LICENSE).
