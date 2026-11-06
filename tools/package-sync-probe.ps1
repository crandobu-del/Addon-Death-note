param([switch]$Release, [switch]$WithDemo)
$ErrorActionPreference = 'Stop'
$probeRepo = Split-Path $PSScriptRoot -Parent
$probeSource = (Resolve-Path -LiteralPath (Join-Path $probeRepo 'addon/SyndicatRouge')).Path
$probeVersion = ((Get-Content -LiteralPath (Join-Path $probeSource 'SyndicatRouge.toc') | Where-Object { $_.StartsWith('## Version: ') }) -replace '^## Version: ', '')
if ($probeVersion -notmatch '^\d+\.\d+\.\d+-dev$') { throw 'Version TOC invalide.' }
$probeSuffix = '-sonde-v4'
if ($Release) { $probeSuffix = '' }
if ($WithDemo) { $probeSuffix += '-avec-demo' }
$probeOutput = Join-Path $probeRepo ('dist/SyndicatRouge-forever-' + $probeVersion + $probeSuffix + '.zip')
if (Test-Path -LiteralPath $probeOutput) { throw 'Archive existante : ne pas remplacer une livraison.' }
foreach ($probeLine in Get-Content -LiteralPath (Join-Path $probeSource 'SyndicatRouge.toc')) {
    if ($probeLine -and -not $probeLine.StartsWith('#') -and -not (Test-Path -LiteralPath (Join-Path $probeSource $probeLine))) { throw "Fichier TOC manquant : $probeLine" }
}
$probeEntries = @{}
$probeFolders = @($probeSource)
if ($WithDemo) { $probeFolders += (Resolve-Path -LiteralPath (Join-Path $probeRepo 'dev/SyndicatRougeDemo')).Path }
foreach ($probeFolder in $probeFolders) {
foreach ($probeLine in Get-Content -LiteralPath (Join-Path $probeFolder ((Split-Path $probeFolder -Leaf) + '.toc'))) {
    if ($probeLine -and -not $probeLine.StartsWith('#') -and -not (Test-Path -LiteralPath (Join-Path $probeFolder $probeLine))) { throw "Fichier compagnon manquant : $probeLine" }
}
foreach ($probeFile in Get-ChildItem -LiteralPath $probeFolder -File -Recurse) {
    if ($probeFile.Name -in @('.gitkeep', 'IllustrativeMap.tga', 'Portraits.tga')) { continue }
    if ($probeFile.Extension -notin @('.lua', '.toc', '.ttf', '.tga', '.txt')) { throw 'Type de fichier inattendu.' }
    $probeRelative = $probeFile.FullName.Substring($probeFolder.Length).TrimStart('\','/').Replace('\','/')
    $probeEntries[(Split-Path $probeFolder -Leaf) + '/' + $probeRelative] = $probeFile.FullName
}
}
$probeEntries['SyndicatRouge/LICENSE.txt'] = Join-Path $probeRepo 'LICENSE'
Add-Type -AssemblyName System.IO.Compression.FileSystem
$probeZip = [IO.Compression.ZipFile]::Open($probeOutput, [IO.Compression.ZipArchiveMode]::Create)
try {
    foreach ($probeName in $probeEntries.Keys | Sort-Object) {
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($probeZip, $probeEntries[$probeName], $probeName, [IO.Compression.CompressionLevel]::Optimal) | Out-Null
    }
} finally { $probeZip.Dispose() }
$probeZip = [IO.Compression.ZipFile]::OpenRead($probeOutput)
try {
    if ($probeZip.Entries.Count -ne $probeEntries.Count) { throw 'Nombre de fichiers incorrect.' }
    foreach ($probeEntry in $probeZip.Entries) {
        if (-not $probeEntries.ContainsKey($probeEntry.FullName)) { throw 'Fichier inattendu dans le ZIP.' }
        $probeStream = $probeEntry.Open()
        $probeHash = [Security.Cryptography.SHA256]::Create()
        try { $probeActual = [BitConverter]::ToString($probeHash.ComputeHash($probeStream)).Replace('-', '') }
        finally { $probeStream.Dispose(); $probeHash.Dispose() }
        if ($probeActual -ne (Get-FileHash -LiteralPath $probeEntries[$probeEntry.FullName] -Algorithm SHA256).Hash) { throw 'Contenu du ZIP non conforme.' }
    }
} finally { $probeZip.Dispose() }
Write-Output ('Archive vérifiée : ' + $probeOutput)
Get-FileHash -LiteralPath $probeOutput -Algorithm SHA256
