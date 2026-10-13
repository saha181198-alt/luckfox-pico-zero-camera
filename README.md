# Pico Zero: CVBS/UVC → ST7735

Готовый комплект сборки для **Luckfox Pico Zero 40-pin на RV1106G3**:
CVBS-камера через USB UVC/MJPEG-конвертер выводится на ST7735 в альбомном
режиме 160×128.

Полная пошаговая инструкция на русском языке: [README_RU.md](README_RU.md).
Что уже проверено без физической платы: [VALIDATION.md](VALIDATION.md).

Для автоматической сборки откройте на GitHub вкладку **Actions** и запустите
workflow **Build Pico Zero UVC to ST7735 firmware**. Результат — `update.img`
для прошивки встроенной eMMC.

Для сбоя USB `Cannot enable` подготовлен отдельный профиль `usb_debug`:
[сохранение системы и диагностика USB Host](docs/USB_HOST_DIAGNOSTICS_RU.md).
