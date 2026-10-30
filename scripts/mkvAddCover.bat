@echo off
setlocal EnableExtensions DisableDelayedExpansion

where mkvpropedit >nul 2>&1
if errorlevel 1 (
    echo mkvpropedit was not found on PATH.
    exit /b 1
)

set "foundMkv="
set "failed="
for %%M in (*.mkv) do if exist "%%~fM" (
    set "foundMkv=1"
    call :attachCover "%%~fM"
    if errorlevel 1 set "failed=1"
)

if not defined foundMkv (
    echo No MKV files found in the current directory.
    exit /b 0
)
if defined failed exit /b 1
exit /b 0

:attachCover
set "mkvPath=%~1"
set "basePath=%~dpn1"
set "coverPath="
if exist "%basePath%.png" set "coverPath=%basePath%.png"
if not defined coverPath if exist "%basePath%.jpg" set "coverPath=%basePath%.jpg"
if not defined coverPath if exist "cover.png" set "coverPath=%CD%\cover.png"
if not defined coverPath if exist "cover.jpg" set "coverPath=%CD%\cover.jpg"

if not defined coverPath (
    echo No per-file or generic JPG/PNG cover found for "%mkvPath%". Skipping.
    exit /b 0
)

for %%C in ("%coverPath%") do set "coverName=cover%%~xC"
echo Attaching "%coverPath%" to "%mkvPath%"...
mkvpropedit "%mkvPath%" --attachment-name "%coverName%" --add-attachment "%coverPath%"
if errorlevel 1 (
    echo Failed to attach cover to "%mkvPath%". Input images were retained.
    exit /b 1
)
exit /b 0
