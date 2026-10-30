$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
$testRoot = Join-Path $env:RUNNER_TEMP ("mkv-safety-tests-{0}" -f [guid]::NewGuid())
$toolsPath = Join-Path $testRoot 'stub tools'
$mergeLog = Join-Path $testRoot 'mkvmerge-arguments.txt'
$editLog = Join-Path $testRoot 'mkvpropedit-arguments.txt'
$originalPath = $env:Path
$originalLocation = Get-Location

function Assert-That([bool]$Condition, [string]$Message) {
    if (-not $Condition) {
        throw $Message
    }
}

function New-WorkingDirectory([string]$Name) {
    $path = Join-Path $testRoot $Name
    New-Item -ItemType Directory -Path $path | Out-Null
    return $path
}

function Invoke-Batch([string]$ScriptPath, [string[]]$Arguments = @()) {
    $quotedArguments = ($Arguments | ForEach-Object { '"{0}"' -f $_ }) -join ' '
    $commandLine = 'call "{0}" {1}' -f $ScriptPath, $quotedArguments
    & $env:ComSpec /d /c $commandLine
    return $LASTEXITCODE
}

try {
    New-Item -ItemType Directory -Path $testRoot | Out-Null
    New-Item -ItemType Directory -Path $toolsPath | Out-Null
    @'
@echo off
if not defined MKVMERGE_EXIT_CODE set "MKVMERGE_EXIT_CODE=0"
>>"%MKVMERGE_LOG%" echo %*
if "%MKVMERGE_EXIT_CODE%"=="2" exit /b 2
if "%MKVMERGE_NO_OUTPUT%"=="1" exit /b 0
>"%~2" echo synthetic output
exit /b %MKVMERGE_EXIT_CODE%
'@ | Set-Content -Path (Join-Path $toolsPath 'mkvmerge.cmd') -Encoding ascii
    @'
@echo off
if not defined MKVPROPEDIT_EXIT_CODE set "MKVPROPEDIT_EXIT_CODE=0"
>>"%MKVPROPEDIT_LOG%" echo %*
exit /b %MKVPROPEDIT_EXIT_CODE%
'@ | Set-Content -Path (Join-Path $toolsPath 'mkvpropedit.cmd') -Encoding ascii

    $env:Path = "$toolsPath;$originalPath"
    $env:MKVMERGE_LOG = $mergeLog
    $env:MKVPROPEDIT_LOG = $editLog
    $env:MKVMERGE_EXIT_CODE = '0'
    $env:MKVPROPEDIT_EXIT_CODE = '0'

    $defaultDirectory = New-WorkingDirectory 'default success'
    $defaultSource = Join-Path $defaultDirectory 'sample video.mp4'
    Set-Content -Path $defaultSource -Value 'synthetic source'
    Set-Location $defaultDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat')
    Assert-That ($result -eq 0) 'Default batch conversion should succeed.'
    Assert-That (Test-Path $defaultSource) 'Default conversion deleted its source.'
    Assert-That (Test-Path (Join-Path $defaultDirectory 'sample video.mkv')) 'Successful conversion did not create its MKV.'
    Assert-That (Test-Path (Join-Path $defaultDirectory 'sample video.mkvmerge.log')) 'Successful conversion did not keep its log.'

    $multipleDirectory = New-WorkingDirectory 'multiple inputs'
    $firstMultipleSource = Join-Path $multipleDirectory 'first.mp4'
    $secondSource = Join-Path $multipleDirectory 'second.mp4'
    Set-Content -Path $firstMultipleSource -Value 'synthetic source'
    Set-Content -Path $secondSource -Value 'synthetic source'
    Set-Location $multipleDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat')
    Assert-That ($result -eq 0) 'Batch conversion should process multiple inputs.'
    Assert-That ((Test-Path $firstMultipleSource) -and (Test-Path (Join-Path $multipleDirectory 'first.mkv'))) 'Batch conversion did not retain and convert the first input.'
    Assert-That ((Test-Path $secondSource) -and (Test-Path (Join-Path $multipleDirectory 'second.mkv'))) 'Batch conversion did not retain and convert the second input.'

    $deleteDirectory = New-WorkingDirectory 'explicit deletion'
    $deleteSource = Join-Path $deleteDirectory 'delete me.mp4'
    Set-Content -Path $deleteSource -Value 'synthetic source'
    Set-Location $deleteDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -eq 0) 'Explicit-delete conversion should succeed.'
    Assert-That (-not (Test-Path $deleteSource)) 'Explicit deletion did not remove the successfully remuxed source.'
    Assert-That (Test-Path (Join-Path $deleteDirectory 'delete me.mkv')) 'Explicit-delete conversion did not create its MKV.'

    $failureDirectory = New-WorkingDirectory 'mkvmerge failure'
    $failureSource = Join-Path $failureDirectory 'failure.mp4'
    Set-Content -Path $failureSource -Value 'synthetic source'
    Set-Location $failureDirectory
    $env:MKVMERGE_EXIT_CODE = '2'
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -ne 0) 'A failed remux should return a non-zero exit status.'
    Assert-That (Test-Path $failureSource) 'A failed remux deleted its source.'
    Assert-That (-not (Test-Path (Join-Path $failureDirectory 'failure.mkv'))) 'The failing stub unexpectedly created an MKV.'
    Assert-That (Test-Path (Join-Path $failureDirectory 'failure.mkvmerge.log')) 'The failed conversion did not keep its log.'
    $env:MKVMERGE_EXIT_CODE = '0'

    $warningDirectory = New-WorkingDirectory 'mkvmerge warning'
    $warningSource = Join-Path $warningDirectory 'warning.mp4'
    Set-Content -Path $warningSource -Value 'synthetic source'
    Set-Location $warningDirectory
    $env:MKVMERGE_EXIT_CODE = '1'
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -ne 0) 'A warning exit status should be reported for review.'
    Assert-That (Test-Path $warningSource) 'A warning exit status deleted its source.'
    Assert-That (Test-Path (Join-Path $warningDirectory 'warning.mkv')) 'Warning test did not produce a usable output.'
    $env:MKVMERGE_EXIT_CODE = '0'

    $missingOutputDirectory = New-WorkingDirectory 'missing output'
    $missingOutputSource = Join-Path $missingOutputDirectory 'missing output.mp4'
    Set-Content -Path $missingOutputSource -Value 'synthetic source'
    Set-Location $missingOutputDirectory
    $env:MKVMERGE_NO_OUTPUT = '1'
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -ne 0) 'A successful exit without an output should be reported as failure.'
    Assert-That (Test-Path $missingOutputSource) 'A missing output caused source deletion.'
    $env:MKVMERGE_NO_OUTPUT = '0'

    $collisionDirectory = New-WorkingDirectory 'output collision'
    $collisionSource = Join-Path $collisionDirectory 'collision.mp4'
    $existingOutput = Join-Path $collisionDirectory 'collision.mkv'
    Set-Content -Path $collisionSource -Value 'synthetic source'
    Set-Content -Path $existingOutput -Value 'preserve this output'
    Set-Location $collisionDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -ne 0) 'An output collision should return a non-zero exit status.'
    Assert-That (Test-Path $collisionSource) 'An output collision deleted its source.'
    Assert-That ((Get-Content $existingOutput -Raw).Trim() -eq 'preserve this output') 'An output collision overwrote the existing MKV.'

    $logCollisionDirectory = New-WorkingDirectory 'log collision'
    $logCollisionSource = Join-Path $logCollisionDirectory 'log-collision.mp4'
    $existingLog = Join-Path $logCollisionDirectory 'log-collision.mkvmerge.log'
    Set-Content -Path $logCollisionSource -Value 'synthetic source'
    Set-Content -Path $existingLog -Value 'preserve this log'
    Set-Location $logCollisionDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\ALLtoMKV.bat') @('--delete-source')
    Assert-That ($result -ne 0) 'A log collision should return a non-zero exit status.'
    Assert-That (Test-Path $logCollisionSource) 'A log collision deleted its source.'
    Assert-That ((Get-Content $existingLog -Raw).Trim() -eq 'preserve this log') 'A log collision overwrote the existing log.'

    $coverDirectory = New-WorkingDirectory 'cover matching'
    $coverMkv = Join-Path $coverDirectory 'movie with spaces.mkv'
    $matchedCover = Join-Path $coverDirectory 'movie with spaces.png'
    $unrelatedImage = Join-Path $coverDirectory 'unrelated.png'
    Set-Content -Path $coverMkv -Value 'synthetic MKV placeholder'
    Set-Content -Path $matchedCover -Value 'synthetic cover'
    Set-Content -Path $unrelatedImage -Value 'keep unrelated image'
    Set-Location $coverDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\mkvAddCover.bat')
    Assert-That ($result -eq 0) 'Cover attachment should succeed with the command stub.'
    Assert-That ((Test-Path $matchedCover) -and (Test-Path $unrelatedImage)) 'Cover attachment deleted artwork.'
    $editArguments = Get-Content $editLog -Raw
    Assert-That ($editArguments.Contains($coverMkv) -and $editArguments.Contains($matchedCover)) 'The per-file cover or MKV path was not passed to mkvpropedit.'
    Assert-That ($editArguments.Contains('--attachment-name "cover.png"')) 'Per-file artwork was not attached with the standard cover filename.'

    $genericDirectory = New-WorkingDirectory 'generic cover'
    $genericMkv = Join-Path $genericDirectory 'no matching image.mkv'
    $genericCover = Join-Path $genericDirectory 'cover.jpg'
    Set-Content -Path $genericMkv -Value 'synthetic MKV placeholder'
    Set-Content -Path $genericCover -Value 'synthetic generic cover'
    Set-Location $genericDirectory
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\mkvAddCover.bat')
    Assert-That ($result -eq 0) 'Generic cover attachment should succeed.'
    Assert-That (Test-Path $genericCover) 'Generic cover was deleted.'
    $editArguments = Get-Content $editLog -Raw
    Assert-That ($editArguments.Contains($genericCover)) 'Generic cover path was not passed to mkvpropedit.'
    Assert-That ($editArguments.Contains('--attachment-name "cover.jpg"')) 'Generic artwork was not attached with the standard cover filename.'

    $noCoverDirectory = New-WorkingDirectory 'missing cover'
    $noCoverMkv = Join-Path $noCoverDirectory 'no cover.mkv'
    Set-Content -Path $noCoverMkv -Value 'synthetic MKV placeholder'
    Set-Location $noCoverDirectory
    $previousEditLogLength = (Get-Item $editLog).Length
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\mkvAddCover.bat')
    Assert-That ($result -eq 0) 'Missing cover should skip cleanly.'
    Assert-That ((Get-Item $editLog).Length -eq $previousEditLogLength) 'mkvpropedit was called despite missing artwork.'

    $editFailureDirectory = New-WorkingDirectory 'mkvpropedit failure'
    $editFailureMkv = Join-Path $editFailureDirectory 'failed cover.mkv'
    $editFailureCover = Join-Path $editFailureDirectory 'cover.png'
    Set-Content -Path $editFailureMkv -Value 'synthetic MKV placeholder'
    Set-Content -Path $editFailureCover -Value 'synthetic cover'
    Set-Location $editFailureDirectory
    $env:MKVPROPEDIT_EXIT_CODE = '2'
    $result = Invoke-Batch (Join-Path $repoRoot 'scripts\mkvAddCover.bat')
    Assert-That ($result -ne 0) 'mkvpropedit failure should return a non-zero status.'
    Assert-That ((Test-Path $editFailureMkv) -and (Test-Path $editFailureCover)) 'mkvpropedit failure deleted source artwork.'

    Write-Host 'Windows safety regression tests passed.'
}
finally {
    Set-Location $originalLocation
    $env:Path = $originalPath
    Remove-Item Env:MKVMERGE_LOG -ErrorAction SilentlyContinue
    Remove-Item Env:MKVPROPEDIT_LOG -ErrorAction SilentlyContinue
    Remove-Item Env:MKVMERGE_EXIT_CODE -ErrorAction SilentlyContinue
    Remove-Item Env:MKVMERGE_NO_OUTPUT -ErrorAction SilentlyContinue
    Remove-Item Env:MKVPROPEDIT_EXIT_CODE -ErrorAction SilentlyContinue
    if (Test-Path $testRoot) {
        Remove-Item -Path $testRoot -Recurse -Force
    }
}
