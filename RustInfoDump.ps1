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

if (!($IsWindows -and (Test-Path "$server/RustDedicated.exe")) -or !((Test-Path "$server/RustDedicated") -and $IsLinux)) {
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

# Make sure out directory exists
New-Item -Path $out -ItemType Directory -ErrorAction SilentlyContinue

## Copy plugin into server dir
Copy-Item -Path './RustDataDump.cs' -Destination "$server/oxide/plugins" -Recurse -Force

if ($IsWindows) {
    Start-Process -FilePath "$server/RustDedicated.exe" -Wait
}
else {
    Start-Process -FilePath "$server/RustDedicated" -Wait
}

if (!(Test-Path -Path "$server/oxide/logs/RustDataDump") -or (Get-ChildItem "$server/oxide/logs/RustDataDump").Length -lt 1) {
    Write-Error "Dump was not successfull, try again later!"
    exit 1
}

Get-ChildItem "$server/oxide/logs/RustDataDump" | Sort-Object LastWriteTime -OutVariable lastdump

$hashfunc = [System.Security.Cryptography.MD5]::Create()

$dumpcontent = Get-Content $lastdump.FullName -AsByteStream

$hash = $hashfunc.ComputeHash($dumpcontent)

$obj = @{
    hash = $hash
    data = (Get-Content $lastdump.FullName -Raw | ConvertFrom-Json -AsHashtable)
}

ConvertTo-Json $obj | Out-File -FilePath "$out/$($lastdump.Name)" -Force
