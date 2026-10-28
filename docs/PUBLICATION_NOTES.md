# Public source release · 2026-10-28

The previously published repository contained a README. This release adds the curated source package while retaining every part of that README and its existing authorship attribution. Its historical description is marked separately from the current source-only distribution.

## Changes for reuse

- The root launcher forwards `--lang`, `--help`, `--list`, `--check` and other arguments correctly. The short `es` and `en` forms are retained.
- The main Bash menu requires an explicit `MSMKALI_KIT_DIR` and no longer falls back to personal filesystem paths.
- The EDL rescue helper requires the user's own kit and boot image. Slot arguments are validated.
- The ADB selector no longer falls back to the first connected device when no recognized OnePlus is found.
- The summarized Python menu points to the correct Bash entries for NetHunter diagnostics and USB configuration.
- The PC launcher does not run Android/chroot repair helpers on the PC.
- Firmware-presence checks accept the documented `--check` flag and return failure when components are missing.
- Personal session notes, internal network addresses, device serials, hardware dumps and third-party guide mirrors are excluded.
- Included source files have a newly generated SHA-256 manifest. Runtime data remains outside the public package.

## Validation boundaries

Python parsing, Bash syntax, command-line help/listing, missing-configuration refusal, local manifest checks and source integrity have been checked. No hardware write, ADB operation, flash, recovery, partition, package-installation or real-device behavior was executed for this release. The scripts remain an experimental toolkit for compatible hardware and require review before device operations.

## Attribution and licensing

The existing MIT notice for msmKALI contributors is retained. Upstream firmware, binaries and copied guides are not distributed. The repository's previously published author attribution is preserved rather than inferred from a different current profile name.
