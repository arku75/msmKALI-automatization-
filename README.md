# msmKALI — Kit portable todo-en-uno para el OnePlus 7 Pro (GM1913 / guacamole)

> **Created and maintained by Luka Sorta · Ajdovščina, Slovenia**

## Professional overview

**msmKALI** is a recovery- and verification-oriented automation project for the **OnePlus 7 Pro GM1913**. It brings together device-state detection, backup-first workflows, integrity checks, recovery paths, Windows ARM preparation and Kali NetHunter-related setup into one guided toolkit.

The project is presented as a practical systems-automation case study: the goal is not to claim ownership of the third-party tools it orchestrates, but to make a complex real-device workflow easier to reproduce, inspect and recover.

**Portfolio context:** [Luka Sorta / arku75](https://github.com/arku75) · [EIDOS](https://github.com/arku75/EIDOS)

---



**Recupera, reinstala, particiona, arranca Windows, rootea e instala Kali NetHunter en un OnePlus 7 Pro — desde un solo menú, sin descargar nada, funcione o no el teléfono.**

Un único programa (`msmkali.sh`) con menú numerado, pensado para que **cualquiera** —no solo un experto— pueda salvar y preparar su OnePlus 7 Pro paso a paso, con red de seguridad en cada acción.

---

## 📱 ¿Para qué modelo es? (léelo antes de nada)

Este kit está construido y probado para el:

> **OnePlus 7 Pro — modelo `GM1913` (variante global/EU)**
> Nombre en clave: **`guacamole`** · SoC: Snapdragon 855 (SM8150) · Base: **OxygenOS 11 (Android 11)**

- Casi todo vale también para la **familia guacamole** (GM1910, GM1915) y el OnePlus 7/7T, pero **el firmware incluido es de la GM1913**. Si tu modelo es otro, usa las herramientas pero **no flashees el firmware de aquí sin comprobar tu variante**.
- **NO es para** OnePlus 7 (sin Pro, "guacamoleb"), 7T Pro McLaren, ni otros teléfonos. El bootloader, el firmware y el particionado son específicos.

⚠️ **El hardware manda.** Flashear firmware del modelo equivocado puede dejar el teléfono inservible.

---

## ✨ ¿Qué hace? (las 18 funciones del menú)

| # | Opción | Qué hace |
|---|--------|----------|
| 1 | **Estado** | Detecta el móvil (ADB/fastboot/EDL) y te dice en qué modo está |
| 2 | **Backup IMEI** | Copia EFS/IMEI/persist (**lo irremplazable** — hazlo SIEMPRE primero) |
| 3 | **Verificar** | Comprueba con SHA256 que nada del kit se ha corrompido |
| 4 | **EDL** | Entra al modo de rescate Qualcomm 9008 y lee la tabla de particiones |
| 5 | **Restaurar** | Devuelve IMEI/persist si un flasheo los corrompió |
| 6 | **Flashear** | Reinstala OxygenOS 11 completo |
| 7 | **SMT** | Recupera el temido **"SMT Download Failed"** con el MSM Tool |
| 8 | **Unlock** | Desbloquea el bootloader |
| 9 | **Preparar PC** | Instala dependencias en tu Linux (python, adb, fastboot, drivers) |
| 10 | **Ayuda** | Guía offline y explicación de cada paso |
| 11 | **Particionar** | Reparte el espacio entre Android y Windows (tú eliges los GB) |
| 12 | **Formatear Windows** | Prepara la partición NTFS para Windows |
| 13 | **Root** | Instala Magisk conservando el arranque dual |
| 14 | **Windows** | Instala Windows 11 ARM en su partición |
| 15 | **NetHunter** | Instala Kali NetHunter (entorno + apps) |
| 16 | **DBKP** | Selector de arranque por la **palanca lateral** (arriba=Windows, abajo=Android) |
| 17 | **Rescate EDL** ⭐ | Reescribe la partición boot con un backup bueno — **salva de un brick por kernel malo en 5 minutos, sin borrar nada** |
| 18 | **Escritorio Kali** | Enciende/apaga el escritorio gráfico de Kali (KeX) |

Resultado final posible: **triple sistema** en un móvil — Windows 11 ARM + Android/OxygenOS + Kali NetHunter, eligiendo con la palanca lateral.

---

## 🎯 Ventajas de usar msmKALI

- **Todo dentro, sin internet.** El kit (~8 GB) lleva el firmware OOS11, el MSM Tool, TWRP, el UEFI de Windows, Magisk, NetHunter, `edl.py` con la autenticación de OnePlus ya parcheada, y la guía completa. Copias la carpeta y funciona aunque no tengas conexión.
- **Recupera lo "irrecuperable".** El error **SMT Download Failed** deja el móvil en un modo de fábrica que asusta; aquí está la receta que lo arregla (opción 7), y un **rescate por EDL** (opción 17) que revive el teléfono sin borrar Windows ni el IMEI.
- **Red de seguridad en cada paso.** Backup de IMEI/persist con verificación SHA256, avisos antes de lo irreversible, y confirmación por teclado (`ACEPTO`) en lo peligroso.
- **Para el público general.** Menú numerado, en español claro, que te lleva de la mano. No hace falta saber de bootloaders para seguirlo.
- **Un solo teléfono, tres sistemas.** Windows de escritorio ARM, Android de diario, y Kali para seguridad — en el mismo aparato.
- **Reproducible.** Cada acción está documentada; si algo sale mal, sabes exactamente qué pasó y cómo volver atrás.

---

## 🚀 Cómo se usa

**Necesitas:** un PC con Linux (Kali o cualquier distro), un cable USB, y tu OnePlus 7 Pro GM1913.

```bash
# 1. Copia la carpeta entera a tu Linux
# 2. Entra y lánzalo:
cd msmkali-portable
./msmkali.sh
```

**Orden recomendado la primera vez:**
1. Opción **9** — preparar el PC (instala lo que falte).
2. Opción **10** — leer la ayuda.
3. Opción **2** — backup del IMEI (**imprescindible antes de cualquier cosa que borre**).
4. A partir de ahí, la opción que necesites.

**Comprobar que el kit está íntegro:**
```bash
sha256sum -c HUELLAS.sha256
```

---

## 🧯 Rescate rápido (lo más valioso)

Si tras un flasheo el móvil no arranca (pantalla negra, "Qualcomm CrashDump", bucle) y **no entra ni en fastboot ni en recovery**, casi siempre es recuperable:

```bash
./rescate_edl.sh          # o la opción 17 del menú
```

Reescribe solo la partición **boot** con una imagen buena verificada — **conserva Windows, el particionado, el IMEI y los datos**. Combo para entrar en EDL: apagar del todo, mantener **Vol Arriba + Vol Abajo** y conectar el USB.

> Nace de una historia real: el teléfono se brickeó con un kernel mal parcheado y se rescató así en 5 minutos en lugar de perder una noche.

---

## 📂 Qué hay dentro

```
msmkali.sh        el programa (menú de 18 opciones)
rescate_edl.sh    rescate por EDL, independiente
herramientas/     edl.py con la auth de OnePlus parcheada, loaders firehose
firmware/         OxygenOS 11 completo
recovery/         TWRP modificado
uefi/             arranque de Windows (edk2 del proyecto WOA)
dualboot/         selector por palanca (DBKP) + modemprov (LTE en Windows)
root/             Magisk
nethunter/        Kali NetHunter (entorno + apps)
guia/             guía oficial + todo lo aprendido, sin internet
backups/          espacio para tus copias (IMEI, boot, etc.)
HUELLAS.sha256    para verificar que nada se ha corrompido
LEEME.txt         resumen rápido
```

---

## 🐉 Sobre el Kali NetHunter que instala

- Es **NetHunter clásico**: un **chroot de Kali sobre Android** (no reemplaza Android, convive con él). Android sigue dando llamadas, datos, GPS y WiFi.
- Se usa de dos formas:
  - **NetHunter Terminal** (la app NeoTerm): shell **root** de Kali, con red, táctil, rápida. **La vía recomendada** para trabajar.
  - **Escritorio gráfico (KeX)**: XFCE por VNC. Vistoso, pero **va a tirones** (es la naturaleza del VNC en chroot). Úsalo como extra, no como principal.
- **Modo monitor WiFi / inyección / HID-BadUSB**: requieren el **kernel NetHunter** y un **adaptador WiFi USB-OTG externo**. El WiFi interno del OnePlus **no** hace modo monitor. Sin adaptador, tienes todas las herramientas para trabajo en red normal (escaneo, web, MITM en tu red, OSINT), pero no captura en modo monitor.

---

## ⚠️ Avisos importantes

- **Modificar un teléfono conlleva riesgo de brick.** Sigue el orden, no interrumpas un flasheo, y haz siempre el backup del IMEI primero. Los autores no se responsabilizan de daños.
- **Windows 11 ARM** en este móvil es un port de la comunidad (proyecto WOA): funciona el táctil, WiFi, GPU, etc., **pero la carga de batería está desactivada** (limitación del port) — se carga en Android o apagado.
- **Kali y sus herramientas** son para **pruebas de seguridad en sistemas propios o con permiso**. Usarlas contra terceros sin autorización es ilegal.
- **No afiliado** con OnePlus, Qualcomm, Kali/OffSec ni Microsoft. Marcas de sus dueños. Este kit reúne herramientas libres y firmware del fabricante para uso personal de recuperación.

---

## 🙏 Créditos

Construido sobre el trabajo de: **bkerler** (edl.py), el equipo de **Kali NetHunter / OffSec**, el proyecto **Windows on ARM para OnePlus 7 (n00b69 / Renegade Project)**, **TWRP**, **Magisk (topjohnwu)** y **DualBootKernelPatcher**. Gracias a todos ellos.

---

*Kit de recuperación personal para OnePlus 7 Pro GM1913. Úsalo con cabeza y con backups.*
