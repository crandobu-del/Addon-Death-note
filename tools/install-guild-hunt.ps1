$ErrorActionPreference='Stop'
& (Join-Path $PSScriptRoot 'install-guild-transport.ps1')
$huntRepo=Split-Path $PSScriptRoot -Parent
$huntDemoSource=(Resolve-Path -LiteralPath (Join-Path $huntRepo 'dev/SyndicatRougeDemo')).Path
$huntDemoTarget=[IO.Path]::GetFullPath('D:\World of Warcraft\_forever_\Interface\AddOns\SyndicatRougeDemo')
if (Test-Path -LiteralPath (Join-Path $huntDemoTarget 'SyndicatRougeDemo.toc')) {
    $huntBackup=Join-Path $huntRepo ('dist/client-backups/guild-hunt-demo-'+(Get-Date -Format 'yyyyMMdd-HHmmss'))
    foreach($huntFile in Get-ChildItem -LiteralPath $huntDemoSource -File) {
        if($huntFile.Extension -notin @('.lua','.toc')) { continue }
        $huntDestination=[IO.Path]::GetFullPath((Join-Path $huntDemoTarget $huntFile.Name))
        if(-not $huntDestination.StartsWith($huntDemoTarget+'\',[StringComparison]::OrdinalIgnoreCase)){throw 'Chemin hors compagnon.'}
        if(Test-Path -LiteralPath $huntDestination){
            New-Item -ItemType Directory -Path $huntBackup -Force | Out-Null
            Copy-Item -LiteralPath $huntDestination -Destination (Join-Path $huntBackup $huntFile.Name)
        }
        Copy-Item -LiteralPath $huntFile.FullName -Destination $huntDestination -Force
        if((Get-FileHash -LiteralPath $huntFile.FullName).Hash -ne (Get-FileHash -LiteralPath $huntDestination).Hash){throw 'Copie compagnon non conforme.'}
    }
    Write-Output ('Compagnon vérifié. Sauvegarde : '+$huntBackup)
}
