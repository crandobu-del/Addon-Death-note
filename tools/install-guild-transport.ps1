$ErrorActionPreference = 'Stop'
$taskRepo = Split-Path $PSScriptRoot -Parent
$taskSource = (Resolve-Path -LiteralPath (Join-Path $taskRepo 'addon/SyndicatRouge')).Path
$taskTarget = [IO.Path]::GetFullPath('D:\World of Warcraft\_forever_\Interface\AddOns\SyndicatRouge')
$taskBackup = Join-Path $taskRepo ('dist/client-backups/guild-transport-' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
if (-not (Test-Path -LiteralPath (Join-Path $taskTarget 'SyndicatRouge.toc'))) { throw 'Installation existante introuvable.' }
$taskFiles = @(Get-ChildItem -LiteralPath $taskSource -File -Recurse | Where-Object { $_.Name -notin @('.gitkeep', 'Portraits.tga', 'IllustrativeMap.tga') })
foreach ($taskFile in $taskFiles) {
    $taskRelative = $taskFile.FullName.Substring($taskSource.Length).TrimStart('\','/')
    $taskDestination = [IO.Path]::GetFullPath((Join-Path $taskTarget $taskRelative))
    if (-not $taskDestination.StartsWith($taskTarget + '\', [StringComparison]::OrdinalIgnoreCase)) { throw 'Chemin hors installation.' }
    if (Test-Path -LiteralPath $taskDestination) {
        $taskOriginal = Join-Path $taskBackup $taskRelative
        New-Item -ItemType Directory -Path (Split-Path $taskOriginal -Parent) -Force | Out-Null
        Copy-Item -LiteralPath $taskDestination -Destination $taskOriginal
    }
    New-Item -ItemType Directory -Path (Split-Path $taskDestination -Parent) -Force | Out-Null
    Copy-Item -LiteralPath $taskFile.FullName -Destination $taskDestination -Force
    if ((Get-FileHash -LiteralPath $taskFile.FullName).Hash -ne (Get-FileHash -LiteralPath $taskDestination).Hash) { throw 'Copie non conforme.' }
}
Write-Output ('Installation vérifiée : ' + $taskFiles.Count + ' fichiers. Sauvegarde : ' + $taskBackup)
