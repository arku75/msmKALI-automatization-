#!/bin/bash
# ============================================================================
#  RESCATE POR EDL — OnePlus 7 Pro (GM1913 "guacamole")
#  Escrito el 15-ago-2026 tras rescatar el móvil de un Qualcomm CrashDump.
#
#  QUÉ HACE: reescribe la partición boot (uno o los dos slots) con una imagen
#  buena, SIN borrar nada más. Salva un móvil que no arranca por un kernel malo
#  conservando Windows, userdata, IMEI y particionado.
#
#  CUÁNDO USARLO: el móvil no arranca (CrashDump / pantalla negra / bucle) y no
#  entra ni en fastboot ni en recovery. Si fastboot SÍ entra, usa fastboot: es
#  más simple. Esto es el escalón de abajo.
#
#  CUÁNDO **NO** USARLO: si el problema no es el boot (p.ej. bootloader/ABL roto)
#  esto no lo arregla. Y si te has quedado sin backup bueno del boot, tampoco:
#  necesitas una imagen de partida.
#
#  LO QUE NO HACE: no borra, no formatea, no toca la GPT. Solo escribe boot.
# ============================================================================
set -u -o pipefail

# The public source has no personal paths or bundled boot image.
if [ -z "${MSMKALI_KIT_DIR:-}" ]; then
  printf '%s\n' 'Set MSMKALI_KIT_DIR to your own local portable kit before rescue.' >&2
  exit 2
fi
EDLDIR="${MSMKALI_EDL_DIR:-$MSMKALI_KIT_DIR/herramientas/edl-tool}"
LOADER="${MSMKALI_LOADER:-$MSMKALI_KIT_DIR/firmware/out/prog_firehose_ddr.elf}"
IMG_DEF="${MSMKALI_BOOT_IMAGE:-}"

rojo(){ printf '\033[1;31m%s\033[0m\n' "$*"; }
verde(){ printf '\033[1;32m%s\033[0m\n' "$*"; }
azul(){ printf '\033[1;34m%s\033[0m\n' "$*"; }

edl(){ sudo python3 "$EDLDIR/edl.py" "$@" --loader="$LOADER" --memory=ufs; }

IMG="${1:-$IMG_DEF}"
SLOTS="${2:-ambos}"     # a | b | ambos
[ -n "$IMG" ] || { printf '%s\n' 'Supply your own verified boot image as the first argument or MSMKALI_BOOT_IMAGE.' >&2; exit 2; }
case "$SLOTS" in a|b|ambos) ;; *) printf '%s\n' 'slot must be a, b or ambos' >&2; exit 2 ;; esac
[ -f "$EDLDIR/edl.py" ] || { printf '%s\n' 'Configured edl.py does not exist.' >&2; exit 2; }

echo
azul "════════ RESCATE POR EDL · OnePlus 7 Pro ════════"
echo "  imagen : $IMG"
echo "  slots  : $SLOTS"
echo

# ---- comprobaciones antes de tocar nada -----------------------------------
[ -f "$IMG" ]    || { rojo "✗ No existe la imagen: $IMG"; exit 1; }
[ -f "$LOADER" ] || { rojo "✗ No existe el firehose: $LOADER"; exit 1; }

MAGIC=$(head -c 8 "$IMG" | xxd -p)
[ "$MAGIC" = "414e44524f494421" ] || {
  rojo "✗ La imagen NO es un boot de Android (magic '$MAGIC', esperaba ANDROID!)."
  rojo "  Abortando: escribir esto dejaría el móvil peor."; exit 1; }

TAM=$(stat -c%s "$IMG")
[ "$TAM" -eq 100663296 ] || {
  rojo "✗ Tamaño raro: $TAM bytes (la partición boot del OP7 es 100663296)."
  rojo "  Abortando por precaución."; exit 1; }

verde "✔ Imagen válida: magic ANDROID!, $TAM bytes"
echo "  sha256: $(sha256sum "$IMG" | cut -d' ' -f1)"
echo

# ModemManager puede secuestrar el puerto 9008. En este Kali está desactivado,
# pero si algún día se activa, esto lo avisa (no lo toco por mi cuenta).
if systemctl is-active --quiet ModemManager 2>/dev/null; then
  rojo "⚠ ModemManager está ACTIVO y puede robarte el puerto EDL."
  echo "  Si falla la conexión, párala:  sudo systemctl stop ModemManager"
