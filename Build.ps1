param (
    [switch]$DepotDownloader,
    [switch]$IL2CPPDumper
)

if (!$DepotDownloader -and !$IL2CPPDumper) {
    $DepotDownloader = $IL2CPPDumper = $true
}

if (!(Test-Path -Path "./config.json")) {
    Write-Error "Could not find configuration file. Make sure it exists at '$PSScriptRoot/config.json' and try again"
    exit 1
}

$config = Get-Content "./config.json" -Raw | ConvertFrom-Json -AsHashtable

if (($DepotDownloader -and !$config.depotdownloader) -or ($IL2CPPDumper -and !$config.il2cppdumper)) {
    Write-Error 'Could not parse configuration correctly, exiting'
    exit 1
}

if (!(Get-Command "git" -ErrorAction SilentlyContinue)) {
    Write-Error 'Could not find Git in path, exiting'
    exit 1
}

if (!(Get-Command "dotnet" -ErrorAction SilentlyContinue)) {
    Write-Error 'Could not find dotnet in path, exiting'
    exit 1
}

if (!(Get-Command "nuget" -ErrorAction SilentlyContinue) -and $IL2CPPDumper) {
    Write-Error "Could not find nuget in path, it's required to build IL2CPPDumper, exiting"
    exit 1
}

&git.exe submodule update --init

if (!(Test-Path -Path "$PSScriptRoot/DepotDownloader") -and $DepotDownloader) {
    Write-Error 'Could not find DepotDownloader repo, exiting'
    exit 1
}

if (!(Test-Path -Path "$PSScriptRoot/Il2CppDumper") -and $IL2CPPDumper) {
    Write-Error 'Could not find Il2CppDumper repo, exiting'
    exit 1
}

if ($DepotDownloader) {
    Write-Host "Started build of DepotDownloader..." -ForegroundColor Gray

    Write-Host "Restoring dependencies..."

    $out = Split-Path $config.depotdownloader -Parent

    Write-Host "Out path will be: '$out'" -ForegroundColor Gray

    &dotnet.exe restore './DepotDownloader' | Out-Null

    Write-Host "Building project..." -NoNewline

    &dotnet.exe build './DepotDownloader' -o $out | Out-Null

    Write-Host 'Finished' -ForegroundColor Green
}

if ($IL2CPPDumper) {
    Write-Host "Started build of IL2CPPDumper..." -ForegroundColor Gray

    Write-Host 'Restoring dependencies...'

    &nuget.exe restore './Il2CppDumper' | Out-Null

    $out = Split-Path $config.il2cppdumper -Parent

    Write-Host "Out path will be: '$out'" -ForegroundColor Gray

    Write-Host 'Building project..' -NoNewline

    &dotnet.exe build './Il2CppDumper' -o $out | Out-Null

    Write-Host 'Finished' -ForegroundColor Green
}


