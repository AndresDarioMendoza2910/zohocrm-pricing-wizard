# Post-pack fix: zet pack v1.0.28 deliberately omits plugin-manifest.json
# from CRM extension zips (lib/commands/package.js line 30). Sigma's CRM
# uploader rejects the zip with "does not include a valid json file"
# without it. This script injects the manifest into the existing
# dist/extension.zip.
#
# Usage (from extension/ folder):
#     zet pack
#     powershell -ExecutionPolicy Bypass -File .\fix-zip.ps1
#
# Then upload dist/extension.zip to https://sigma.zoho.com.

[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression")            | Out-Null
[System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null

$root     = $PSScriptRoot
$zipPath  = Join-Path $root "dist\extension.zip"
$manifest = Join-Path $root "plugin-manifest.json"

if (-not (Test-Path $zipPath))  { Write-Error "Run 'zet pack' first - $zipPath not found"; exit 1 }
if (-not (Test-Path $manifest)) { Write-Error "plugin-manifest.json not found at project root"; exit 1 }

$mode = [System.IO.Compression.ZipArchiveMode]::Update
$zip  = [System.IO.Compression.ZipFile]::Open($zipPath, $mode)
$old  = $zip.GetEntry("plugin-manifest.json")
if ($old) { $old.Delete() }
[System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zip, $manifest, "plugin-manifest.json") | Out-Null
$zip.Dispose()

Write-Host "[fix-zip] Injected plugin-manifest.json into dist\extension.zip"
