param (
    [string[]]$Scenarios = @()
)

if ($Scenarios.Length -lt 1) {
    Write-Warning "No scenarios passed, exiting"
    exit 0
}

[hashtable]$config = Get-Content -Path "./config.json" -Raw | ConvertFrom-Json -AsHashtable

[hashtable[]]$il2cpp_scen = $config.cpp2il_scenarios

if (!$config) {
    Write-Error "No configuration file found. Make sure it's located at $PSScriptRoot/config.json and restart the script"
    exit 1
}

if (!(Test-Path -Path $config.il2cppdumper)) {
    Write-Error "Could not locate IL2CPPDumper binary. Make sure right path is specified in the config"
    exit 1
}

if (!$il2cpp_scen -or $il2cpp_scen.Length -lt 1) {
    Write-Error "No scenarios found in the config file"
    exit 1
}

function Invoke-IL2CPPDumper {
    param (
        [string]$exe,
        [string]$meta,
        [string]$unity = "2019.2.0f1",
        [string]$mode = 3,
        [string]$out_dir = $PSScriptRoot
    )

    if (!$exe -or !$meta -or !$unity -or !$mode) {
        throw "INVALID_ARGS"
    }

    $cpp2il_bin = $config.il2cppdumper

    New-Item -Path $out_dir -ItemType Directory -ErrorAction SilentlyContinue

    $exe = Join-Path -Path $PSScriptRoot -ChildPath $exe

    $meta = Join-Path -Path $PSScriptRoot -ChildPath $meta

    $arguments = "$exe $meta $unity $mode"

    Start-Process -FilePath $cpp2il_bin -ArgumentList $arguments -WorkingDirectory $out_dir
}

foreach ($scen in $Scenarios) {
    $arg = $il2cpp_scen.$scen

    if (!$arg) {
        Write-Warning "Could not find scenario '$scen', make sure it exists if the configuration and try again!"
        continue
    }

    Write-Output "Executing '$scen'..."

    try {
        Invoke-IL2CPPDumper -exe $arg.GameAssembly -meta $arg['global-metadata'] -out_dir $arg['out-dir']

        # Write-Output "'$scen' completed successfully"
    }
    catch {
        Write-Warning "Scenario '$scen' failed to execute:"
        Write-Error $_
    }
}

Start-Sleep -Seconds 20

Get-Process Il2CppDumper -OutVariable dumpers -ErrorAction SilentlyContinue
if (!$dumpers -or $dumpers.Length -lt 1) {
    exit 0
}

$dumpers | Stop-Process
