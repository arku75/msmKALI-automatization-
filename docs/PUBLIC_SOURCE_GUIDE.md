# Guía de la edición pública

## Qué contiene

Esta edición publica la automatización de msmKALI para OnePlus 7 Pro GM1913 / guacamole. El código procede de la carpeta preparada para GitHub del kit original. El README histórico y su atribución se conservan.

| Ruta | Función |
|---|---|
| `msmkali` | Lanzador que conserva los argumentos de la línea de comandos. |
| `scripts/msmkali.py` | Interfaz ES/EN, listado de scripts y comprobación de herramientas del PC. |
| `scripts/msmkali.sh` | Menú Bash original: estado, copias, verificación, recuperación, preparación de Android/Windows/NetHunter y utilidades del dispositivo. |
| `scripts/rescate_edl.sh` | Escritura de una imagen de arranque elegida por el usuario mediante su herramienta EDL local, con comprobaciones previas y comparación posterior. |
| `scripts/nh-doctor*` | Ayudantes para el entorno Android/NetHunter; requieren revisión e instalación deliberada dentro del dispositivo. |
| `scripts/modemprov-auto.sh` | Sincroniza datos de aprovisionamiento del módem desde Android hacia la instalación Windows del propio dispositivo. |
| `scripts/nv-diagnostico.sh` | Diagnóstico y copia local de particiones de identidad del dispositivo; su salida contiene datos privados. |
| `windows/` | Utilidades PowerShell/CMD para consultar y cambiar el rol USB del port de Windows. |
| `grapo-lite/generate_graph.py` | Genera un árbol local de archivos en HTML/JSON. |
| `manifest/` | Describe y comprueba la presencia de componentes aportados por cada usuario. |
| `tools/check-size.*` | Comprueba el tamaño de los archivos antes de publicar. |

El menú Bash contiene 21 opciones; el README histórico describe una versión anterior de 18. La interfaz Python es un acceso resumido y muestra el número correcto del menú Bash cuando delega una operación.

## Requisitos y comprobaciones sin dispositivo

Utiliza Python 3 y Bash en Linux. Los programas necesarios para operaciones sobre el teléfono, como ADB, fastboot y la herramienta EDL, se instalan por separado.

```bash
./msmkali --help
./msmkali --list
./msmkali --lang en --check
python3 tools/check-size.py
sha256sum -c HUELLAS.sha256
```

`--help`, `--list` y `--check` no acceden al teléfono. La comprobación de dependencias busca ejecutables en `PATH` y, si se configura el kit, comprueba la existencia de `edl.py`; no ejecuta ADB, fastboot ni EDL. El comando `doctor` del lanzador del PC informa dónde deben utilizarse los ayudantes y no ejecuta reparaciones sobre el sistema anfitrión.

## Configurar un kit propio

El código público no incluye firmware, imágenes de arranque, loaders, datos del módem ni herramientas de terceros. Conserva esos componentes en una carpeta privada independiente y comprueba su procedencia, modelo, versión e integridad.

La variable `MSMKALI_KIT_DIR` debe indicar la raíz absoluta de ese kit:

```bash
export MSMKALI_KIT_DIR='/ruta/absoluta/a/mi/msmkali-portable'
python3 manifest/fetch-firmware.py --src "$MSMKALI_KIT_DIR" --check
```

El comprobador informa de archivos presentes o ausentes y devuelve un código distinto de cero si falta alguno. Es una comprobación de presencia; no certifica que una imagen sea compatible ni que tenga una firma válida.

El menú necesita `firmware/out/` y `herramientas/`. El resto del diseño se describe en `manifest/firmware-manifest.json`. Los archivos que una operación necesita se deben comprobar antes de seleccionarla.

| Variable opcional | Uso |
|---|---|
| `MSMKALI_EDL` | Ruta del `edl.py` utilizado por el menú principal. |
| `MSMKALI_EDL_DIR` | Directorio del `edl.py` utilizado por el ayudante de rescate. |
| `MSMKALI_LOADER` | Loader compatible con el dispositivo. |
| `MSMKALI_BACKUP_DIR` | Destino privado de copias; por defecto, `backups/` dentro del kit. |
| `MSMKALI_LOG_DIR` | Destino privado de registros; por defecto, `logs/` dentro del kit. |
| `MSMKALI_BOOT_IMAGE` | Imagen de arranque propia para el ayudante de rescate si no se pasa como argumento. |

El menú y el rescate se detienen antes de operar cuando no se configura un kit. El rescate también exige que se indique una imagen propia; no conserva una ruta o imagen del dispositivo del autor.

## Operaciones sobre hardware

Después de revisar el código y preparar el kit, `./msmkali --lang es` abre la interfaz interactiva. Las operaciones de escritura, desbloqueo, formato o particionado pueden perder datos o impedir el arranque. Las confirmaciones del programa no sustituyen la verificación manual de modelo, particiones, imágenes y copias.

Usa únicamente tu propio dispositivo compatible y desconecta otros teléfonos. Los ayudantes Android/NetHunter se ejecutan en ese entorno, no en el PC. Los ayudantes de Windows pueden cambiar configuración del dispositivo y requieren sus privilegios correspondientes.

Los logs, copias de módem, IMEI, seriales, capturas de memoria y gráficos de directorios privados deben permanecer fuera del repositorio. Los comandos de diagnóstico pueden generarlos durante el uso aunque el código publicado no incluya muestras reales.

## Validación de esta publicación

Se ha revisado la sintaxis Python/Bash y se han comprobado las rutas de ayuda, listado, configuración ausente y comprobación de archivos. No se ha conectado un teléfono ni se han ejecutado flashes, desbloqueos, reparaciones, montajes de particiones o instalaciones para validar esta publicación.

Las notas privadas de sesiones se excluyen. Las guías de otros proyectos se enlazan en [THIRD_PARTY.md](../THIRD_PARTY.md) para conservar su autoría y consultar sus instrucciones vigentes.
