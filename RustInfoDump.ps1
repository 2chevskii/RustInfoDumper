param (
    [string]$Server,
    [string]$Out,
    [switch]$KeepServer
)

## Remove server folder, install server, get filenames, compute their hash, download oxide,get files, compute it's hash, install it, launch server and make dump, compute its hash, delete server if !KeepServer

$config = Get-Content './config.json' -Raw | ConvertFrom-Json -AsHashtable
$oxide_link = if ($IsWindows) { 'https://umod.org/games/rust/download' } else { 'https://umod.org/games/rust/download/develop' }

if (!$Server) {
    $Server = $config.rustinfodump.'server-dir'
}

if (!$Out) {
    $Out = $config.rustinfodump.'out-dir'
}

$__child_path = if ($IsWindows) { 'RustDedicated.exe' } else { 'RustDedicated' } # fuck PS does not have an actual ternary operator before v7
$server_bin = Join-Path -Path $Server -ChildPath $__child_path
$oxide_bin = Join-Path -Path $Server -ChildPath 'RustDedicated_Data/Managed/Oxide.Core.dll'
$plugin_path = "./RustDataDump.cs"

if (!(Test-Path -Path $server_bin)) {
    Write-Error 'Could not find RustDedicated executable! Verify configuration and try again'
    exit 1
}

if (!(Test-Path -Path $oxide_bin)) {
    Write-Error 'Could not find Oxide! Make sure it is installed and try again'
    exit 1    
}

if (!(Test-Path -Path $plugin_path)) {
    Write-Error 'Could not find plugin! Make sure repository is up to date!'
    exit 1
}

# Make sure out directory exists
New-Item -Path $Out -ItemType Directory -ErrorAction SilentlyContinue
New-Item -Path "$Server/oxide/plugins" -ItemType Directory -ErrorAction SilentlyContinue

## Copy plugin into server dir
Copy-Item -Path './RustDataDump.cs' -Destination "$Server/oxide/plugins" -Recurse -Force

Write-Host 'Starting server...' -ForegroundColor Yellow

Start-Process -FilePath 'cmd.exe' -ArgumentList "/C `"RustDedicated.exe -batchmode -nographics +server.worldsize 1000 +nav.wait false`"" -WorkingDirectory $Server -NoNewWindow -Wait

Write-Host 'Dumping the contents...' -ForegroundColor Yellow

$dumps = Get-ChildItem "$Server/oxide/logs/RustDataDump"

if ($dumps.Length -lt 1) {
    Write-Error 'Dump was not successfull! Try again later'
    exit 1
}

$latest = $dumps | Sort-Object LastWriteTime | Select-Object -First 1

$content = Get-Content -Path $latest.FullName -Raw

$hashfunc = [System.Security.Cryptography.MD5]::Create()

$hash_string = ''

$dump_hash = $hashfunc.ComputeHash([System.Text.Encoding]::Unicode.GetBytes($content))

foreach ($byte in $dump_hash) {
    $hash_string += $byte.ToString("x2")
}

$out_object = @{
    hash = $hash_string
    data = ConvertFrom-Json -InputObject $content -AsHashtable
}

ConvertTo-Json $out_object -Depth 10 -Compress | Out-File -FilePath "$Out/dump_$([System.DateTime]::Now.ToString("dd-MM-yyy")).json" -Force
