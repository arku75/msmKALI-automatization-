@echo off
title USB -> DEVICE (conectar al PC / cargar)
net session >nul 2>&1 || (powershell -Command "Start-Process '%~f0' -Verb RunAs" & exit /b)
echo.
echo  ==========================================================
echo   PASANDO USB A MODO **DEVICE**  (modo seguro)
echo   El movil se comporta como periferico: se conecta al PC
echo   y es seguro enchufar el cargador.
echo.
echo   NOTA: en Windows la carga NO funciona (desactivada por
echo   el port por BSoD). Para cargar de verdad: Android.
echo  ==========================================================
echo.
powershell -ExecutionPolicy Bypass -File "C:\op7\usb-mode.ps1" device
echo.
pause
