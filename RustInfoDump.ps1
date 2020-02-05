param (
    [string]$server,
    [string]$out,
    [switch]$NoDelete
)

$config = Get-Content './config,json' -Raw | ConvertFrom-Json -AsHashtable

if (!$server) {
    $server = $config.rustinfodump.'server-dir'
}

if (!$out) {
    $out = $config.rustinfodump.'out-dir'
}

if (!(Test-Path "$server/RustDedicated.exe")) {
    Write-Error 'Could not find RustDedicated executable! Verify configuration and try again'
    exit 1
}

if (!(Test-Path "$server/RustDedicated_Data/Managed/Oxide.Core.dll")) {
    Write-Error 'Could not find Oxide! Make sure it is installed and try again'
    exit 1    
}

if (!(Test-Path -Path './RustDataDump.cs')) {
    Write-Error 'Could not find plugin! Make sure repository is up to date!'
    exit 1
}

New-Item -Path $out -ItemType Directory -ErrorAction SilentlyContinue

Copy-Item -Path './RustDataDump.cs' -Destination "$server/oxide/plugins" -Recurse -Force

## launch server and stuff (placeholder)
