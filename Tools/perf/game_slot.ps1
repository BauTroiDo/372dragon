# CY-Source Tools/perf/game_slot.ps1 - shared Game.exe slot lock of the coordinator (15/09/2026). Dot-source it.
# Before any Game.exe (ours or CY's): wait while Build\game-slot.lock exists and is younger than 5 minutes, or while a
# Game.exe is alive; then write "<agent> <start time>". Release deletes the file (only when it is still ours).
# ASCII only (Windows PowerShell 5.1).
$script:CysSlotPath = 'C:\TLBB\085\CY-Source\Build\game-slot.lock'

function Enter-CysGameSlot([string]$Agent = 'perf-cy', [int]$WaitMinutes = 20) {
    $deadline = (Get-Date).AddMinutes($WaitMinutes)
    while ($true) {
        $busy = $false
        if (Test-Path -LiteralPath $script:CysSlotPath) {
            $age = (Get-Date) - (Get-Item -LiteralPath $script:CysSlotPath).LastWriteTime
            if ($age.TotalMinutes -lt 5) { $busy = $true }
        }
        if (@(Get-Process -Name Game -ErrorAction SilentlyContinue).Count -gt 0) { $busy = $true }
        if (-not $busy) {
            $stamp = $Agent + ' ' + (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
            [IO.File]::WriteAllText($script:CysSlotPath, $stamp)
            Start-Sleep -Milliseconds 500
            if ((Get-Content -LiteralPath $script:CysSlotPath -Raw).Trim() -eq $stamp) { return $stamp }
        }
        if ((Get-Date) -gt $deadline) { throw ('game slot still busy after ' + $WaitMinutes + ' minutes') }
        Start-Sleep -Seconds 10
    }
}

function Exit-CysGameSlot([string]$Stamp) {
    try {
        if ((Test-Path -LiteralPath $script:CysSlotPath) -and ((Get-Content -LiteralPath $script:CysSlotPath -Raw).Trim() -eq $Stamp)) {
            Remove-Item -LiteralPath $script:CysSlotPath
        }
    } catch { }
}
