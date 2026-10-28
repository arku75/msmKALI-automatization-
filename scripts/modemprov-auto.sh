#!/system/bin/sh
# ============================================================================
#  modemprov-auto  ·  OnePlus 7 Pro (GM1913) — Android + Windows 11 ARM
#  Mantiene el PROVISIONING DEL MODEM de Windows sincronizado con el de Android.
#
#  POR QUE: el driver qcremotefs8150 de Windows guarda el remote-FS del modem en
#  bootmodem_fs1/2. Si no coincide con modemst1/2 de Android el modem NO REGISTRA
#  en Windows -> Signal 0%, netsh mbn connect = 0x139f. (Diagnosticado 20-ago-2026.)
#
#  POR QUE AUTOMATICO Y NO UNA VEZ (medido): Android REESCRIBE modemst
#  constantemente (cambio detectado en 3 minutos), asi que una copia manual
#  -como la del modemprov.zip original- se queda vieja enseguida.
#
#  SEGURIDAD:
#   - solo LEE modemst (nunca escribe al modem; IMEI intacto)
#   - aborta si el NTFS esta sucio (Windows hibernado)
#   - ESCRITURA ATOMICA (tmp + mv): un apagado a media copia no deja el fichero roto
#   - verifica por md5 y revierte si falla
# ============================================================================
LOG=/data/adb/modemprov-auto.log
MP=/data/local/tmp/win-auto
LOCK=/data/adb/.modemprov.lock
INTERVALO=1800     # refresco periodico: 30 min

exec >> $LOG 2>&1
[ -f "$LOCK" ] && kill -0 "$(cat $LOCK 2>/dev/null)" 2>/dev/null && { echo "ya hay una instancia viva"; exit 0; }
echo $$ > $LOCK

recorta_log() { [ "$(wc -l < $LOG 2>/dev/null || echo 0)" -gt 400 ] && { tail -200 $LOG > $LOG.tmp; mv $LOG.tmp $LOG; }; }

sincronizar() {
  WIN=/dev/block/by-name/win
  [ -e "$WIN" ] || { echo "no hay particion win"; return 0; }
  umount $MP 2>/dev/null; mkdir -p $MP
  OUT=$(mount.ntfs $WIN $MP 2>&1)
  if echo "$OUT" | grep -qi "unclean"; then
    echo "ABORTADO: NTFS sucio (Windows hibernado). No se toca."; umount $MP 2>/dev/null; return 0
  fi
  mount | grep -q "$MP" || { echo "ABORTADO: no se pudo montar win ($OUT)"; return 0; }

  P=$(find $MP/Windows/System32/DriverStore/FileRepository -maxdepth 1 -name "qcremotefs8150.inf_arm64_*" 2>/dev/null | head -1)
  [ -n "$P" ] || { echo "ABORTADO: no existe el driver qcremotefs8150"; umount $MP 2>/dev/null; return 0; }

  CAMBIOS=0
  for N in 1 2; do
    SRC=/dev/block/by-name/modemst$N
    DST="$P/bootmodem_fs$N"
    MS=$(dd if=$SRC bs=8388608 2>/dev/null | md5sum | cut -d' ' -f1)
    MD=$(md5sum "$DST" 2>/dev/null | cut -d' ' -f1)
    if [ "$MS" = "$MD" ]; then
      echo "fs$N sincronizado ($MS)"
    else
      echo "fs$N DIFIERE: win=$MD android=$MS -> copiando (atomico)"
      TMP="$P/.bootmodem_fs$N.tmp"
      dd if=$SRC of="$TMP" bs=8388608 2>/dev/null; sync
      NEW=$(md5sum "$TMP" 2>/dev/null | cut -d' ' -f1)
      if [ "$NEW" = "$MS" ]; then
        cp "$DST" "$P/bootmodem_fs$N.antes" 2>/dev/null
        mv "$TMP" "$DST" && sync && { echo "fs$N OK verificado"; CAMBIOS=$((CAMBIOS+1)); } \
                         || echo "fs$N FALLO en el mv (original intacto)"
      else
        echo "fs$N copia corrupta -> descartada (original intacto)"; rm -f "$TMP"
      fi
    fi
  done
  sync
  umount $MP 2>/dev/null && echo "win desmontado limpio" || echo "AVISO: no se desmonto"
  echo "fin (cambios=$CAMBIOS)"
}

echo "===== $(date) · arranque ====="
i=0; while [ "$(getprop sys.boot_completed)" != "1" ] && [ $i -lt 60 ]; do sleep 5; i=$((i+1)); done
sleep 10
sincronizar
recorta_log

# refresco periodico: modemst cambia mientras Android corre
while true; do
  sleep $INTERVALO
  echo "----- $(date) · refresco -----"
  sincronizar
  recorta_log
done
