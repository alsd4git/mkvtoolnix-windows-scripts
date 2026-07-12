# MKVToolNix Windows Scripts

> Formerly **MKVToolNixScriptCollection**.

Windows Command Prompt utilities for remuxing video files and managing MKV
cover art with [MKVToolNix](https://mkvtoolnix.download/).

## Requirements

- Windows 10 or later
- MKVToolNix installed and available on `PATH`

## Safety

These scripts modify media files in place. Test them on copies first and keep
backups of your library. `mkvAddCover.bat` also removes JPEG and PNG files as
part of its cleanup step.

## Scripts

### `install.bat`

Installs the helper scripts next to MKVToolNix and adds them to `PATH`. Run it
from an elevated Command Prompt.

### `ALLtoMKV.bat`

Remuxes supported video files into MKV without re-encoding. Supported inputs:

- `.avi`, `.mp4`, `.flv`, `.mpg`, `.mpeg`, `.rmvb`, `.ts`, and `.mov`

Run `ALLtoMKV` from the directory containing the media files.

### `mkvAddCover.bat`

Adds a generic `cover.jpg` or `cover.png` to every MKV in the current directory,
or matches `movie_name.jpg` to `movie_name.mkv`. It deletes JPEG and PNG files
after completing its cleanup step.

## License

The repository's batch scripts are MIT licensed; see [LICENSE](LICENSE).
`scripts/tee.exe` is a third-party executable and is not covered by that
license; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
