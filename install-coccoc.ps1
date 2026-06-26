<#
Coc Coc Browser Installer v2.0
- Fetches official Browser-bin via Omaha API (no auto-update)
- Extracts: .crx -> setup.exe -> browser.7z -> Browser-bin
- Installs and creates clean shortcuts
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Require admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://go.bibica.net/coccoc | iex`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "Coc Coc Browser Installer v2.0" -BackgroundColor DarkGreen

# Check Windows version (Windows 10+ only)
$winVer = [System.Environment]::OSVersion.Version
if ($winVer.Major -lt 10) {
    Write-Host "`nError: Windows 10 or later is required." -ForegroundColor Red
    Write-Host "Current version: Windows $($winVer.Major).$($winVer.Minor)" -ForegroundColor Red
    exit 1
}

# Detect OS arch and pick install variant
if (-not [Environment]::Is64BitOperatingSystem) {
    Write-Host "`n32-bit OS detected, using x86 build." -ForegroundColor Yellow
    $useArch = "x86"
} else {
    Write-Host ""
    Write-Host "Select build:" -ForegroundColor Cyan
    Write-Host "  [1] x64 - 64-bit (default)" -ForegroundColor Green
    Write-Host "  [2] x86 - 32-bit"
    $choice = (Read-Host "Enter choice (or press Enter for default)").Trim()
    $useArch = if ($choice -eq "2") { "x86" } else { "x64" }
}

Write-Host "`nPreparing $useArch build..." -ForegroundColor Cyan

# Check latest version via Omaha API
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$omahaUrl     = "https://update.coccoc.com/service/update2/json"
$omahaHeaders = @{
    "User-Agent" = "CocCocUpdater/148.0.7778.254"
    "Accept"     = "application/json"
}
$bodyX64 = '{"request":{"@os":"win","@updater":"CocCocUpdater","acceptformat":"crx3,download","protocol":"4.0","os":{"arch":"x86_64","platform":"Windows","version":"10.0"},"updaterversion":"148.0.7778.254","apps":[{"appid":"{C0CC0CBB-47DD-46FF-A04D-7011A06486E1}","version":"0.0.0.0","ap":"arch_x64","updatecheck":{}}]}}'
$bodyX86  = '{"request":{"@os":"win","@updater":"CocCocUpdater","acceptformat":"crx3,download","protocol":"4.0","os":{"arch":"x86","platform":"Windows","version":"10.0"},"updaterversion":"148.0.7778.254","apps":[{"appid":"{C0CC0CBB-47DD-46FF-A04D-7011A06486E1}","version":"0.0.0.0","updatecheck":{}}]}}'
$omahaBody = if ($useArch -eq "x64") { $bodyX64 } else { $bodyX86 }

