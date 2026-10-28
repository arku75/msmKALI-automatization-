<# ============================================================================
  msmkali.ps1 — dispatcher Windows (ES/EN) para msmKALI
  No flashea desde Windows: guia + USB mode + deriva a WSL/Linux.
  Uso: powershell -ExecutionPolicy Bypass -File scripts\msmkali.ps1 -Lang es
============================================================================>
param([string]$Lang = "es", [switch]$Check)

$es = @{
  title="msmKALI · OnePlus 7 Pro (GM1913 / guacamole)";
  need="Necesitas Linux para flashear/EDL. Usa WSL2 + Ubuntu o un USB Kali.";
  usb="Usa windows\usb-mode.ps1 host|device|estado para el rol USB.";
  wsl="Abriendo WSL hacia scripts/msmkali.sh si existe..."
  check="Comprobando herramientas Windows..."
}
$en = @{
  title="msmKALI · OnePlus 7 Pro (GM1913 / guacamole)";
  need="You need Linux to flash/EDL. Use WSL2 + Ubuntu or a Kali USB.";
  usb="Use windows\usb-mode.ps1 host|device|estado for USB role.";
  wsl="Opening WSL to scripts/msmkali.sh if available..."
  check="Checking Windows tools..."
}
$S = if ($Lang -eq "en") { $en } else { $es }
Write-Output $S.title
Write-Output $S.need
Write-Output $S.usb
if ($Check) {
  Write-Output $S.check
  foreach ($t in @("adb.exe","fastboot.exe","wsl.exe","pnputil.exe")) {
    $f = Get-Command $t -ErrorAction SilentlyContinue
    if ($f) { Write-Output "  OK $($t)" } else { Write-Output "  FALTA/MISSING $($t)" }
  }
  & "$PSScriptRoot\..\windows\usb-mode.ps1" estado
  exit 0
}
Write-Output $S.wsl
$sh = Join-Path $PSScriptRoot "msmkali.sh"
if (Get-Command wsl.exe -ErrorAction SilentlyContinue) {
  wsl.exe bash "$(wsl.exe wslpath $sh)" 2>$null
  if ($LASTEXITCODE -ne 0) { Write-Output $S.need }
} else {
  Write-Output $S.need
}
