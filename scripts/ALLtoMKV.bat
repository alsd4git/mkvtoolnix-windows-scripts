@echo off
setlocal EnableExtensions DisableDelayedExpansion

set "deleteSource=0"
if "%~1"=="--delete-source" (
    if not "%~2"=="" (
        echo Usage: ALLtoMKV [--delete-source]
        exit /b 2
    )
    set "deleteSource=1"
) else if not "%~1"=="" (
    echo Usage: ALLtoMKV [--delete-source]
    exit /b 2
)

where mkvmerge >nul 2>&1
if errorlevel 1 (
    echo mkvmerge was not found on PATH.
    exit /b 1
)

set "foundInput="
set "failed="
for %%A in (*.avi *.mp4 *.flv *.mpg *.mpeg *.rmvb *.ts *.mov) do if exist "%%~fA" (
    set "foundInput=1"
    set "source=%%~fA"
    set "output=%%~dpnA.mkv"
    set "log=%%~dpnA.mkvmerge.log"
    call :processFile
    if errorlevel 1 set "failed=1"
)

if not defined foundInput echo No supported video files found in the current directory.
if defined failed exit /b 1
exit /b 0

:processFile
if exist "%output%" (
    echo Skipping "%source%": output "%output%" already exists.
    exit /b 1
)
if exist "%log%" (
    echo Skipping "%source%": log "%log%" already exists.
    exit /b 1
)

echo Remuxing "%source%"...
mkvmerge -o "%output%" "%source%" --ui-language en >"%log%" 2>&1
set "mergeResult=%ERRORLEVEL%"
if "%mergeResult%"=="1" (
    echo mkvmerge completed with warnings. Source retained; review "%log%".
    exit /b 1
)
if not "%mergeResult%"=="0" (
    echo mkvmerge failed with exit code %mergeResult%. Source retained; see "%log%".
    exit /b 1
)
if not exist "%output%" (
    echo mkvmerge reported success but created no output. Source retained; see "%log%".
    exit /b 1
)
for %%Z in ("%output%") do if %%~zZ LEQ 0 (
    echo mkvmerge created an empty output. Source retained; see "%log%".
    exit /b 1
)

echo Created "%output%". Source retained.
if "%deleteSource%"=="1" (
    del /q /f "%source%"
    if exist "%source%" (
        echo Could not remove source "%source%".
        exit /b 1
    )
    echo Removed source "%source%" after successful remux.
)
exit /b 0

::"--language" "0:jpn" "--language" "1:ita"
:: if added before "%%~A" you can set tracks language

:: --atracks 1
:: keep only the selcted track (in this case "a" stand for audio track) with the choosen number (1 is the f)
:: using "--atracks 1,2" you ca keep track 1 and 2

:: "%%~nA.srt" before "%%~A" ifd you want to add a subtitle track with the same name as the file
:: --attach-file "cover.jpg" if you want to add a cover as an attachment
::(remeber to use the name "cover.jpg" as stated in the mkv guideline)