Write-Host "Checking latest version..." -ForegroundColor Cyan
try {
    $resp = Invoke-WebRequest -Uri $omahaUrl -Method POST -Body $omahaBody `
        -ContentType "application/json" -Headers $omahaHeaders -UseBasicParsing
    $raw = $resp.Content
    if ($raw.StartsWith(")]}'")) { $raw = $raw.Substring(4) }
    $updateCheck = ($raw | ConvertFrom-Json).response.apps[0].updatecheck

    if ($updateCheck.status -ne "ok") {
        Write-Host "Error: Server returned status '$($updateCheck.status)'" -ForegroundColor Red; exit 1
    }
    $version = $updateCheck.nextversion
    $crxUrl  = $updateCheck.pipelines[0].operations[0].urls[0].url
} catch {
    Write-Host "Error: Failed to contact update server. $($_.Exception.Message)" -ForegroundColor Red; exit 1
}

Write-Host "Version : $version" -ForegroundColor Green
Write-Host "URL     : $crxUrl"

# Create temp folder
$tempRoot = Join-Path $env:TEMP ("coccoc_" + [System.IO.Path]::GetRandomFileName().Replace(".", ""))
New-Item -ItemType Directory -Path $tempRoot -Force | Out-Null

# Download .crx
$crxFile = Join-Path $tempRoot "coccoc.crx"
Write-Host "`nDownloading ($useArch)..." -ForegroundColor Cyan
try {
    $wc = New-Object System.Net.WebClient
    $wc.DownloadFile($crxUrl, $crxFile)
    $wc.Dispose()
} catch {
    Write-Host "Error: Download failed. $($_.Exception.Message)" -ForegroundColor Red; exit 1
}

# Check if 7-Zip is installed, install if missing
$7zExe = "${env:ProgramFiles}\7-Zip\7z.exe"
if (-not (Test-Path $7zExe)) { $7zExe = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }

if (-not (Test-Path $7zExe)) {
    $7zipInstaller = Join-Path $tempRoot "7z-setup.exe"
    $7zipUrl = if ([Environment]::Is64BitOperatingSystem) { "https://www.7-zip.org/a/7z2409-x64.exe" } else { "https://www.7-zip.org/a/7z2409.exe" }
    Write-Host "Downloading 7-Zip..." -ForegroundColor Cyan
    try {
        $wc2 = New-Object System.Net.WebClient
        $wc2.DownloadFile($7zipUrl, $7zipInstaller)
        $wc2.Dispose()
    } catch {
        Write-Host "Error: Failed to download 7-Zip. $($_.Exception.Message)" -ForegroundColor Red; exit 1
    }
    Write-Host "Installing 7-Zip..." -ForegroundColor Cyan
    Start-Process -FilePath $7zipInstaller -ArgumentList "/S" -Wait
    $7zExe = "${env:ProgramFiles}\7-Zip\7z.exe"
    if (-not (Test-Path $7zExe)) { $7zExe = "${env:ProgramFiles(x86)}\7-Zip\7z.exe" }
    if (-not (Test-Path $7zExe)) {
        Write-Host "Error: 7z.exe not found after install." -ForegroundColor Red; exit 1
    }
} else {
    Write-Host "7-Zip found: $7zExe" -ForegroundColor DarkGray
}

# Extract .crx
Write-Host "Extracting .crx..." -ForegroundColor Cyan
$crxDir = Join-Path $tempRoot "crx"
New-Item -ItemType Directory -Path $crxDir -Force | Out-Null
& $7zExe x "$crxFile" -o"$crxDir" -y 2>&1 | Out-Null
if ($LASTEXITCODE -gt 1) {
    Write-Host "Error: Failed to extract .crx (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1
}

$setupExe = Get-ChildItem $crxDir -Filter "*coccocsetup.exe" -Recurse | Select-Object -First 1
if (-not $setupExe) {
    Write-Host "Error: *coccocsetup.exe not found in .crx" -ForegroundColor Red; exit 1
}
Write-Host "Found: $($setupExe.Name)" -ForegroundColor DarkGray

# Extract setup.exe -> browser.7z
Write-Host "Extracting setup.exe..." -ForegroundColor Cyan
$setupDir = Join-Path $tempRoot "setup"
New-Item -ItemType Directory -Path $setupDir -Force | Out-Null
& $7zExe x "$($setupExe.FullName)" -o"$setupDir" -y 2>&1 | Out-Null
if ($LASTEXITCODE -gt 1) {
    Write-Host "Error: Failed to extract setup.exe (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1
}

$browser7z = Get-ChildItem $setupDir -Filter "browser.7z" -Recurse | Select-Object -First 1
if (-not $browser7z) {
    Write-Host "Error: browser.7z not found after extracting setup.exe" -ForegroundColor Red; exit 1
}

# Extract browser.7z -> Browser-bin
Write-Host "Extracting browser.7z (this may take a while)..." -ForegroundColor Cyan
$binDir = Join-Path $tempRoot "bin"
New-Item -ItemType Directory -Path $binDir -Force | Out-Null
& $7zExe x "$($browser7z.FullName)" -o"$binDir" -y 2>&1 | Out-Null
if ($LASTEXITCODE -gt 1) {
    Write-Host "Error: Failed to extract browser.7z (exit $LASTEXITCODE)" -ForegroundColor Red; exit 1
}

$browserBinSrc = Get-ChildItem $binDir -Directory -Filter "Browser-bin" | Select-Object -First 1
if (-not $browserBinSrc) { $browserBinSrc = Get-Item $binDir }

# Kill running Coc Coc processes
Write-Host "`nStopping Coc Coc processes..." -ForegroundColor Cyan
@("browser", "CocCocUpdate", "CocCocCrashHandler") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 800

# Remove old installation (both paths to handle x64<->x86 migration)
Write-Host "Removing old installation..." -ForegroundColor Cyan
@("${env:ProgramFiles}\CocCoc", "${env:ProgramFiles(x86)}\CocCoc") | ForEach-Object {
    if (Test-Path $_) {
        takeown /F $_ /R /A /D Y 2>&1 | Out-Null
        icacls $_ /grant:r "Administrators:F" /T /C 2>&1 | Out-Null
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove leftover scheduled tasks from old installer
Get-ScheduledTask -TaskName "CocCoc*" -ErrorAction SilentlyContinue |
    Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# Copy Browser-bin to install directory
$installBase = if ($useArch -eq "x64") { $env:ProgramFiles } else { ${env:ProgramFiles(x86)} }
$installDir  = Join-Path $installBase "CocCoc\Browser"
Write-Host "Installing to $installDir..." -ForegroundColor Cyan
New-Item -ItemType Directory -Path $installDir -Force | Out-Null

robocopy $browserBinSrc.FullName $installDir /E /NFL /NDL /NJH /NJS /NC /NS | Out-Null
if ($LASTEXITCODE -ge 8) {
    Write-Host "Warning: robocopy exit $LASTEXITCODE, check install directory." -ForegroundColor Yellow
}

# Apply registry tweaks
Write-Host "Applying registry tweaks..." -ForegroundColor Cyan
try {
    $regFile = Join-Path $tempRoot "debloat.reg"
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/coccoc-debloat.reg" `
        -OutFile $regFile -UseBasicParsing -TimeoutSec 15
    Start-Process "regedit.exe" -ArgumentList "/s `"$regFile`"" -Wait -NoNewWindow
} catch {
    Write-Host "Skipped registry tweaks: $($_.Exception.Message)" -ForegroundColor DarkGray
}

# Find browser.exe and create shortcuts
$browserExe = Get-ChildItem $installDir -Filter "browser.exe" -Recurse -ErrorAction SilentlyContinue |
    Select-Object -First 1

if ($browserExe) {
    $browserPath = $browserExe.FullName
    Write-Host "Creating shortcuts..." -ForegroundColor Cyan

    # Remove old shortcuts
    @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("CommonDesktopDirectory"),
        [Environment]::GetFolderPath("Programs"),
        [Environment]::GetFolderPath("CommonPrograms")
    ) | Sort-Object -Unique | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem "$_\Cốc Cốc.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }

    # Create new shortcuts
    @([Environment]::GetFolderPath("Desktop"), [Environment]::GetFolderPath("CommonPrograms")) | ForEach-Object {
        if (-not (Test-Path $_)) { return }
        $shell    = New-Object -ComObject WScript.Shell
        $tempLnk  = Join-Path $_ "temp_coccoc.lnk"
        $finalLnk = Join-Path $_ "Cốc Cốc.lnk"

        $lnk = $shell.CreateShortcut($tempLnk)
        $lnk.TargetPath   = $browserPath
        $lnk.Arguments    = "--no-first-run --no-default-browser-check --disable-features=OutdatedBuildDetector,CocCocAskAi,ExtensionManifestV2Unsupported,ExtensionManifestV2Disabled --profile-directory=Default"
        $lnk.IconLocation = "$browserPath,0"
        $lnk.Save()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($shell) | Out-Null

        if (Test-Path $tempLnk) {
            Rename-Item $tempLnk $finalLnk -Force -ErrorAction SilentlyContinue
        }
        Remove-Item $tempLnk -ErrorAction SilentlyContinue
    }
} else {
    Write-Host "Warning: browser.exe not found in $installDir" -ForegroundColor Yellow
}

# Cleanup temp folder
Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue

# Restart Explorer to apply icon/shortcut changes
Write-Host "`nRestarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host "`nCốc Cốc installation completed!" -BackgroundColor DarkGreen

Write-Host "`nNOTICE: To update Cốc Cốc when needed, please:" -ForegroundColor Cyan -BackgroundColor DarkGreen
Write-Host "1. Open PowerShell with Administrator privileges" -ForegroundColor White
Write-Host "2. Run the following command: irm https://go.bibica.net/coccoc | iex" -ForegroundColor Yellow
Write-Host "3. Wait for the installation process to complete" -ForegroundColor White
