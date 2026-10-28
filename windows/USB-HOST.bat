@echo off
title USB -> HOST (reconocer pendrives/teclados)
net session >nul 2>&1 || (powershell -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)
echo.
echo  ==========================================================
echo   PASANDO USB A MODO **HOST**
echo   Podras usar pendrives, teclados y raton por USB.
echo.
echo   AVISO: en modo HOST el movil GENERA 5V hacia fuera.
echo   NO conectes el cable al PC ni el cargador estando asi:
echo   dos fuentes de 5V pueden danar el movil.
echo   Para cargar, usa USB-DEVICE.bat o apaga Windows.
echo  ==========================================================
echo.
powershell -ExecutionPolicy Bypass -File "C:\op7\usb-mode.ps1" host
echo.
pause
