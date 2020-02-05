param (
    [string]$server,
    [string]$out,
    [switch]$NoDelete
)

$config = Get-Content './config.json' -Raw | ConvertFrom-Json -AsHashtable

if (!$server) {
    $server = $config.rustinfodump.'server-dir'
}

if (!$out) {
    $out = $config.rustinfodump.'out-dir'
}

$server = Resolve-Path -Path $server -ErrorAction SilentlyContinue
$out = Resolve-Path -Path $out -ErrorAction SilentlyContinue

$server_bin = if ($IsWindows) { Join-Path -Path $server -ChildPath 'RustDedicated.exe' } elseif ($IsLinux) { Join-Path -Path $server -ChildPath 'RustDedicated' }
$oxide_bin = Join-Path -Path $server -ChildPath 'RustDedicated_Data/Managed/Oxide.Core.dll'
$plugin_path = "$PSScriptRoot/RustDataDump.cs"

if (!$server_bin) {
    Write-Error 'Your system is not supported!'
    exit 1
}

if (($IsWindows -and !(Test-Path $server_bin)) -or ($IsLinux -and !(Test-Path $server_bin))) {
    Write-Error 'Could not find RustDedicated executable! Verify configuration and try again'
    exit 1
}

if (!(Test-Path $oxide_bin)) {
    Write-Error 'Could not find Oxide! Make sure it is installed and try again'
    exit 1    
}

if (!(Test-Path -Path $plugin_path)) {
    Write-Error 'Could not find plugin! Make sure repository is up to date!'
    exit 1
}

# Make sure out directory exists
New-Item -Path $out -ItemType Directory -ErrorAction SilentlyContinue

## Copy plugin into server dir
Copy-Item -Path './RustDataDump.cs' -Destination "$server/oxide/plugins" -Recurse -Force

Start-Process -FilePath $server_bin -Wait

$dumps = Get-ChildItem "$server/oxide/logs/RustDataDump"

if ($dumps.Length -lt 1) {
    Write-Error 'Dump was not successfull! Try again later'
    exit 1
}

$latest = $dumps | Sort-Object LastWriteTime

$content = Get-Content $latest -Raw

$hashfunc = [System.Security.Cryptography.MD5]::Create()

$dump_hash = $hashfunc.ComputeHash([System.Text.Encoding]::UTF8.GetBytes($content))

$out_object = @{
    hash = $dump_hash
    data = ConvertFrom-Json $content -AsHashtable
}

ConvertTo-Json $out_object | Out-File -FilePath "$out/$($lastdump.Name)" -Force