fi

cat <<'INSTRUCCIONES'
─────────────────────────────────────────────────────────────────────────────
 CÓMO PONER EL MÓVIL EN EDL (9008):
   1. Apágalo del todo: Power + Vol Arriba + Vol Abajo, 20-30 s, hasta que
      la pantalla quede negra y NO vuelva.
   2. Con el cable DESENCHUFADO, mantén Vol Arriba + Vol Abajo (sin Power).
   3. Sin soltarlos, enchufa el USB.
   4. La pantalla se queda NEGRA. Eso es lo correcto en EDL, no está muerto.

 Comprobar que enganchó:  lsusb | grep 05c6:9008
─────────────────────────────────────────────────────────────────────────────
INSTRUCCIONES
echo
echo "Este script se queda ESPERANDO al móvil, así que puedes lanzarlo ANTES"
echo "de enchufar el cable: engancha en el primer segundo y no se escapa."
echo
read -r -p "¿Seguimos? Escribe ACEPTO para continuar: " OK
[ "$OK" = "ACEPTO" ] || { echo "Cancelado."; exit 0; }

# ---- 1. leer la tabla de particiones (solo lectura, confirma que engancha) --
echo; azul "▶ 1/4 · Leyendo la tabla de particiones (solo lectura)"
edl printgpt > /tmp/rescate_gpt.log 2>&1
if grep -q "boot_a" /tmp/rescate_gpt.log; then
  verde "✔ Enganchado. Particionado leído (log: /tmp/rescate_gpt.log)"
  grep -E "^(boot_a|boot_b|win|userdata|esp):" /tmp/rescate_gpt.log | sed 's/^/    /'
else
  rojo "✗ No enganchó. ¿Está en EDL? Comprueba:  lsusb | grep 05c6:9008"; exit 1
fi

# ---- 2/3. escribir ---------------------------------------------------------
escribir_y_verificar(){
  local SLOT="$1"
  echo; azul "▶ Escribiendo boot_$SLOT"
  edl w "boot_$SLOT" "$IMG" 2>&1 | grep -vE "Progress:|DEMACIA|SETPROJ" | tail -3
  echo "   verificando por lectura de vuelta..."
  local TMPV="/tmp/verify_boot_$SLOT.img"
  edl r "boot_$SLOT" "$TMPV" 2>&1 | grep -vE "Progress:|DEMACIA|SETPROJ" | tail -1
  sudo chown "$USER:$USER" "$TMPV" 2>/dev/null
  if [ "$(sha256sum "$IMG" | cut -d' ' -f1)" = "$(sha256sum "$TMPV" | cut -d' ' -f1)" ]; then
    verde "   ✔ boot_$SLOT verificado: sha256 idéntico"
  else
    rojo  "   ✗ boot_$SLOT NO coincide. NO reinicies. Repite la escritura."; return 1
  fi
}

case "$SLOTS" in
  a)     escribir_y_verificar a ;;
  b)     escribir_y_verificar b ;;
  ambos) escribir_y_verificar a && escribir_y_verificar b ;;
  *)     rojo "slots debe ser: a | b | ambos"; exit 1 ;;
esac || exit 1

# ---- 4. reiniciar ----------------------------------------------------------
echo; azul "▶ 4/4 · Reiniciando el móvil"
edl reset 2>&1 | tail -2
echo
verde "════════ HECHO ════════"
cat <<'FINAL'
  El móvil debería arrancar en 1-2 minutos.
  Recuerda: la PALANCA decide el sistema — ARRIBA = Windows, MEDIO/ABAJO = Android.

  Comprobar:   adb devices        (Android)
               ping <ip>          (Windows, por WiFi/Tailscale)

  NOTA: el 'reset' puede escupir un TypeError de la herramienta. Es un bug
  conocido de edlclient — el móvil se reinicia igual. Míralo por la pantalla.

  Si NO arranca: vuelve a meterlo en EDL y prueba con otra imagen de
  backups-telefono/ (boot_ROOTED_*, boot_CON_SELECTOR_*, boot_original_predbkp_*).
FINAL
