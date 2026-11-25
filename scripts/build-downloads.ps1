<#
.SYNOPSIS
    Packages sanitized workstation configuration bundles from V:\system-config and V:\projects\obelisk
    into public/downloads/ with SHA-256 manifest and secret-leak verification.
#>
[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

$siteRoot = Split-Path $PSScriptRoot -Parent
$outDir = Join-Path $siteRoot 'public\downloads'
$stagingRoot = Join-Path $env:TEMP ("hola-setup-stage-" + [guid]::NewGuid().ToString('N').Substring(0, 8))

$sysConfig = 'V:\system-config'
$obeliskRoot = 'V:\projects\obelisk'
$ahkTools = 'V:\tools\auto-hotkey'

if (-not (Test-Path $sysConfig)) { throw "Missing V:\system-config" }
if (-not (Test-Path $obeliskRoot)) { throw "Missing V:\projects\obelisk" }

if (Test-Path $outDir) { Remove-Item -LiteralPath $outDir -Recurse -Force }
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
New-Item -ItemType Directory -Path $stagingRoot -Force | Out-Null

function Copy-IntoStage($src, $stageDir, $relTarget) {
  if (-not (Test-Path $src)) { throw "Source path not found: $src" }
  $dest = Join-Path $stageDir $relTarget
  $parent = Split-Path $dest -Parent
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Path $parent -Force | Out-Null }
  Copy-Item -Path $src -Destination $dest -Recurse -Force
}

function Build-BundleZip($id, $title, $category, $targetPath, $summary, $zipName, $stageDir, $includedFiles) {
  $zipPath = Join-Path $outDir $zipName
  if (Test-Path $zipPath) { Remove-Item -LiteralPath $zipPath -Force }
  Compress-Archive -Path (Join-Path $stageDir '*') -DestinationPath $zipPath -CompressionLevel Optimal -Force
  $hash = (Get-FileHash -LiteralPath $zipPath -Algorithm SHA256).Hash.ToLowerInvariant()
  $sizeBytes = (Get-Item -LiteralPath $zipPath).Length
  [PSCustomObject]@{
    id          = $id
    title       = $title
    category    = $category
    targetPath  = $targetPath
    summary     = $summary
    fileName    = $zipName
    href        = "/downloads/$zipName"
    sizeBytes   = $sizeBytes
    sha256      = $hash
    files       = $includedFiles
  }
}

