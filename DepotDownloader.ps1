param (
    [string[]]$Scenarios = @()
)

if ($Scenarios.Length -lt 1) {
    Write-Warning 'No scenarios passed, exiting'
    exit 0
}

[hashtable]$config = Get-Content -Path './config.json' -Raw | ConvertFrom-Json -AsHashtable

[hashtable[]]$depot_scen = $config.depot_scenarios

if (!$config) {
    Write-Error "No configuration file found. Make sure it's located at $PSScriptRoot/config.json and restart the script"
    exit 1
}

if (!(Test-Path -Path $config.depotdownloader)) {
    Write-Error 'Could not locate DepotDownloader binary. Make sure right path is specified in the config'
    exit 1
}

if (!$depot_scen -or $depot_scen.Length -lt 1) {
    Write-Error 'No scenarios found in the config file'
    exit 1
}

function Invoke-DepotDownloader {
    param (
        [int]$app_id,
        [int]$depot_id,
        [int]$manifest_id,
        [string]$filelist,
        [string[]]$login,
        [string]$out_dir
    )

    if (!$app_id) {
        throw 'APP_ID_UNDEFINED'
    }

    $depot_bin = $config.depotdownloader

    $arguments = "$depot_bin -app $app_id"

    if ($depot_id) {
        $arguments += " -depot $depot_id"
    }

    if ($manifest_id) {
        $arguments += " -manifest $manifest_id"
    }

    if ($filelist) {
        $arguments += " -filelist $filelist"
    }

    if ($login -and $login[0] -ne 'anonymous') {
        $arguments += " -username $($login[0]) -password $($login[1])"
    }

    if ($out_dir) {
        $arguments += " -dir $out_dir"
    }

    Start-Process -FilePath 'dotnet' -ArgumentList $arguments -NoNewWindow -Wait
}

foreach ($scenario in $Scenarios) {
    $arg = $depot_scen.$scenario

    if (!$arg) {
        Write-Warning "Could not find scenario '$scenario', make sure it exists if the configuration and try again!"
        continue
    }

    Write-Output "Executing '$scenario'..."

    try {
        Invoke-DepotDownloader -app_id $arg.app_id -depot_id $arg.depot_id -manifest_id $arg.manifest_id `
            -filelist $arg.files -login $arg.login -out_dir $arg.out_dir

        Write-Output "'$scenario' completed successfully"
    }
    catch {
        Write-Warning "Scenario '$scenario' failed to execute:"
        Write-Error $_
    }
}


