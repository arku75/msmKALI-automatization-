#!/system/bin/sh
# ============================================================================
#  Diagnóstico del aviso "NV Backup warning: Invalid VIP NVs"
#  NO TOCA NADA. Solo mira y hace BACKUP del estado bueno actual.
# ============================================================================
BK=/data/local/tmp/nv-backup-$(date +%Y%m%d_%H%M%S)
mkdir -p $BK

echo "=========================================================="
echo " 1. BACKUP FRESCO del estado ACTUAL (que FUNCIONA)"
echo "=========================================================="
for P in modemst1 modemst2 fsc fsg persist; do
  if [ -e /dev/block/by-name/$P ]; then
    dd if=/dev/block/by-name/$P of=$BK/$P.img bs=1M 2>/dev/null
    echo "  $P -> $(md5sum $BK/$P.img | cut -d' ' -f1)"
  fi
done
echo "  guardado en: $BK"

echo
echo "=========================================================="
echo " 2. EL MENSAJE COMPLETO: ¿QUÉ NVs concretos se quejan?"
echo "=========================================================="
logcat -d 2>/dev/null | grep -iE "vip nv|nv backup|nvbackup|invalid.*nv" | tail -15
echo "-- ¿qué app lo lanza? --"
pm list packages 2>/dev/null | grep -iE "nvbackup|oem_nv|engineer|qualcomm" | sed 's/package://'
echo "-- notificaciones activas con 'NV' --"
dumpsys notification --noredact 2>/dev/null | grep -iA3 "NV Backup" | head -20

echo
echo "=========================================================="
echo " 3. ¿AFECTA A ALGO REAL? (lo que importa de verdad)"
echo "=========================================================="
echo "-- IMEI --"
service call iphonesubinfo 4 2>/dev/null | cut -d\' -f2 | tr -d '.[:space:]' | head -1
getprop | grep -iE "imei|meid" | head -3
echo "-- MAC WiFi (uno de los VIP NV típicos) --"
ip link show wlan0 2>/dev/null | grep ether | awk '{print "   wlan0: "$2}'
cat /sys/class/net/wlan0/address 2>/dev/null | sed 's/^/   sysfs: /'
echo "-- MAC Bluetooth --"
settings get secure bluetooth_address 2>/dev/null | sed 's/^/   BT: /'
echo "-- Radio / red --"
getprop gsm.operator.alpha | sed 's/^/   operador: /'
getprop gsm.network.type  | sed 's/^/   tipo red: /'
getprop gsm.sim.state     | sed 's/^/   SIM: /'
echo "-- señal --"
dumpsys telephony.registry 2>/dev/null | grep -m2 -iE "mSignalStrength|rssi" | head -2

echo
echo "=========================================================="
echo " VEREDICTO: si IMEI + MACs + operador salen BIEN, el aviso"
echo " es COSMÉTICO (un checksum de OnePlus que no cuadra) y"
echo " tocar los NV es MÁS peligroso que dejarlo."
echo "=========================================================="
