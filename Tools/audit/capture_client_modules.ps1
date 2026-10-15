param([string]$Stage='Build/world-gui/stage-play-21', [string]$OutDir='Build/Logs/2026-09-24-source-audit/runtime')
$ErrorActionPreference='Stop'
$auditRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$auditStage=(Resolve-Path (Join-Path $auditRoot $Stage)).Path
$auditOut=[IO.Path]::GetFullPath((Join-Path $auditRoot $OutDir))
New-Item -ItemType Directory -Path $auditOut -Force | Out-Null
if(Get-Process Game -ErrorAction SilentlyContinue){throw 'Existing Game.exe: do not interrupt the player.'}
# Use the same cleared CYS environment as Play.cmd; no account or gameplay test.
Get-ChildItem Env:CYS_* | ForEach-Object {Remove-Item -LiteralPath ('Env:'+$_.Name)}
$auditBin=Join-Path $auditStage 'Bin64'
$auditConfig=Join-Path $auditBin 'WXSystem.cfg'
$auditOriginal=[IO.File]::ReadAllBytes($auditConfig)
$auditSnapshots=@()
$auditProcess=$null
try {
    $auditProcess=Start-Process -FilePath (Join-Path $auditBin 'Game.exe') -ArgumentList '-fl' -WorkingDirectory $auditBin -WindowStyle Hidden -PassThru
    $auditStarted=Get-Date
    for($auditStep=0;$auditStep -lt 18;$auditStep++){
        Start-Sleep -Seconds 5
        $auditProcess.Refresh()
        if($auditProcess.HasExited){break}
        $auditModules=@($auditProcess.Modules | ForEach-Object {
            [ordered]@{name=$_.ModuleName;path=$_.FileName;base_address=('0x{0:x}' -f $_.BaseAddress.ToInt64());size=$_.ModuleMemorySize}
        })
        $auditSnapshots+=,[ordered]@{elapsed=[int]((Get-Date)-$auditStarted).TotalSeconds;modules=$auditModules}
        if($auditStep -ge 11 -and ($auditModules.name -contains 'UI_CEGUI.dll') -and ($auditModules.name -contains 'RenderSystem_Direct3D9.dll')){break}
    }
    [ordered]@{pid=$auditProcess.Id;exe=(Join-Path $auditBin 'Game.exe');args='-fl';cys_environment_cleared=$true;account_login=$false;snapshots=$auditSnapshots} | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $auditOut 'modules.json') -Encoding utf8
    Write-Output ('Captured PID {0}: {1} snapshots, {2} loaded modules' -f $auditProcess.Id,$auditSnapshots.Count,$auditSnapshots[-1].modules.Count)
} finally {
    if($auditProcess -and -not $auditProcess.HasExited){
        [void]$auditProcess.CloseMainWindow()
        if(-not $auditProcess.WaitForExit(10000)){Stop-Process -Id $auditProcess.Id}
        $auditProcess.WaitForExit()
    }
    foreach($auditLog in @('WXClient.log','WXRender.log','UISystem.log')){
        if(Test-Path -LiteralPath (Join-Path $auditBin $auditLog)){Copy-Item -LiteralPath (Join-Path $auditBin $auditLog) -Destination $auditOut}
    }
    [IO.File]::WriteAllBytes($auditConfig,$auditOriginal)
}
