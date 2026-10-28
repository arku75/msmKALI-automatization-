#!/usr/bin/env bash
# ============================================================================
#  msmKALI — el MSM de OnePlus, hecho en Kali Linux, sin Windows
#  Para OnePlus 7 Pro (GM1913 / guacamole).  Menu del 1 al 18.
#  (17 y 18 anadidas el 15-ago-2026: rescate por EDL y escritorio de Kali.)
#
#  Basado en la experiencia original resolviendo el "SMT Download
#  Failed" del 13/14-ago-2026 (ver CEREBRO/estado/SMT_RESUELTO_RECETA.md).
#
#  FILOSOFIA:
#   - Nada irreversible sin backup verificado ANTES y sin escribir "SI" a mano.
#   - Todo lo que hace queda en un registro con fecha.
#   - Si algo no esta claro, PARA y pregunta. Nunca adivina.
# ============================================================================
set -o pipefail

# Public source release: use an explicitly configured, separately held kit.
AQUI="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd)"
if [ -z "${MSMKALI_KIT_DIR:-}" ]; then
  printf '%s\n' 'Set MSMKALI_KIT_DIR to your own local portable kit. See docs/PUBLIC_SOURCE_GUIDE.md.' >&2
  exit 2
fi
BASE="$(cd "$MSMKALI_KIT_DIR" 2>/dev/null && pwd)" || exit 2
if [ ! -d "$BASE/firmware/out" ] || [ ! -d "$BASE/herramientas" ]; then
  printf '%s\n' 'The configured kit needs firmware/out and herramientas directories. No device action started.' >&2
  exit 2
fi
MODO="portable"
EDL="${MSMKALI_EDL:-$BASE/herramientas/edl-tool/edl.py}"
LOADER="${MSMKALI_LOADER:-$BASE/firmware/out/prog_firehose_ddr.elf}"
OUTDIR="$BASE/firmware/out"
BACKUPS="${MSMKALI_BACKUP_DIR:-$BASE/backups}"
LOGDIR="${MSMKALI_LOG_DIR:-$BASE/logs}"
REGISTRO="$LOGDIR/msmkali.log"
CRITICAS="persist modemst1 modemst2 fsg fsc"
DESCARGAS="$BASE"
TWRP="$BASE/recovery/moddedtwrp.img"
UEFI="$BASE/uefi/guacamole-uefi.img"
DBKP_DIR="$BASE/dualboot"
MAGISK="$BASE/root"
NETHUNTER="$BASE/nethunter"
WINISO="$BASE/windows"
GUIA="$BASE/guia"
mkdir -p -- "$BACKUPS" "$LOGDIR" || exit 1

R=$'\e[31m'; V=$'\e[32m'; A=$'\e[33m'; Z=$'\e[36m'; B=$'\e[1m'; N=$'\e[0m'

mkdir -p "$LOGDIR"
reg() { echo "[$(date '+%F %T')] $*" >> "$REGISTRO"; }
titulo() { clear; echo "${Z}${B}"; cat <<'EOF'
  ┌────────────────────────────────────────────────────────┐
  │   msmKALI  ·  el MSM de OnePlus, desde Kali Linux      │
  │   OnePlus 7 Pro (GM1913 / guacamole)                   │
  └────────────────────────────────────────────────────────┘
EOF
echo "${N}"; }

pausa() { echo; read -rp "  Pulsa ENTER para volver al menu... " _ || true; }
ok()   { echo "  ${V}✔${N} $*"; }
mal()  { echo "  ${R}X${N} $*"; }
avisa(){ echo "  ${A}!${N} $*"; }

# --- confirmacion fuerte para lo irreversible -------------------------------
confirmar() {
  local que="$1"
  echo
  echo "  ${R}${B}╔══════════════════ ATENCION ══════════════════╗${N}"
  echo "  ${R}${B}║ Vas a: $que${N}"
  echo "  ${R}${B}║ Esto NO se puede deshacer.                    ║${N}"
  echo "  ${R}${B}╚═══════════════════════════════════════════════╝${N}"
  echo
  read -rp "  Escribe exactamente  ACEPTO  para continuar: " r
  [ "$r" = "ACEPTO" ]
}

# --- deteccion --------------------------------------------------------------
# Si hay varios moviles enchufados, elige el OnePlus por su modelo.
ADB_SERIE=""
elegir_movil() {
  ADB_SERIE=""
  local series
  series=$(timeout 10 adb devices 2>/dev/null | awk '$2=="device"{print $1}')
  local n; n=$(echo "$series" | grep -c .)
  [ "$n" -eq 0 ] && return 1
  local s modelo
  for s in $series; do
    modelo=$(timeout 10 adb -s "$s" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
    case "$modelo" in
      GM19*|OnePlus*|*7*Pro*) ADB_SERIE="$s"; return 0 ;;
    esac
  done
  # No seleccionar otro dispositivo si no se reconoce un OnePlus.
  return 1
}
# adb "seguro": siempre contra el movil elegido
MOVIL() { if [ -n "$ADB_SERIE" ]; then timeout 12 adb -s "$ADB_SERIE" "$@"; else timeout 12 adb "$@"; fi; }
hay_adb()      { elegir_movil; [ -n "$ADB_SERIE" ]; }
hay_fastboot() { timeout 8 sudo -n fastboot devices 2>/dev/null | grep -q .; }
hay_edl()      { timeout 5 lsusb 2>/dev/null | grep -qi "05c6:9008"; }

estado_corto() {
  local e=""
  hay_adb      && e="${e}${V}ADB${N} "
  hay_fastboot && e="${e}${V}FASTBOOT${N} "
  hay_edl      && e="${e}${V}EDL-9008${N} "
  [ -z "$e" ] && e="${R}sin movil conectado${N}"
  echo -e "$e"
}

