param([switch]$Apply)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
$buildRoot = [IO.Path]::GetFullPath((Join-Path $projectRoot 'Build'))
$outDir = Join-Path $buildRoot 'Logs/2026-09-26-runtime-polish'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$keep = @('world-gui/stage-play-21','world-gui/stage-vothach-26','world-gui/stage-runtime-polish-26','cmake/coord-x64')
$active = @(Get-CimInstance Win32_Process | Where-Object { $_.Name -in @('Game.exe','ninja.exe','cl.exe','link.exe','MSBuild.exe') })
if ($active.Count) { throw 'A game or build process is active; cleanup refused.' }
$targets = @()
foreach ($group in @('world-gui','cmake')) {
 foreach ($dir in Get-ChildItem -LiteralPath (Join-Path $buildRoot $group) -Directory) {
  $relative = "$group/$($dir.Name)"
  if ($relative -in $keep) { continue }
  if ($group -eq 'world-gui' -and $dir.Name -notlike 'stage-*') { continue }
  if ($group -eq 'cmake' -and -not (Test-Path -LiteralPath (Join-Path $dir.FullName 'CMakeCache.txt'))) { continue }
  $path = [IO.Path]::GetFullPath($dir.FullName)
  if (-not $path.StartsWith($buildRoot+'\',[StringComparison]::OrdinalIgnoreCase) -or $path -eq $buildRoot) { throw "Outside build root: $path" }
  if (($dir.Attributes -band [IO.FileAttributes]::ReparsePoint) -or (Test-Path -LiteralPath (Join-Path $path '.git'))) { throw "Not an ordinary generated build directory: $path" }
  $stack = [Collections.Generic.Stack[IO.DirectoryInfo]]::new()
  $stack.Push([IO.DirectoryInfo]::new($path))
  $links = [Collections.Generic.List[string]]::new()
  [long]$bytes=0; [long]$files=0
  while ($stack.Count) {
   foreach ($entry in $stack.Pop().EnumerateFileSystemInfos()) {
    if ($entry.Attributes -band [IO.FileAttributes]::ReparsePoint) { $links.Add($entry.FullName); continue }
    if ($entry.Attributes -band [IO.FileAttributes]::Directory) { $stack.Push([IO.DirectoryInfo]$entry) }
    else { $bytes += ([IO.FileInfo]$entry).Length; $files++ }
   }
  }
  $targets += [pscustomobject]@{path=$path;bytes=$bytes;files=$files;links=@($links.ToArray())}
 }
}
$report = [ordered]@{at=(Get-Date -Format o);root=$buildRoot;kept=$keep;targets=$targets;bytes=($targets|Measure-Object bytes -Sum).Sum;applied=$false}
$report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $outDir 'cleanup-plan.json') -Encoding utf8
if ($Apply) {
 foreach ($target in $targets) {
  # Validate the resolved absolute directory again immediately before deletion.
  $path=(Resolve-Path -LiteralPath $target.path).ProviderPath
  if ($path -ne $target.path -or -not $path.StartsWith($buildRoot+'\',[StringComparison]::OrdinalIgnoreCase)) { throw "Target changed: $path" }
  foreach ($link in $target.links) {
   if (-not $link.StartsWith($path+'\',[StringComparison]::OrdinalIgnoreCase)) { throw 'Link outside selected build' }
   $item=Get-Item -LiteralPath $link -Force
   if (-not ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) { throw "Link changed: $link" }
   Remove-Item -LiteralPath $link -Force
  }
  Remove-Item -LiteralPath $path -Recurse -Force
  if (Test-Path -LiteralPath $path) { throw "Directory remains: $path" }
 }
 $report.applied=$true
 $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $outDir 'cleanup-result.json') -Encoding utf8
}
[pscustomobject]@{applied=$report.applied;directories=$targets.Count;GiB=[math]::Round($report.bytes/1GB,2);files=($targets|Measure-Object files -Sum).Sum}
