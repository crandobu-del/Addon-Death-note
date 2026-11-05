$ErrorActionPreference = 'Stop'
$taskRepo = Split-Path $PSScriptRoot -Parent
$taskSource = Join-Path $taskRepo 'dev/SyndicatRougeDemo'
$taskTarget = [IO.Path]::GetFullPath('D:\World of Warcraft\_forever_\Interface\AddOns\SyndicatRougeDemo')
$taskBackup = Join-Path $taskRepo ('dist/client-backups/kill-proof-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
if (-not (Test-Path -LiteralPath (Join-Path $taskTarget 'SyndicatRougeDemo.toc'))) { throw 'Compagnon existant introuvable.' }
foreach ($taskName in @('KillProofProbe.lua','SyndicatRougeDemo.toc')) {
    $taskDestination = [IO.Path]::GetFullPath((Join-Path $taskTarget $taskName))
    if (-not $taskDestination.StartsWith($taskTarget + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Chemin hors installation.' }
    if (Test-Path -LiteralPath $taskDestination) {
        New-Item -ItemType Directory -Path $taskBackup -Force | Out-Null
        Copy-Item -LiteralPath $taskDestination -Destination (Join-Path $taskBackup $taskName)
    }
    $taskFile = Join-Path $taskSource $taskName
    Copy-Item -LiteralPath $taskFile -Destination $taskDestination -Force
    if ((Get-FileHash -LiteralPath $taskFile).Hash -ne (Get-FileHash -LiteralPath $taskDestination).Hash) { throw 'Copie non conforme.' }
}
Write-Output ('Diagnostic installé et vérifié. Copie de secours : ' + $taskBackup)
