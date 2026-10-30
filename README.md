# MKVToolNix Windows Scripts

[![CI](https://github.com/alsd4git/mkvtoolnix-windows-scripts/actions/workflows/ci.yml/badge.svg)](https://github.com/alsd4git/mkvtoolnix-windows-scripts/actions/workflows/ci.yml)

> Formerly **MKVToolNixScriptCollection**.

Windows Command Prompt utilities for remuxing video files and managing MKV
cover art with [MKVToolNix](https://mkvtoolnix.download/).

## Requirements

- Windows 10 or later
- MKVToolNix installed and available on `PATH`

## Safety

`ALLtoMKV.bat` keeps source videos by default and refuses to overwrite an
existing MKV or log. Source deletion is available only through the explicit
`--delete-source` option, and only after `mkvmerge` exits successfully and
creates a non-empty MKV. Keep backups before modifying a media library.

`mkvAddCover.bat` never deletes or renames artwork. It attaches the selected
image directly to each MKV and names the attachment `cover.jpg` or
`cover.png`.

## Scripts

### `install.bat`

Installs the helper scripts next to MKVToolNix and adds them to `PATH`. Run it
from an elevated Command Prompt.

### `ALLtoMKV.bat`

Remuxes supported video files into MKV without re-encoding. Supported inputs:

- `.avi`, `.mp4`, `.flv`, `.mpg`, `.mpeg`, `.rmvb`, `.ts`, and `.mov`

Run `ALLtoMKV` from the directory containing the media files. Each input gets
a `.mkvmerge.log` file, which is kept for review. Existing output or log files
are not overwritten. The default command keeps every source file:

```bat
ALLtoMKV
```

To remove a source only after a verified successful remux, explicitly opt in:

```bat
ALLtoMKV --delete-source
```

Warnings and errors reported through a non-zero `mkvmerge` exit status keep the
source. The script exits with a non-zero status if any input fails or is
skipped because of a collision.

### `toMKV.bat`

Remuxes one file into MKV without re-encoding. Pass the source path as the first argument:

```bat
toMKV "D:\Videos\example.mp4"
```

The source file is retained. If an MKV with the same base name already exists, `mkvmerge` decides whether the command can proceed.

### `mkvAddCover.bat`

Attaches artwork to each MKV in the current directory. For each file it selects
the first available image in this order: matching `movie_name.png`, matching
`movie_name.jpg`, generic `cover.png`, then generic `cover.jpg`. If no image is
available, that MKV is skipped. All images are retained, including on failure.

```bat
cd /d D:\Videos\Movie
mkvAddCover
```

## License

The repository's batch scripts are MIT licensed; see [LICENSE](LICENSE).
`scripts/tee.exe` is a third-party executable and is not covered by that
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