try {
  $bundles = @()

  # 1. Antigravity (anti) sanitized setup
  $sAnti = Join-Path $stagingRoot 'anti-setup'
  Copy-IntoStage "$sysConfig\configs\antigravity\GEMINI.md" $sAnti 'GEMINI.md'
  Copy-IntoStage "$sysConfig\configs\antigravity\config_GEMINI.md" $sAnti 'config\GEMINI.md'
  Copy-IntoStage "$sysConfig\configs\antigravity\config.json" $sAnti 'config\config.json'
  Copy-IntoStage "$sysConfig\configs\antigravity\mcp_config.template.json" $sAnti 'config\mcp_config.template.json'
  Copy-IntoStage "$sysConfig\configs\antigravity\rules_templates" $sAnti 'config\rules_templates'
  Copy-IntoStage "$sysConfig\configs\antigravity\skills" $sAnti 'config\skills'
  Copy-IntoStage "$sysConfig\configs\antigravity\plugins" $sAnti 'config\plugins'
  Copy-IntoStage "$sysConfig\configs\antigravity\scripts" $sAnti 'config\scripts'
  $bundles += Build-BundleZip `
    -id 'anti-setup' `
    -title 'Antigravity Setup (anti)' `
    -category 'AI Agent Runtime' `
    -targetPath '%USERPROFILE%\.gemini\' `
    -summary 'Global GEMINI.md, sanitized mcp_config.template.json, plugins, skills, and rules templates.' `
    -zipName 'anti-setup.zip' `
    -stageDir $sAnti `
    -includedFiles @('GEMINI.md', 'config/config.json', 'config/mcp_config.template.json', 'config/plugins/', 'config/rules_templates/', 'config/skills/')

  # 2. GlazeWM + Zebar
  $sGlaze = Join-Path $stagingRoot 'glazewm-zebar'
  Copy-IntoStage "$sysConfig\configs\glazewm\config.yaml" $sGlaze 'glazewm\config.yaml'
  Copy-IntoStage "$sysConfig\configs\glazewm\zebar\settings.json" $sGlaze 'zebar\settings.json'
  $bundles += Build-BundleZip `
    -id 'glazewm-zebar' `
    -title 'GlazeWM & Zebar Config' `
    -category 'Tiling Window Manager' `
    -targetPath '%USERPROFILE%\.glzr\' `
    -summary 'Declarative GlazeWM tiling keybindings, workspace rules, and Zebar topbar settings.' `
    -zipName 'glazewm-zebar.zip' `
    -stageDir $sGlaze `
    -includedFiles @('glazewm/config.yaml', 'zebar/settings.json')

  # 3. VS Code
  $sVscode = Join-Path $stagingRoot 'vscode-config'
  Copy-IntoStage "$sysConfig\configs\vscode\settings.json" $sVscode 'settings.json'
  Copy-IntoStage "$sysConfig\configs\vscode\keybindings.json" $sVscode 'keybindings.json'
  $bundles += Build-BundleZip `
    -id 'vscode-config' `
    -title 'VS Code Configuration' `
    -category 'Editor' `
    -targetPath '%APPDATA%\Code\User\' `
    -summary 'Curated editor typography, clean UI settings, and custom keyboard bindings.' `
    -zipName 'vscode-config.zip' `
    -stageDir $sVscode `
    -includedFiles @('settings.json', 'keybindings.json')

  # 4. Hola Theme (Obelisk)
  $sTheme = Join-Path $stagingRoot 'hola-theme'
  Copy-IntoStage "$obeliskRoot\theme.css" $sTheme 'obsidian-obelisk\theme.css'
  Copy-IntoStage "$obeliskRoot\manifest.json" $sTheme 'obsidian-obelisk\manifest.json'
  Copy-IntoStage "$obeliskRoot\README.md" $sTheme 'obsidian-obelisk\README.md'
  Copy-IntoStage "$obeliskRoot\edge-theme" $sTheme 'edge-theme'
  $bundles += Build-BundleZip `
    -id 'hola-theme' `
    -title 'Hola Theme (Obelisk)' `
    -category 'Themes' `
    -targetPath '<vault>\.obsidian\themes\Obelisk\' `
    -summary 'Obelisk muted jewel Obsidian theme plus Edge browser extension theme package.' `
    -zipName 'hola-theme.zip' `
    -stageDir $sTheme `
    -includedFiles @('obsidian-obelisk/theme.css', 'obsidian-obelisk/manifest.json', 'edge-theme/')

  # 5. PowerShell & Oh My Posh
  $sPwsh = Join-Path $stagingRoot 'pwsh-config'
  Copy-IntoStage "$sysConfig\configs\powershell\Microsoft.PowerShell_profile.ps1" $sPwsh 'Microsoft.PowerShell_profile.ps1'
  Copy-IntoStage "$sysConfig\configs\powershell\amro.omp.json" $sPwsh 'amro.omp.json'
  $bundles += Build-BundleZip `
    -id 'pwsh-config' `
    -title 'PowerShell 7 & Prompt' `
    -category 'Shell' `
    -targetPath '%USERPROFILE%\Documents\PowerShell\' `
    -summary 'PowerShell 7 profile, navigation aliases, and Oh My Posh amro.omp.json theme.' `
    -zipName 'pwsh-config.zip' `
    -stageDir $sPwsh `
    -includedFiles @('Microsoft.PowerShell_profile.ps1', 'amro.omp.json')

  # 6. AutoHotkey (hola-dev.ahk + hola-dev.exe + MouseDebounce.ahk)
  $sAhk = Join-Path $stagingRoot 'autohotkey'
  Copy-IntoStage "$sysConfig\configs\autohotkey\hola-dev.ahk" $sAhk 'hola-dev.ahk'
  Copy-IntoStage "$sysConfig\configs\autohotkey\MouseDebounce.ahk" $sAhk 'MouseDebounce.ahk'
  Copy-IntoStage "$sysConfig\scheduled-tasks\Workstation-AHK-Startup.xml" $sAhk 'Workstation-AHK-Startup.xml'
  if (Test-Path "$ahkTools\hola-dev.exe") {
    Copy-IntoStage "$ahkTools\hola-dev.exe" $sAhk 'hola-dev.exe'
  }
  # Also publish direct 1-click files for hola-dev.ahk and hola-dev.exe
  Copy-Item -LiteralPath "$sysConfig\configs\autohotkey\hola-dev.ahk" -Destination (Join-Path $outDir 'hola-dev.ahk') -Force
  $ahkDirectExe = $null
  if (Test-Path "$ahkTools\hola-dev.exe") {
    Copy-Item -LiteralPath "$ahkTools\hola-dev.exe" -Destination (Join-Path $outDir 'hola-dev.exe') -Force
    $ahkDirectExe = [PSCustomObject]@{
      fileName  = 'hola-dev.exe'
      href      = '/downloads/hola-dev.exe'
      sizeBytes = (Get-Item (Join-Path $outDir 'hola-dev.exe')).Length
      sha256    = (Get-FileHash (Join-Path $outDir 'hola-dev.exe') -Algorithm SHA256).Hash.ToLowerInvariant()
    }
  }
  $ahkDirectScript = [PSCustomObject]@{
    fileName  = 'hola-dev.ahk'
    href      = '/downloads/hola-dev.ahk'
    sizeBytes = (Get-Item (Join-Path $outDir 'hola-dev.ahk')).Length
    sha256    = (Get-FileHash (Join-Path $outDir 'hola-dev.ahk') -Algorithm SHA256).Hash.ToLowerInvariant()
  }

  $bundles += Build-BundleZip `
    -id 'autohotkey' `
    -title 'AutoHotkey & hola-dev.exe' `
    -category 'Desktop Automation' `
    -targetPath 'V:\tools\auto-hotkey\' `
    -summary 'hola-dev.ahk source script, MouseDebounce.ahk, Startup XML, and compiled hola-dev.exe.' `
    -zipName 'autohotkey.zip' `
    -stageDir $sAhk `
    -includedFiles @('hola-dev.ahk', 'hola-dev.exe', 'MouseDebounce.ahk', 'Workstation-AHK-Startup.xml')

  # 7. Secret-leak scan across ALL staged text files before building all-in-one archive
  $secretPattern = '\bghp_[A-Za-z0-9]{20,}|\bgho_[A-Za-z0-9]{20,}|\bre_[A-Za-z0-9]{24,}\b|mongodb\+srv://[^\s"<]+|\bAIza[0-9A-Za-z\-_]{30,}'
  $hits = Get-ChildItem -Path $stagingRoot -Recurse -File |
    Where-Object { $_.Extension -notin @('.exe','.pak','.png','.jpg','.svg','.ico') } |
    Select-String -Pattern $secretPattern
  if ($hits) {
    $hitInfo = ($hits | ForEach-Object { "$($_.Path):$($_.LineNumber)" }) -join '; '
    throw "SECRET LEAK DETECTED in staged files: $hitInfo"
  }

  # 8. Build combined "Download Everything" archive
  $allBundleZip = Join-Path $outDir 'hola-all-bundle.zip'
  Compress-Archive -Path (Join-Path $stagingRoot '*') -DestinationPath $allBundleZip -CompressionLevel Optimal -Force
  $allBundle = [PSCustomObject]@{
    fileName  = 'hola-all-bundle.zip'
    href      = '/downloads/hola-all-bundle.zip'
    sizeBytes = (Get-Item -LiteralPath $allBundleZip).Length
    sha256    = (Get-FileHash -LiteralPath $allBundleZip -Algorithm SHA256).Hash.ToLowerInvariant()
  }

  # 9. Emit manifest.json for frontend consumption
  $manifest = [PSCustomObject]@{
    generatedAt = (Get-Date).ToString('o')
    allBundle   = $allBundle
    directFiles = @($ahkDirectScript, $ahkDirectExe) | Where-Object { $_ -ne $null }
    bundles     = $bundles
  }
  $manifestPath = Join-Path $outDir 'manifest.json'
  $manifest | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath $manifestPath -Encoding UTF8

  # Copy manifest to src/generated/manifest.json for strict compile-time typing too
  $genDir = Join-Path $siteRoot 'src\generated'
  if (-not (Test-Path $genDir)) { New-Item -ItemType Directory -Path $genDir -Force | Out-Null }
  Copy-Item -LiteralPath $manifestPath -Destination (Join-Path $genDir 'manifest.json') -Force

  Write-Output "Built $($bundles.Count) bundles + all-bundle + direct files cleanly with 0 secret leaks."
}
finally {
  if (Test-Path $stagingRoot) { Remove-Item -LiteralPath $stagingRoot -Recurse -Force -ErrorAction SilentlyContinue }
}
