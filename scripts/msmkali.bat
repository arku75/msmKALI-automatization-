@echo off
REM msmkali.bat — lanzador Windows (ES/EN). Requiere Python o WSL para lo serio.
REM Uso: msmkali.bat [es|en] | msmkali.bat check
set LANG=%1
if "%LANG%"=="" set LANG=es
if "%LANG%"=="check" (
  powershell -ExecutionPolicy Bypass -File "%~dp0msmkali.ps1" -Lang es -Check
  goto :eof
)
where python >nul 2>&1
if %errorlevel%==0 (
  python "%~dp0msmkali.py" --lang %LANG%
  goto :eof
)
powershell -ExecutionPolicy Bypass -File "%~dp0msmkali.ps1" -Lang %LANG%