# ============================ 1. ESTADO =====================================
opcion_estado() {
  elegir_movil >/dev/null 2>&1
  titulo; echo "  ${B}1) Estado del movil${N}"; echo
  echo "  Conexion: $(estado_corto)"
  [ -n "$ADB_SERIE" ] && echo "  Hablando con: $ADB_SERIE"
  echo
  if hay_adb; then
    echo "  ${Z}--- por ADB ---${N}"
    printf "  %-22s %s\n" "modelo:"      "$(MOVIL shell getprop ro.product.model 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "nombre clave:" "$(MOVIL shell getprop ro.product.device 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "Android:"     "$(MOVIL shell getprop ro.build.version.release 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "version OOS:" "$(MOVIL shell getprop ro.build.display.id 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "slot activo:" "$(MOVIL shell getprop ro.boot.slot_suffix 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "bootloader:"  "$(MOVIL shell getprop ro.boot.flash.locked 2>/dev/null | tr -d '\r') (1=bloqueado 0=desbloqueado)"
    printf "  %-22s %s\n" "permite OEM:" "$(MOVIL shell getprop sys.oem_unlock_allowed 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "verified boot:" "$(MOVIL shell getprop ro.boot.verifiedbootstate 2>/dev/null | tr -d '\r')"
    printf "  %-22s %s\n" "root (Magisk):" "$(MOVIL shell 'which su || echo NO' 2>/dev/null | tr -d '\r')"
    echo
    echo "  ${Z}--- IMEI (si sale vacio, hay que restaurar: opcion 5) ---${N}"
    echo "  (Android 11 no deja leerlo por USB: marca *#06# en el movil)"
  elif hay_fastboot; then
    echo "  ${Z}--- por FASTBOOT ---${N}"
    sudo fastboot getvar current-slot 2>&1 | head -2
    sudo fastboot getvar unlocked 2>&1 | head -2
  elif hay_edl; then
    ok "El movil esta en EDL (9008). Usa las opciones 2, 5 o 6."
  else
    mal "No veo el movil."
    echo "     - Encendido y con depuracion USB  -> deberia salir ADB"
    echo "     - Apagado + Vol+ y Vol- + cable   -> deberia salir EDL"
  fi
  pausa
}

# ============================ 2. BACKUP =====================================
opcion_backup() {
  titulo; echo "  ${B}2) Copia de seguridad de lo insustituible (IMEI, calibracion)${N}"; echo
  echo "  Guarda: $CRITICAS"
  echo "  Son las particiones que NO se pueden recuperar de ningun sitio."
  echo
  if ! hay_edl; then
    mal "El movil tiene que estar en EDL (apagado + Vol+ y Vol- + cable)."
    pausa; return
  fi
  local dest="$BACKUPS/checkpoint_$(date +%Y%m%d_%H%M%S)"
  mkdir -p "$dest"
  echo "  Guardando en: $dest"; echo
  local lista="" ficheros=""
  for p in $CRITICAS; do lista="$lista,$p"; ficheros="$ficheros,$dest/$p.img"; done
  lista="${lista#,}"; ficheros="${ficheros#,}"
  reg "BACKUP -> $dest"
  ( cd "$OUTDIR" && sudo timeout 600 python3 "$EDL" r "$lista" "$ficheros" --loader="$LOADER" --memory=ufs ) 2>&1 | tail -20
  echo
  ( cd "$dest" && sha256sum ./*.img > MANIFIESTO.sha256 2>/dev/null )
  echo "  ${Z}--- comprobacion ---${N}"
  local n=0
  for p in $CRITICAS; do
    if [ -s "$dest/$p.img" ]; then ok "$p.img  ($(du -h "$dest/$p.img" | cut -f1))"; n=$((n+1))
    else mal "$p.img  VACIO O NO CREADO"; fi
  done
  echo
  [ "$n" -eq 5 ] && ok "Copia completa (5/5) con su MANIFIESTO.sha256" || avisa "Solo $n de 5. Repite antes de tocar nada."
  pausa
}

# ============================ 3. VERIFICAR ==================================
opcion_verificar() {
  titulo; echo "  ${B}3) Comprobar que las copias siguen intactas${N}"; echo
  local hay=0
  for d in "$BACKUPS"/checkpoint_*; do
    [ -d "$d" ] || continue
    hay=1
    echo "  ${Z}$(basename "$d")${N}"
    if [ -f "$d/MANIFIESTO.sha256" ]; then
      local res
      res=$( cd "$d" && sha256sum -c MANIFIESTO.sha256 2>&1 )
      local bien mal_n
      bien=$(echo "$res" | grep -c ": La suma coincide\|: OK")
      mal_n=$(echo "$res" | grep -c "FALLO\|FAILED")
      if [ "$mal_n" -eq 0 ] && [ "$bien" -gt 0 ]; then ok "$bien ficheros correctos"
      else mal "$mal_n ficheros CORRUPTOS"; fi
    else
      avisa "sin MANIFIESTO.sha256 (no se puede comprobar)"
    fi
  done
  [ "$hay" -eq 0 ] && avisa "No hay ninguna copia todavia. Usa la opcion 2."
  pausa
}

# ============================ 4. ENTRAR EN EDL ==============================
opcion_edl() {
  titulo; echo "  ${B}4) Poner el movil en modo EDL (9008)${N}"; echo
  echo "  Dos formas:"
  echo "   a) Por software (necesita ADB):   adb reboot edl"
  echo "   b) A mano: apagar del todo, mantener Vol+ y Vol- y enchufar el cable"
  echo
  echo "  ${A}Recuerda: el movil solo aguanta ~15 segundos en EDL si nadie le habla.${N}"
  echo
  if hay_adb; then
    read -rp "  ¿Lo mando yo por ADB? (s/n): " r
    if [ "$r" = "s" ]; then reg "adb reboot edl"; MOVIL reboot edl; sleep 3; fi
  fi
  echo "  Esperando el 9008 (30 s)..."
  for i in $(seq 1 30); do
    if hay_edl; then ok "EDL detectado: $(lsusb | grep -i 05c6:9008)"; pausa; return; fi
    sleep 1
  done
  mal "No aparecio. Comprueba el cable (mejor USB 2.0) y que qcserial este en lista negra (opcion 9)."
  pausa
}

# ============================ 5. RESTAURAR IMEI =============================
opcion_restaurar() {
  titulo; echo "  ${B}5) Devolver el IMEI y la calibracion al movil${N}"; echo
  echo "  Usalo despues de un SMT Download o de un borrado de fabrica,"
  echo "  cuando el movil se queda sin cobertura o sin IMEI."
  echo
  local dirs=() i=1
  for d in "$BACKUPS"/checkpoint_*; do [ -d "$d" ] && { dirs+=("$d"); echo "   $i) $(basename "$d")"; i=$((i+1)); }; done
  [ ${#dirs[@]} -eq 0 ] && { mal "No hay copias. Sin copia NO se puede restaurar."; pausa; return; }
  echo
  read -rp "  ¿Cual uso? (numero): " sel
  local d="${dirs[$((sel-1))]}"
  [ -d "$d" ] || { mal "Eleccion no valida."; pausa; return; }
  echo; echo "  Usando: $d"
  ( cd "$d" && sha256sum -c MANIFIESTO.sha256 2>&1 | tail -6 )
  hay_edl || { echo; mal "El movil tiene que estar en EDL."; pausa; return; }
  confirmar "escribir persist/modemst/fsg/fsc en el movil" || { avisa "Cancelado."; pausa; return; }
  local lista="" ficheros=""
  for p in $CRITICAS; do lista="$lista,$p"; ficheros="$ficheros,$d/$p.img"; done
  lista="${lista#,}"; ficheros="${ficheros#,}"
  reg "RESTAURAR desde $d"
  ( cd "$OUTDIR" && sudo timeout 600 python3 "$EDL" w "$lista" "$ficheros" --loader="$LOADER" --memory=ufs ) 2>&1 | tail -25
  echo
  ok "Terminado. Reinicia el movil y mira si vuelve la cobertura."
  pausa
}

# ============================ 6. FLASHEAR ===================================
opcion_flashear() {
  titulo; echo "  ${B}6) Instalar el firmware completo (lo que hace el MSM)${N}"; echo
  echo "  Equivale al 'Download' del MsmDownloadTool, pero desde Kali."
  echo "  ${A}BORRA EL MOVIL ENTERO.${N}"
  echo
  echo "  Antes de dejarte seguir compruebo tres cosas:"
  local listo=1
  [ -f "$LOADER" ] && ok "cargador firehose presente" || { mal "falta el firehose"; listo=0; }
  ls "$OUTDIR"/rawprogram*.xml >/dev/null 2>&1 && ok "listas de particiones (rawprogram) presentes" || { mal "faltan los rawprogram*.xml"; listo=0; }
  local hay_bk=0
  for d in "$BACKUPS"/checkpoint_*; do [ -f "$d/persist.img" ] && hay_bk=1; done
  [ "$hay_bk" -eq 1 ] && ok "hay copia del IMEI/persist" || { mal "NO hay copia del IMEI. Haz la opcion 2 primero."; listo=0; }
  echo
  [ "$listo" -eq 0 ] && { avisa "Falta algo. No sigo."; pausa; return; }
  hay_edl || { mal "El movil tiene que estar en EDL."; pausa; return; }
  confirmar "borrar el movil entero e instalar el firmware" || { avisa "Cancelado."; pausa; return; }
  echo
  echo "  ${A}NO desenchufes el cable ni toques el movil hasta que termine.${N}"
  echo "  ${A}Una interrupcion es lo que provoca el 'SMT Download Failed'.${N}"; echo
  reg "FLASHEO COMPLETO iniciado"
  local log="$LOGDIR/flasheo_$(date +%Y%m%d_%H%M%S).log"
  ( cd "$OUTDIR" && for x in rawprogram0.xml rawprogram1.xml rawprogram2.xml rawprogram3.xml rawprogram4.xml rawprogram5.xml; do
      [ -f "$x" ] || continue
      echo ">>> $x"
      sudo python3 "$EDL" qfil "$x" "${x/rawprogram/patch}" . --loader="$LOADER" --memory=ufs
    done ) 2>&1 | tee "$log" | grep -Ei "wrote|error|done|complete" | tail -30
  echo; ok "Registro completo en: $log"
  pausa
}

# ============================ 7. DIAGNOSTICO SMT ============================
opcion_smt() {
  titulo; echo "  ${B}7) Diagnostico del estado 'SMT Download Failed'${N}"; echo
  cat <<EOF
  ${Z}QUE ES:${N} una marca que el movil se pone cuando un flasheo se corta a
  medias. Vive en la particion 'param'. Mientras esta puesta, el movil
  arranca siempre en modo fabrica y no entra al sistema.

  ${Z}COMO SE QUITA (probado el 14-ago-2026):${N}
   Con el MsmDownloadTool en Windows, en modo "SMT Download":
     1. En  C:\\temp\\MsmDownloadTool\\MES_SETTING_SAVE.ini        -> IsAutoLine=0
        (si no, el programa busca el servidor de fabrica, no encuentra
         libMESAPI.dll y se cierra solo en 93 milisegundos)
     2. En  C:\\temp\\MsmDownloadTool\\QCOM_DownloadTool_Com_Config.ini
        -> TODOS los puertos con enable=1
        (si estan a 0, el programa ve llegar el movil, dice "Port is diable"
         y no le habla; el movil se cansa y se va a los 15 segundos)
     3. Login "Others" > Next > Verify > (sale en ROJO) > marcar SMT Download
     4. Start > contraseña ${B}te123${N} > memoria ${B}256G${N} > OK
     5. Cuando ponga "Waiting for device", enchufar el movil en EDL
     6. Esperar SIN TOCAR NADA (unos 10 minutos)
   Al final debe salir: "UPD_PARAM_AFTER_DOWNLOAD Checking - Pass"

  ${A}Despues del SMT el movil pierde el IMEI: usa la opcion 5 para devolverselo.${N}
EOF
  echo
  if hay_adb; then
    echo "  ${Z}Estado ahora:${N}"
    local est
    est=$(MOVIL shell getprop ro.boot.verifiedbootstate 2>/dev/null | tr -d '\r')
    ok "el movil arranca en Android (verifiedbootstate=$est) -> no esta en SMT"
  fi
  pausa
}

# ============================ 8. DESBLOQUEAR ================================
opcion_unlock() {
  titulo; echo "  ${B}8) Desbloquear el bootloader (paso previo al root)${N}"; echo
  echo "  Hace falta para: root con Magisk, TWRP, Kali NetHunter, Windows."
  echo "  ${A}BORRA TODOS LOS DATOS del movil.${N}"
  echo
  echo "  Antes, en el movil:  Ajustes > Opciones de desarrollador >"
  echo "     - Desbloqueo de OEM      : activado"
  echo "     - Depuracion por USB     : activada"
  echo
  if hay_adb; then
    local permite
    permite=$(MOVIL shell getprop sys.oem_unlock_allowed 2>/dev/null | tr -d '\r')
    [ "$permite" = "1" ] && ok "El movil permite el desbloqueo (sys.oem_unlock_allowed=1)" \
                         || avisa "sys.oem_unlock_allowed=$permite  (activa 'Desbloqueo de OEM' primero)"
  fi
  echo
  echo "  ${A}Ojo: en OxygenOS 12 esto falla ('cannot be unlocked for technical reason').${N}"
  echo "  ${A}En OxygenOS 11 o menor, funciona.${N}"
  echo
  confirmar "borrar el movil y desbloquear el bootloader" || { avisa "Cancelado."; pausa; return; }
  reg "UNLOCK"
  MOVIL reboot bootloader; sleep 6
  echo "  Confirma en la PANTALLA DEL MOVIL con Volumen + Encendido:"
  sudo fastboot flashing unlock || sudo fastboot oem unlock
  pausa
}

# ============================ 9. PREPARAR EL PC =============================
opcion_pc() {
  titulo; echo "  ${B}9) Preparar este Kali para hablar con el movil${N}"; echo
  echo "  ${Z}--- herramientas ---${N}"
  for h in adb fastboot python3; do
    command -v $h >/dev/null && ok "$h  ($(command -v $h))" || mal "$h NO instalado  -> sudo apt install android-tools-adb android-tools-fastboot"
  done
  [ -f "$EDL" ] && ok "edl.py presente" || mal "falta edl.py"
  [ -f "$LOADER" ] && ok "cargador firehose presente" || mal "falta el firehose"
  echo
  echo "  ${Z}--- el arreglo que hace falta para EDL ---${N}"
  if [ -f /etc/modprobe.d/edl-blacklist.conf ]; then
    ok "qcserial esta en lista negra (necesario: si no, secuestra el puerto)"
  else
    avisa "qcserial NO esta en lista negra. El EDL se colgara en 'Waiting for the device'."
    read -rp "  ¿Lo arreglo ahora? (s/n): " r
    if [ "$r" = "s" ]; then
      printf 'blacklist qcserial\nblacklist usb_wwan\n' | sudo tee /etc/modprobe.d/edl-blacklist.conf >/dev/null
      sudo modprobe -r qcserial usb_wwan 2>/dev/null
      ok "Hecho (para deshacerlo: borra /etc/modprobe.d/edl-blacklist.conf)"
    fi
  fi
  echo
  echo "  ${Z}--- consejos que costaron caro aprender ---${N}"
  echo "   · Usa siempre  --memory=ufs   (este movil es UFS; sin eso se cuelga)"
  echo "   · Usa siempre  sudo"
  echo "   · Varias particiones: separadas por COMAS, no por espacios"
  echo "   · Cable original y puerto USB 2.0 trasero: los USB 3 dan guerra"
  echo "   · NUNCA mates el proceso a media escritura: eso deja el movil en SMT"
  pausa
}

# ============================ 10. AYUDA =====================================
opcion_ayuda() {
  titulo; echo "  ${B}10) Que es esto y en que orden se usa${N}"; echo
  cat <<EOF
  msmKALI hace desde Linux lo que el MsmDownloadTool hace en Windows.

  ${Z}ORDEN RECOMENDADO${N}
    1. Opcion 9  -> preparar el PC (una sola vez)
    2. Opcion 1  -> ver como esta el movil
    3. Opcion 2  -> COPIA DE SEGURIDAD del IMEI  (nunca te la saltes)
    4. Opcion 3  -> comprobar que la copia esta bien
    5. ...ya puedes tocar: 6 (flashear), 8 (desbloquear), etc.
    6. Opcion 5  -> si pierdes el IMEI, devolverselo

  ${Z}LAS TRES REGLAS${N}
    1. Copia verificada ANTES de cualquier cosa que borre.
    2. Un flasheo NUNCA se interrumpe (asi nace el "SMT Download Failed").
    3. Si algo no encaja, para y pregunta. Nada de probar a ver que pasa.

  ${Z}SI ALGO SALE MAL${N}
    · El movil casi nunca esta "muerto": mientras entre en EDL (9008), se
      puede recuperar entero.
    · Registro de todo lo hecho: $REGISTRO

  Escrito con lo aprendido en la sesion del 13/14-ago-2026, cuando se
  resolvio el "SMT Download Failed" de este mismo OnePlus 7 Pro.
EOF
  pausa
}


# ============================ 11. PARTICIONAR ===============================
opcion_particionar() {
  titulo; echo "  ${B}11) Repartir el disco: Android + Windows${N}"; echo
  cat <<EOF
  Esto crea tres trozos en el disco del movil:
    · userdata -> Android (y Kali NetHunter dentro)
    · esp      -> el arranque de Windows (300 MB)
    · win      -> Windows

  ${A}BORRA TODOS LOS DATOS DEL MOVIL.${N}
  Necesita: bootloader desbloqueado + TWRP modificado arrancado.
EOF
  echo
  # comprobaciones
  local listo=1
  [ -f "$TWRP" ] && ok "TWRP modificado presente" || { mal "falta el TWRP modificado"; listo=0; }
  if hay_adb; then
    local unl; unl=$(MOVIL shell getprop ro.boot.flash.locked 2>/dev/null | tr -d '\r')
    [ "$unl" = "0" ] && ok "bootloader desbloqueado" || { mal "el bootloader sigue BLOQUEADO (usa la opcion 8)"; listo=0; }
  fi
  [ "$listo" -eq 0 ] && { pausa; return; }
  echo
  echo "  ${Z}¿Cuanto quieres para cada uno?${N}  (el movil tiene ~232 GB en total)"
  echo "    1) Mas Android    -> Android 150 GB / Windows ~74 GB   ${V}(recomendado)${N}"
  echo "    2) Equilibrado    -> Android 120 GB / Windows ~104 GB"
  echo "    3) Mas Windows    -> Android  90 GB / Windows ~134 GB"
  echo "    4) Lo elijo yo"
  echo
  read -rp "  Elige (1-4): " rep
  local and_gb
  case "$rep" in
    1) and_gb=150 ;;
    2) and_gb=120 ;;
    3) and_gb=90 ;;
    4) read -rp "  ¿Cuantos GB para Android? (minimo 40, deja al menos 45 para Windows): " and_gb ;;
    *) avisa "Cancelado."; pausa; return ;;
  esac
  if ! echo "$and_gb" | grep -qE '^[0-9]+$' || [ "$and_gb" -lt 40 ] || [ "$and_gb" -gt 185 ]; then
    mal "Valor no valido. Tiene que estar entre 40 y 185 GB."; pausa; return
  fi
  echo
  echo "  ${Z}--- PASO 1: leer la tabla REAL de tu movil ---${N}"
  echo "  (nunca uso numeros de una guia: los saco de tu aparato)"
  if ! hay_adb; then mal "Necesito el movil por ADB (arranca el TWRP modificado)."; pausa; return; fi
  local tabla
  tabla=$(MOVIL shell "parted /dev/block/sda unit MB print" 2>/dev/null | tr -d '\r')
  if [ -z "$tabla" ]; then
    mal "No pude leer la tabla. ¿Esta arrancado el TWRP modificado?"
    echo "     Para arrancarlo:  sudo fastboot boot \"$TWRP\""
    pausa; return
  fi
  echo "$tabla" | tail -25
  local num inicio
  num=$(echo "$tabla" | awk '/userdata/{print $1}' | head -1)
  inicio=$(echo "$tabla" | awk '/userdata/{print $2}' | head -1 | tr -d 'MB')
  echo
  if [ -z "$num" ] || [ -z "$inicio" ]; then
    mal "No encuentro 'userdata' en la tabla. PARO (no voy a adivinar)."; pausa; return
  fi
  ok "userdata es la particion numero $num y empieza en ${inicio}MB"
  local fin_data fin_esp
  fin_data=$(python3 -c "print(f'{$inicio/1000 + $and_gb:.1f}')")
  fin_esp=$(python3 -c "print(f'{$inicio/1000 + $and_gb + 0.3:.1f}')")
  echo
  echo "  ${Z}--- PASO 2: lo que voy a hacer ---${N}"
  echo "     rm $num"
  echo "     mkpart userdata ext4 ${inicio}MB ${fin_data}GB      -> Android: $and_gb GB"
  echo "     mkpart esp fat32 ${fin_data}GB ${fin_esp}GB          -> arranque Windows: 300 MB"
  echo "     mkpart win ntfs ${fin_esp}GB -0MB                    -> Windows: el resto"
  echo
  confirmar "borrar userdata y rehacer el reparto del disco" || { avisa "Cancelado."; pausa; return; }
  reg "PARTICIONAR: android=${and_gb}GB inicio=${inicio}MB"
  echo
  echo "  ${Z}--- PASO 3: arreglando la tabla de particiones (fixgpt) ---${N}"
  MOVIL shell "fixgpt" 2>&1 | tail -3
  echo "  ${Z}--- PASO 4: reparticionando ---${N}"
  MOVIL shell "parted -s /dev/block/sda rm $num" 2>&1 | tail -2
  MOVIL shell "parted -s /dev/block/sda mkpart userdata ext4 ${inicio}MB ${fin_data}GB" 2>&1 | tail -2
  MOVIL shell "parted -s /dev/block/sda mkpart esp fat32 ${fin_data}GB ${fin_esp}GB" 2>&1 | tail -2
  MOVIL shell "parted -s /dev/block/sda mkpart win ntfs ${fin_esp}GB -0MB" 2>&1 | tail -2
  echo "  ${Z}--- PASO 5: marcando el esp como arrancable ---${N}"
  local nesp
  nesp=$(MOVIL shell "parted /dev/block/sda unit MB print" 2>/dev/null | tr -d '\r' | awk '/esp/{print $1}' | head -1)
  [ -n "$nesp" ] && MOVIL shell "parted -s /dev/block/sda set $nesp esp on" 2>&1 | tail -2 || avisa "no encuentro el esp para marcarlo"
  echo
  echo "  ${Z}--- resultado ---${N}"
  MOVIL shell "parted /dev/block/sda unit GB print" 2>/dev/null | tr -d '\r' | tail -12
  echo
  ok "Reparto hecho."
  echo "  ${A}AHORA, en el TWRP del movil: Wipe > Format Data > escribe 'yes'.${N}"
  echo "  ${A}Si no lo haces, Android no arrancara.${N}"
  echo "  Despues, vuelve a arrancar el TWRP y usa la opcion 12 para dar formato a Windows."
  pausa
}

# ============================ 12. FORMATEAR WINDOWS =========================
opcion_formatear_win() {
  titulo; echo "  ${B}12) Dar formato a las particiones de Windows${N}"; echo
  echo "  Se hace DESPUES de repartir el disco y de formatear los datos en TWRP."
  echo "  Necesita el TWRP modificado arrancado."
  echo
  if ! hay_adb; then mal "Necesito el movil por ADB con el TWRP arrancado."; pausa; return; fi
  confirmar "dar formato a las particiones esp y win" || { avisa "Cancelado."; pausa; return; }
  reg "FORMAT esp+win"
  MOVIL shell "format" 2>&1 | tail -10
  echo; ok "Listo. Ya puedes instalar Windows (opcion 14)."
  pausa
}

# ============================ 13. ROOT ======================================
opcion_root() {
  titulo; echo "  ${B}13) Poner root (Magisk)${N}"; echo
  cat <<EOF
  El root hace falta para:
    · Kali NetHunter
    · La app WOA Helper (cambiar a Windows desde Android)

  Como funciona: se saca el arranque del movil (boot.img), Magisk lo modifica,
  y se vuelve a meter. No se toca nada mas.
EOF
  echo
  local apk
  apk=$(ls "$MAGISK"/*.apk 2>/dev/null | head -1)
  [ -n "$apk" ] && ok "Magisk descargado: $(basename "$apk")" || avisa "no veo el APK de Magisk en $MAGISK"
  echo
  if ! hay_adb; then mal "Necesito el movil conectado."; pausa; return; fi
  echo "  ${Z}--- PASO 1: sacar el arranque actual del movil ---${N}"
  local slot dest
  slot=$(MOVIL shell getprop ro.boot.slot_suffix 2>/dev/null | tr -d '\r')
  [ -z "$slot" ] && slot="_a"
  dest="$BACKUPS/boot_original${slot}_$(date +%Y%m%d_%H%M%S).img"
  echo "  slot activo: $slot"
  MOVIL shell "dd if=/dev/block/by-name/boot${slot} of=/tmp/boot.img" 2>&1 | tail -2
  MOVIL pull /tmp/boot.img "$dest" 2>&1 | tail -2
  if [ -s "$dest" ]; then
    ok "arranque guardado: $dest ($(du -h "$dest" | cut -f1))"
  else
    mal "No pude sacarlo. ¿Estas en TWRP o con root? (desde Android normal no se puede)"
    pausa; return
  fi
  echo
  echo "  ${Z}--- PASO 2: lo que tienes que hacer TU en el movil ---${N}"
  cat <<EOF
   1. Instala el APK de Magisk en el movil (te lo paso ahora al movil).
   2. Abre Magisk > "Install" > "Select and Patch a File".
   3. Elige el fichero boot.img que te dejo en la carpeta Download del movil.
   4. Magisk crea "magisk_patched-XXXX.img" en Download.
   5. Vuelve aqui y pulsa ENTER: yo me lo traigo y lo instalo.
EOF
  echo
  [ -n "$apk" ] && { MOVIL install "$apk" 2>&1 | tail -2; }
  MOVIL push "$dest" /sdcard/Download/boot.img 2>&1 | tail -1
  ok "boot.img dejado en la carpeta Download del movil"
  echo
  read -rp "  Cuando Magisk haya creado el parcheado, pulsa ENTER... " _
  local parch
  parch=$(MOVIL shell "ls /sdcard/Download/magisk_patched*.img 2>/dev/null | head -1" | tr -d '\r')
  if [ -z "$parch" ]; then mal "No encuentro el fichero parcheado en Download."; pausa; return; fi
  ok "encontrado: $parch"
  MOVIL pull "$parch" "$BACKUPS/magisk_patched.img" 2>&1 | tail -1
  confirmar "instalar el arranque con root en el movil" || { avisa "Cancelado."; pausa; return; }
  reg "ROOT: flash magisk_patched"
  MOVIL reboot bootloader; sleep 10
  sudo fastboot flash boot "$BACKUPS/magisk_patched.img" 2>&1 | tail -4
  sudo fastboot reboot 2>&1 | tail -2
  echo; ok "Hecho. Cuando arranque, abre Magisk y comprueba que dice 'Installed'."
  pausa
}

# ============================ 14. WINDOWS ===================================
opcion_windows() {
  titulo; echo "  ${B}14) Instalar Windows 11 ARM${N}"; echo
  echo "  ${Z}--- lo que tienes ---${N}"
  local iso; iso=$(ls "$WINISO"/*.esd "$WINISO"/*.wim "$WINISO"/*.iso 2>/dev/null | head -1)
  [ -n "$iso" ] && ok "imagen de Windows: $(basename "$iso") ($(du -h "$iso" | cut -f1))" || mal "no veo la imagen de Windows en $WINISO"
  [ -f "$UEFI" ] && ok "UEFI presente (verificado igual al oficial)" || mal "falta el UEFI"
  ls "$DESCARGAS"/drivers-aloha/*.zip >/dev/null 2>&1 && ok "controladores presentes" || avisa "no veo los controladores"
  echo
  cat <<EOF
  ${A}AVISO IMPORTANTE, para que no te lleves un chasco:${N}
   En Windows FUNCIONA: pantalla, tactil, wifi, GPU, sonido, USB, GPS, NFC, LTE.
   ${R}NO funciona: la CARGA de bateria (hay que volver a Android para cargar),
   la camara, la vibracion, la huella y casi todos los sensores.${N}

  ${A}Y lo mas serio: usa SIEMPRE el UEFI mas nuevo. Con uno viejo, el
  almacenamiento del movil (UFS) puede morir en cualquier momento.${N}

  ${Z}Este paso se hace desde un Windows${N} (hace falta DISM y bcdboot, que no
  existen en Linux). Guia completa, ya descargada, en:
     descargas/woa-op7-guia/guide/3-install.md
EOF
  echo
  cat <<'EOF'

  >>> LOS PASOS EXACTOS (probados el 14-ago-2026 en el movil de SER)

  1. En el movil, en TWRP:  Advanced > Enable Mass Storage Mode
     !! OJO: es "Mass Storage", NO "MTP". Con MTP el PC NO ve las particiones.
     Windows lo vera entonces como un disco: "Linux File-Stor Gadget".

  2. En el PC Windows, abrir CMD como administrador y mirar los volumenes:
       diskpart
       list volume
     Deben aparecer WINONEPLUS (NTFS, ~87 GB) y ESPONEPLUS (FAT32, ~300 MB).
     El formateo del TWRP ya les pone esos nombres solo.

  3. Darles letra (en el ejemplo real: WINONEPLUS ya tenia E, al ESP le puse Y):
       select volume <el de WINONEPLUS>
       assign letter=x
       select volume <el de ESPONEPLUS>
       assign letter=y
       exit
     !! NUNCA borres, crees ni modifiques particiones dentro de diskpart:
     eso puede dejar el movil inservible de verdad.

  4. Volcar Windows a la particion del movil:
       dism /apply-image /ImageFile:C:\ruta\install.esd /index:6 /ApplyDir:X:\
     Si da Error 87, mirar el indice correcto con:
       dism /get-imageinfo /ImageFile:C:\ruta\install.esd
     y usar el numero de "Windows 11 Pro".

  5. Controladores: descomprimir el paquete y ejecutar OfflineUpdater.cmd
     (si falla, OfflineUpdaterFix.cmd). Cuando pida una letra, dar la de WINONEPLUS.

  6. Crear el arranque de Windows:
       bcdboot X:\Windows /s Y: /f UEFI
     Si dice "Failure when attempting to copy boot files", volver a diskpart,
     asignar OTRA letra al ESP y repetir con esa letra.

  7. Soltar la letra del ESP:   mountvol y: /d

  8. ** Para que funcione el LTE (si no, te quedas sin datos moviles):
     en TWRP: Advanced > ADB Sideload > deslizar, y desde el PC:
       adb sideload modemprov.zip

  9. Arrancar Windows la primera vez:
       adb reboot bootloader
       fastboot boot guacamole-uefi.img
     !! Tarda unos 10 minutos en la primera puesta en marcha. No lo toques.
     Al terminar vuelve solo a Android.

 10. Ya solo queda el selector (opcion 16).

  >>> CONSEJO: si te salta el inicio de sesion de Microsoft y no quieres cuenta,
  pulsa "I don't have internet" y luego "Continue with limited setup".
EOF
  pausa
}

# ============================ 15. NETHUNTER =================================
opcion_nethunter() {
  titulo; echo "  ${B}15) Kali NetHunter${N}"; echo
  cat <<EOF
  NetHunter NO es otro sistema: es una capa DENTRO de Android
  (un kernel preparado + el entorno de Kali). Por eso convive con Windows
  sin problema: Windows va en su particion, NetHunter va dentro de Android.

  ${V}Tu OxygenOS 11 SIRVE${N}: hay que usar la version "oos-eleven"
  (no hace falta bajar a OxygenOS 10).
EOF
  echo
  echo "  ${Z}--- lo que tienes descargado ---${N}"
  [ -f "$NETHUNTER/Image.gz-dtb" ] && ok "kernel NetHunter presente" || avisa "no veo el kernel"
  ls "$NETHUNTER"/*rootfs*.xz >/dev/null 2>&1 && ok "entorno Kali (rootfs) presente: $(ls -la "$NETHUNTER"/*rootfs*.xz | awk '{print $5/1024/1024" MB"}' | head -1)" || avisa "no veo el rootfs"
  local mag; mag=$(ls "$MAGISK"/*.apk 2>/dev/null | head -1)
  [ -n "$mag" ] && ok "Magisk presente" || avisa "no veo Magisk"
  echo
  cat <<EOF
  ${Z}ORDEN${N}
   1. Tener root (opcion 13).
   2. Instalar la tienda NetHunter y la app NetHunter.
   3. Desde la app, instalar el entorno de Kali (chroot).
   4. Instalar el kernel de NetHunter (por TWRP, "adb sideload").
   5. Comprobar:  adb shell uname -r   -> debe salir un kernel "-Re4son-"

  ${A}Ojo con el orden:${N} si vas a repartir el disco para Windows, hazlo ANTES
  de instalar NetHunter. Repartir borra /data, y el entorno de Kali vive ahi:
  lo perderias y habria que instalarlo otra vez.
EOF
  pausa
}

# ============================ 16. SELECTOR (DBKP) ===========================
opcion_dbkp() {
  titulo; echo "  ${B}16) El selector: elegir Windows o Android al encender${N}"; echo
  cat <<EOF
  ${Z}No existe un menu tipo GRUB en este movil.${N} Hay dos formas, y las dos
  arrancan UN SOLO sistema cada vez (nunca los dos a la vez, y el que
  arranca dispone de toda la memoria del movil).

  ${V}FORMA 1 - la palanca lateral (alert slider)  [la que recomiendo]${N}
    Se parchea el arranque con DualBootKernelPatcher y luego:
      · palanca ARRIBA         + encender/reiniciar  ->  Windows
      · palanca EN MEDIO/ABAJO + encender/reiniciar  ->  Android (con NetHunter)
    Hay una version que NO necesita root (con el TWRP modificado).

  ${Z}FORMA 2 - una app${N}
    App "WOA Helper" en Android: boton "QUICKBOOT TO WINDOWS".
    En Windows: un acceso directo en el escritorio para volver a Android.
    Esta SI necesita root.
EOF
  echo
  echo "  ${Z}--- lo que tienes ---${N}"
  [ -f "$DBKP_DIR/DualBootKernelPatcher.zip" ] && ok "DualBootKernelPatcher presente" || avisa "falta el patcher"
  [ -f "$DBKP_DIR/guacamole.fd" ] && ok "fichero guacamole.fd presente" || avisa "falta guacamole.fd"
  [ -f "$DBKP_DIR/magiskboot.exe" ] && ok "magiskboot presente" || avisa "falta magiskboot"
  echo
  echo "  Guia completa (ya descargada):  descargas/woa-op7-guia/guide/dbkp.md"
  pausa
}

# ============================ 17. RESCATE POR EDL ===========================
# Anadido el 15-ago-2026, despues de rescatar DOS VECES el movil el mismo dia
# (CrashDump por DBKP-sobre-kernel-NetHunter, y EDL tras magisk --install-module
# con el movil arrancado). La receta esta probada entera.
opcion_rescate_edl() {
  titulo; echo "  ${B}17) Rescate por EDL: devolver un arranque que funcione${N}"; echo
  cat <<EOF
  ${Z}PARA CUANDO EL MOVIL NO ARRANCA${N} (CrashDump, pantalla negra, bucle) y
  NO entra ni en fastboot ni en recovery.

  Reescribe SOLO la particion de arranque (boot) con una imagen buena.
  ${V}NO borra nada mas${N}: se quedan Windows, tus datos, el IMEI y el particionado.

  Si fastboot SI entra, usa fastboot: es mas simple. Esto es el escalon de abajo.
EOF
  echo
  echo "  ${Z}--- lo que hay que saber del EDL en este movil (aprendido a base de fallos) ---${N}"
  cat <<EOF
   · Combo EDL: movil APAGADO del todo -> manten ${B}VolArriba + VolAbajo${N} -> enchufa el USB.
     La pantalla se queda NEGRA: eso es lo correcto en EDL, no esta muerto.
   · ${B}Lanza el rescate ANTES de enchufar el cable${N}: la herramienta se queda esperando
     ("Waiting for the device") y engancha en el primer segundo.
   · Siempre con ${B}--memory=ufs${N} y el loader ${B}Loaders/prog_firehose_ddr.elf${N}
     (md5 29e9b2a4e71e95d31619943390c1edb1).
   · Los mensajes ${A}ERROR: raw hex token${N} y ${A}ERROR: SN:${N} son ${V}NORMALES${N} en el
     firehose de OnePlus: la operacion acaba en ACK igualmente.
   · El ${B}reset${N} escupe un ${A}TypeError${N} de la propia herramienta (bug conocido de
     edlclient) pero ${V}el movil SI se reinicia${N}. Miralo por la pantalla.
   · Si tienes ${B}ModemManager${N} activo, parale: te roba el puerto 9008.
EOF
  echo
  # el script de rescate: primero al lado de este programa, si no en el sitio de siempre
  local RESC=""
  for c in "$AQUI/rescate_edl.sh" "$BASE/rescate_edl.sh"; do
    [ -f "$c" ] && { RESC="$c"; break; }
  done
  if [ -z "$RESC" ]; then
    mal "No encuentro rescate_edl.sh (deberia estar junto a este programa)."
    pausa; return
  fi
  ok "Script de rescate: $RESC"
  echo "  ${Z}Comprueba antes de escribir:${N} magic ANDROID!, tamano 100663296 bytes,"
  echo "  y ${B}verifica leyendo de vuelta${N} (compara sha256). Si no coincide, avisa y NO reinicia."
  echo
  echo "  ${Z}--- imagenes de arranque que tienes guardadas ---${N}"
  # mira en las dos carpetas posibles: la del paquete portable y la del proyecto
  local BKS
  BKS=$(ls -1 "$BACKUPS"/boot_*.img 2>/dev/null | sort -u)
  if [ -n "$BKS" ]; then
    echo "$BKS" | sed 's|^|    |' | head -12
  else
    avisa "no veo imagenes de boot guardadas (el script te dira si falta la que pidas)"
  fi
  echo
  echo "  Por defecto usa el boot bueno conocido: ${B}boot_preNH_20260815_024952_bootA.img${N}"
  echo "  (sha256 8634a846... = OxygenOS 11 stock + selector DBKP + root Magisk)"
  echo
  echo "   ${B}1${N}) Lanzar el rescate  (los dos slots: a y b)"
  echo "   ${B}2${N}) Lanzar el rescate  (SOLO boot_a  — deja boot_b como plan B)"
  echo "   ${B}3${N}) Volver"
  echo
  read -rp "  Elige (1-3): " r || return
  case "$r" in
    1) reg "17: rescate EDL ambos slots"; bash "$RESC" ;;
    2) reg "17: rescate EDL solo boot_a"; bash "$RESC" "" a ;;
    *) return ;;
  esac
  pausa
}

# ============================ 18. ESCRITORIO KALI ===========================
# Anadido el 15-ago-2026: el escritorio grafico de Kali funcionando en el movil.
opcion_escritorio_kali() {
  titulo; echo "  ${B}18) El escritorio de Kali en el movil${N}"; echo
  cat <<EOF
  ${V}${B}LO IMPORTANTE, PARA NO LIARSE:${N}
  "NetHunter FULL" = con el ${B}kernel${N} parcheado, y ese kernel ${B}SOLO${N} sirve para
  modo monitor / inyeccion / HID-BadUSB (y necesita un ${B}adaptador WiFi USB-OTG${N}:
  el WiFi interno del OnePlus NO hace modo monitor).

  ${V}Usar Kali${N} — escritorio grafico tactil y todas las herramientas —
  ${V}NO necesita kernel ni adaptador.${N} Ya funciona.

  ${A}Ademas, el kernel de NetHunter SUSTITUYE al kernel del arranque${N} -> en ese slot
  pierdes el selector de la palanca y con el, el arranque de Windows.
EOF
  echo
  echo "  ${Z}--- como se enciende (script que vive EN EL MOVIL) ---${N}"
  cat <<EOF
    /data/local/nhsystem/kali-escritorio            -> lo enciende
    /data/local/nhsystem/kali-escritorio parar      -> lo apaga
    /data/local/nhsystem/kali-escritorio estado     -> dice si esta arriba

  Te dice la IP y la contrasena al encenderlo. Ejemplo real:
    ${V}✔ Escritorio ENCENDIDO -> <IP_DEL_MOVIL>:5901${N}

  ${Z}Como verlo:${N}
    · Desde el propio movil, con la app ${B}KeX${N} (con el dedo).
    · Desde este PC:  ${B}vncviewer <IP-del-movil>:5901${N}
    Contrasena: ${B}kali2026${N}
EOF
  echo
  echo "  ${Z}--- detalles que costaron encontrarse ---${N}"
  cat <<EOF
   · La config de TigerVNC nuevo esta en ${B}/root/.config/tigervnc/${N}, ${A}ya NO en /root/.vnc${N}.
   · Para que XFCE arranque dentro del chroot hace falta
     ${B}XDG_RUNTIME_DIR=/tmp/runtime-root${N} + ${B}eval \$(dbus-launch --sh-syntax)${N},
     y a veces levantar ${B}xfdesktop${N} y ${B}xfce4-panel${N} a mano.
   · Si Kali no tiene internet: casi siempre es el WiFi de ${A}Android${N}, que se queda
     "encendido pero desconectado" al volver de Windows.
     Arreglo:  ${B}svc wifi disable ; sleep 3 ; svc wifi enable${N}
   · ${B}bootkali.sh${N} acepta ${B}-c "orden"${N} para lanzar comandos sueltos (copia del
     original en bootkali.sh.bak).
EOF
  echo
  if hay_adb; then
    echo "   ${B}1${N}) Encender el escritorio en el movil"
    echo "   ${B}2${N}) Ver si esta encendido"
    echo "   ${B}3${N}) Apagarlo"
    echo "   ${B}4${N}) Volver"
    echo
    read -rp "  Elige (1-4): " r || return
    case "$r" in
      1) reg "18: encender escritorio kali"; MOVIL shell su -c "sh /data/local/nhsystem/kali-escritorio" ;;
      2) MOVIL shell su -c "sh /data/local/nhsystem/kali-escritorio estado" ;;
      3) reg "18: parar escritorio kali"; MOVIL shell su -c "sh /data/local/nhsystem/kali-escritorio parar" ;;
      *) return ;;
    esac
  else
    avisa "El movil no esta conectado por USB: solo te enseno como se hace."
  fi
  pausa
}


opcion_medico() {
  titulo; echo "  ${B}19) Medico del NetHunter (nh-doctor)${N}"; echo
  cat <<EOF
  Repara SOLO los errores que ya nos costaron horas, y comprueba 6 cosas:
    [1] binder de Android   (si se rompe, NINGUNA app arranca ni hay capturas)
    [2] WiFi de Android     (el Kali del chroot depende de el para tener red)
    [3] apps NetHunter      (que esten las 5)
    [4] chroot: apt sano, DNS, /dev/shm, opencode+tmux, nmap, metasploit
    [5] ${V}provisioning del modem para Windows${N}  (los datos moviles de Windows)
    [6] ${V}permisos de arranque de NetHunter${N}    (Android 11 se los bloquea)

  ${Z}Vive EN EL MOVIL${N}, se usa desde la terminal de NetHunter (NeoTerm):
    ${B}nh-doctor${N}              -> diagnostica y repara lo seguro
    ${B}nh-doctor check${N}        -> solo mira, no toca nada
    ${B}nh-doctor install PKG${N}  -> instala paquetes sin romper el chroot
EOF
  echo
  if hay_adb; then
    echo "  ${Z}--- pasandole el medico al movil ahora ---${N}"; echo
    adb -s "$ADB_SERIE" shell su -c "sh /data/local/nhsystem/nh-doctor" 2>&1 | tr -d '\r' | sed 's/^/  /'
  else
    avisa "El movil no esta por USB. Instalalo/actualizalo asi cuando lo conectes:"
    echo "    adb push nh-doctor /data/local/tmp/ && adb shell su -c 'cp /data/local/tmp/nh-doctor /data/local/nhsystem/ && chmod 755 /data/local/nhsystem/nh-doctor'"
  fi
  pausa
}

opcion_datos_windows() {
  titulo; echo "  ${B}20) Datos moviles en Windows (LTE)${N}"; echo
  cat <<EOF
  ${V}${B}EL PROBLEMA Y SU CAUSA REAL (20-ago-2026):${N}
  En Windows la senal salia ${R}0%${N} y conectar daba ${R}error 0x139f${N}, aunque el perfil
  del operador (APN) estuviera bien puesto. ${B}No era el perfil${N}: el modem no registraba.

  El driver de Windows ${B}qcremotefs8150${N} guarda el "sistema de ficheros remoto" del
  modem en ${B}bootmodem_fs1/fs2${N}. Si eso NO coincide con ${B}modemst1/2${N} de Android,
  el modem no tiene provisioning valido y ${R}no registra en la red${N}.

  ${A}Y lo que nadie dice:${N} Android ${B}reescribe modemst cada pocos minutos${N} (medido:
  cambio en 3 min). Por eso copiarlo "una vez" (el modemprov.zip de siempre)
  ${R}se queda viejo enseguida${N} -> de ahi el automatismo.

  ${V}${B}LA SOLUCION (ya instalada en el movil):${N}
    ${B}/data/adb/service.d/modemprov-auto.sh${N}
    · resincroniza en CADA arranque de Android y cada 30 min
    · ${B}solo LEE${N} modemst (nunca escribe al modem: el IMEI ni se toca)
    · aborta si el NTFS de Windows esta sucio (hibernado)
    · ${B}escritura atomica${N} (tmp+mv): un apagado a media copia no rompe nada
    · verifica por md5 y descarta la copia si sale corrupta
    · log: /data/adb/modemprov-auto.log

  ${Z}Resultado verificado en Windows:${N}
    State: Connected · Provider: Mobitel · LTE · APN: internet
    ping por la celular -> 4/4, 0% perdida, 44 ms
EOF
  echo
  if hay_adb; then
    echo "  ${Z}--- estado del provisioning en tu movil ahora ---${N}"; echo
    adb -s "$ADB_SERIE" shell su -c "tail -8 /data/adb/modemprov-auto.log" 2>&1 | tr -d '\r' | sed 's/^/  /'
    echo
    if adb -s "$ADB_SERIE" shell su -c "test -x /data/adb/service.d/modemprov-auto.sh && echo si" 2>/dev/null | grep -q si; then
      ok "El automatismo esta instalado y activo."
    else
      avisa "NO esta instalado. Para instalarlo:"
      echo "    adb push modemprov-auto.sh /data/local/tmp/ && adb shell su -c 'cp /data/local/tmp/modemprov-auto.sh /data/adb/service.d/ && chmod 755 /data/adb/service.d/modemprov-auto.sh'"
    fi
  else
    avisa "El movil no esta por USB: solo te ensenio como es."
  fi
  echo
  echo "  ${A}Si Windows llegara a borrarte las particiones del modem${N} (el propio port avisa"
  echo "  de que puede pasar), restauralas con la opcion ${B}5${N} desde recovery."
  pausa
}

opcion_usb_windows() {
  titulo; echo "  ${B}21) USB en Windows: HOST o DEVICE${N}"; echo
  cat <<EOF
  ${V}${B}QUE ES:${N} el puerto del movil puede ser de dos maneras, y en este Windows
  ${B}no se decide solo${N} (falta el UCM, el que lee los pines del Type-C):

    ${B}HOST${N}    -> Windows reconoce lo que ENCHUFES (pendrive, teclado, raton).
    ${B}DEVICE${N}  -> el movil es el periferico: se conecta al PC y ${V}es seguro cargar${N}.

  ${R}${B}AVISO IMPORTANTE (puede danar el movil de forma irreversible):${N}
  En ${B}HOST${N} el movil ${B}genera 5V hacia fuera${N}. Si ademas hay otra fuente de 5V
  (${R}un hub USB alimentado, el cable al PC, o el cargador${N}), son dos fuentes
  enfrentadas. ${B}Antes de cargar o conectar al PC: pon DEVICE.${N}

  ${Z}--- como se cambia (todo esta ya en el movil, en C:\\op7) ---${N}
    Desde el escritorio de Windows, doble clic en:
      ${B}USB-HOST (pendrives).bat${N}       o    ${B}USB-DEVICE (PC y cargar).bat${N}
    O por linea de comandos:
      ${B}powershell -File C:\\op7\\usb-mode.ps1 host${N} | ${B}device${N} | ${B}estado${N}

  ${Z}--- como se descubrio (no estaba documentado en ningun sitio) ---${N}
    Windows lo guarda en el registro:
      ${B}HKLM\\SYSTEM\\CurrentControlSet\\Enum\\ACPI\\QCOM0597\\0\\Device Parameters${N}
      valor ${B}RoleSwitchMode${N} (DWORD):  ${B}1 = HOST${N} · ${B}2 = DEVICE${N} · 3 = auto (no funciona aqui)
    Microsoft NO documenta esos valores: se sacaron ${V}decompilando${N} la herramienta
    oficial del port (USB_Mode_Control, .NET) con ikdasm:
      HOST_ROLE_VALUE = 0x1 · FUNCTION_ROLE_VALUE = 0x2
    Se aplica sin reiniciar Windows:  ${B}pnputil /restart-device "ACPI\\QCOM0597\\0"${N}

  ${Z}--- verificado de verdad ---${N}
    En HOST cargaron ${B}xHCI Host Controller${N} + ${B}USB Root Hub${N}, y un pendrive
    Verbatim de 8 GB aparecio como ${B}D: FAT32${N}: escritura y lectura correctas.

  ${A}La carga en Windows NO funciona${N}, estes en el modo que estes: el propio port la
  desactivo ("disabled due to random BSoD"). Para cargar de verdad: ${B}Android${N}.
EOF
  pausa
}

# ============================ MENU ==========================================
while true; do
  elegir_movil >/dev/null 2>&1
  titulo
  [ "$MODO" = "portable" ] && echo "   ${V}[paquete portable — todo incluido]${N}"
  echo "   Movil: $(estado_corto)"
  echo
  echo "  ${Z}── RESCATE ──────────────────────────────────${N}"
  echo "   ${B}1${N}) Ver como esta el movil"
  echo "   ${B}2${N}) Copia de seguridad del IMEI                    ${V}(hazla siempre)${N}"
  echo "   ${B}3${N}) Comprobar que las copias estan intactas"
  echo "   ${B}4${N}) Poner el movil en modo EDL"
  echo "   ${B}5${N}) Devolver el IMEI al movil"
  echo "   ${B}6${N}) Instalar el firmware completo                  ${R}(borra todo)${N}"
  echo "   ${B}7${N}) Diagnostico del 'SMT Download Failed'"
  echo
  echo "  ${Z}── INSTALAR ANDROID + WINDOWS + KALI ────────${N}"
  echo "   ${B}8${N}) Desbloquear el bootloader                      ${R}(borra todo)${N}"
  echo "  ${B}11${N}) Repartir el disco (eliges los GB)             ${R}(borra todo)${N}"
  echo "  ${B}12${N}) Dar formato a las particiones de Windows"
  echo "  ${B}13${N}) Poner root (Magisk)"
  echo "  ${B}14${N}) Instalar Windows 11 ARM"
  echo "  ${B}15${N}) Kali NetHunter"
  echo "  ${B}16${N}) El selector: Windows o Android al encender"
  echo
  echo "  ${Z}── EL MOVIL YA FUNCIONA: USARLO Y SALVARLO ──${N}"
  echo "  ${B}17${N}) Rescate por EDL: devolver un arranque bueno   ${V}(no borra nada)${N}"
  echo "  ${B}18${N}) El escritorio de Kali en el movil"
  echo "  ${B}19${N}) Medico del NetHunter: arregla lo que falle    ${V}(diagnostica y repara)${N}"
  echo "  ${B}20${N}) Datos moviles (LTE) en Windows"
  echo "  ${B}21${N}) USB en Windows: HOST o DEVICE                 ${R}(leelo antes de cargar)${N}"
  echo
  echo "  ${Z}── AYUDA ────────────────────────────────────${N}"
  echo "   ${B}9${N}) Preparar este PC        ${B}10${N}) Ayuda y orden recomendado"
  echo
  echo "   ${B}0${N}) Salir"
  echo
  if ! read -rp "  Elige (0-21): " op; then echo; echo "  (fin de entrada) Hasta luego."; exit 0; fi
  case "$op" in
    1) opcion_estado ;;
    2) opcion_backup ;;
    3) opcion_verificar ;;
    4) opcion_edl ;;
    5) opcion_restaurar ;;
    6) opcion_flashear ;;
    7) opcion_smt ;;
    8) opcion_unlock ;;
    9) opcion_pc ;;
    10) opcion_ayuda ;;
    11) opcion_particionar ;;
    12) opcion_formatear_win ;;
    13) opcion_root ;;
    14) opcion_windows ;;
    15) opcion_nethunter ;;
    16) opcion_dbkp ;;
    17) opcion_rescate_edl ;;
    18) opcion_escritorio_kali ;;
    19) opcion_medico ;;
    20) opcion_datos_windows ;;
    21) opcion_usb_windows ;;
    0) echo; echo "  Hasta luego."; echo; exit 0 ;;
    *) ;;
  esac
done
