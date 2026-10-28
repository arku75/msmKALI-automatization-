# ============================================================================
#  usb-mode.ps1 - Cambia el rol USB del OnePlus 7 Pro en Windows 11 ARM
#  Receta extraida del binario oficial USB_Mode_Control_V9.4 (WOA-Tools):
#     clave : SYSTEM\CurrentControlSet\Enum\ACPI\QCOM0597\0\Device Parameters
#     valor : RoleSwitchMode (DWORD)   1 = HOST   2 = DEVICE   (3 = auto/desconocido)
#     aplica: pnputil /restart-device "ACPI\QCOM0597\0"
#
#  AVISO DEL PORT: en modo HOST no conectes un hub USB ALIMENTADO ni el cable a
#  un PC/cargador: dos fuentes de 5V enfrentadas pueden danar el movil.
#
#  uso: usb-mode.ps1 host | device | estado
# ============================================================================
param([string]$modo = "estado")
$k = "HKLM:\SYSTEM\CurrentControlSet\Enum\ACPI\QCOM0597\0\Device Parameters"
$nombres = @{1="HOST (reconoce USB que enchufes)"; 2="DEVICE (se comporta como periferico)"; 3="auto/dual (por defecto del port)"}

if (-not (Test-Path $k)) { Write-Output "ERROR: no existe el controlador ACPI\QCOM0597\0"; exit 1 }
$actual = (Get-ItemProperty $k -Name RoleSwitchMode -ErrorAction SilentlyContinue).RoleSwitchMode
if ($null -eq $actual) { $actual = -1 }
$desc = $nombres[[int]$actual]; if (-not $desc) { $desc = "desconocido" }

switch ($modo.ToLower()) {
  "estado" {
    Write-Output "RoleSwitchMode actual = $actual  ->  $desc"
    Write-Output "-- dispositivos USB que ve Windows ahora --"
    Get-PnpDevice -Class USB -ErrorAction SilentlyContinue | Select-Object Status,FriendlyName | Format-Table -Auto | Out-String -Width 90
  }
  default {
    $nuevo = if ($modo.ToLower() -eq "host") {1} elseif ($modo.ToLower() -eq "device") {2} else {0}
    if ($nuevo -eq 0) { Write-Output "uso: usb-mode.ps1 host | device | estado"; exit 1 }
    # backup del valor actual antes de tocar
    $bk = "C:\op7\usb-mode-backup.txt"
    New-Item -ItemType Directory -Force -Path C:\op7 | Out-Null
    "$(Get-Date -Format s) RoleSwitchMode anterior = $actual" | Add-Content $bk
    Set-ItemProperty -Path $k -Name RoleSwitchMode -Value $nuevo -Type DWord
    $ver = (Get-ItemProperty $k -Name RoleSwitchMode).RoleSwitchMode
    Write-Output "RoleSwitchMode: $actual -> $ver  ($($nombres[[int]$ver]))"
    if ($ver -ne $nuevo) { Write-Output "ERROR: no se escribio bien"; exit 1 }
    Write-Output "-- aplicando (reinicio del controlador, sin reiniciar Windows) --"
    $pnp = Join-Path ([Environment]::GetFolderPath(37)) "pnputil.exe"
    if (-not (Test-Path $pnp)) { $pnp = "pnputil.exe" }
    & $pnp /restart-device "ACPI\QCOM0597\0" 2>&1 | Select-Object -Last 3
    Write-Output "-- estado despues --"
    Get-PnpDevice -Class USB -ErrorAction SilentlyContinue | Select-Object Status,FriendlyName | Format-Table -Auto | Out-String -Width 90
  }
}
