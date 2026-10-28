# msmKALI · public source edition

Automation sources for the OnePlus 7 Pro GM1913 / guacamole. The existing project attribution is preserved in [README.md](README.md).

This edition publishes the reusable scripts from the author's portable kit. Device firmware, recovery images, third-party executables, personal backups and hardware logs are not included. Supply compatible components from your own trusted sources.

## Start by inspecting the commands

```bash
./msmkali --help
./msmkali --list
python3 scripts/msmkali.py --check
```

These commands do not flash or contact a phone. `--check` checks command availability and the configured local EDL path. A nonzero result can mean a required command is missing.

The [public source guide](docs/PUBLIC_SOURCE_GUIDE.md) explains the layout, explicit kit configuration, device operations and verification limits. The [publication notes](docs/PUBLICATION_NOTES.md) describe the changes made for this release. See [third-party attribution](THIRD_PARTY.md) for upstream projects.

Hardware repair, unlocking, partitioning and flashing remain destructive operations. The historical scripts require inspection and compatible hardware; they have not been rerun against a phone for this public release.
