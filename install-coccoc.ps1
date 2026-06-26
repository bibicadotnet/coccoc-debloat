<#
Cốc Cốc Browser Installer v2.1
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
Write-Host "Cốc Cốc Browser Installer v2.1" -BackgroundColor DarkGreen

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

# Clean up Browser-bin before install
$dictDir = Get-ChildItem $browserBinSrc.FullName -Directory -Filter "Dictionaries" -Recurse | Select-Object -First 1
if ($dictDir) {
    Get-ChildItem $dictDir.FullName -File | Remove-Item -Force -ErrorAction SilentlyContinue
    Write-Host "Cleared Dictionaries." -ForegroundColor DarkGray
}

$extDir = Get-ChildItem $browserBinSrc.FullName -Directory -Filter "Extensions" -Recurse | Select-Object -First 1
if ($extDir) {
    $filesToKeep = @(
        "jdfkmiabjpfjacifcmihfdjhpnjpiick.json",
        "savior.crx",
        "google-search-clean.crx",
        "kfjpnijdkpendafdhdaoeoafdnpfdfpk.json"
    )
    Get-ChildItem $extDir.FullName -File | Where-Object { $_.Name -notin $filesToKeep } |
        Remove-Item -Force -ErrorAction SilentlyContinue

    # Download custom extensions
    $extDownloads = @{
        "google-search-clean.crx"          = "https://github.com/bibicadotnet/coccoc-portable/raw/refs/heads/main/Extensions/google-search-clean.crx"
        "kfjpnijdkpendafdhdaoeoafdnpfdfpk.json" = "https://raw.githubusercontent.com/bibicadotnet/coccoc-portable/refs/heads/main/Extensions/kfjpnijdkpendafdhdaoeoafdnpfdfpk.json"
    }
    $wcExt = New-Object System.Net.WebClient
    foreach ($entry in $extDownloads.GetEnumerator()) {
        try {
            $wcExt.DownloadFile($entry.Value, (Join-Path $extDir.FullName $entry.Key))
            Write-Host "Downloaded: $($entry.Key)" -ForegroundColor DarkGray
        } catch {
            Write-Host "Warning: Failed to download $($entry.Key): $($_.Exception.Message)" -ForegroundColor Yellow
        }
    }
    $wcExt.Dispose()
    Write-Host "Cleaned Extensions." -ForegroundColor DarkGray
}

# Delete browser_proxy.exe from Browser-bin root
$proxyExe = Join-Path $browserBinSrc.FullName "browser_proxy.exe"
if (Test-Path $proxyExe) {
    Remove-Item $proxyExe -Force -ErrorAction SilentlyContinue
    Write-Host "Removed browser_proxy.exe." -ForegroundColor DarkGray
}

# Kill running Cốc Cốc processes
Write-Host "`nStopping Cốc Cốc processes..." -ForegroundColor Cyan
@("browser", "CocCocUpdate", "CocCocCrashHandler") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}
Start-Sleep -Milliseconds 800

# Remove old installation
Write-Host "Removing old installation..." -ForegroundColor Cyan
@("${env:ProgramFiles}\CocCoc", "${env:ProgramFiles(x86)}\CocCoc") | ForEach-Object {
    if (Test-Path $_) {
        takeown /F $_ /R /A /D Y 2>&1 | Out-Null
        icacls $_ /grant:r "Administrators:F" /T /C 2>&1 | Out-Null
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Remove leftover scheduled tasks
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

# Configure Cốc Cốc Adblock
Write-Host "Configuring Cốc Cốc built-in Adblock..." -ForegroundColor Cyan
$prefsDir = "$env:LOCALAPPDATA\CocCoc\Browser\User Data\Default"
$prefsPath = Join-Path $prefsDir "Preferences"

if (!(Test-Path $prefsDir)) {
    New-Item -ItemType Directory -Path $prefsDir -Force | Out-Null
}

$adblockUrl = "https://raw.githubusercontent.com/bibicadotnet/ublock-filters/main/coc-coc-savior.txt"
$defaultSubscriptions = @(
    "https://easylist-downloads.adblockplus.org/easylist.txt",
    "https://easylist-downloads.adblockplus.org/exceptionrules.txt",
    "https://easylist-downloads.adblockplus.org/abp-filters-anti-cv.txt",
    "https://coccoc.com/adblock/coccoc_standard.txt",
    "https://easylist-downloads.adblockplus.org/antiadblockfilters.txt",
    "https://raw.githubusercontent.com/hoshsadiq/adblock-nocoin-list/master/nocoin.txt",
    "https://easylist-downloads.adblockplus.org/abpvn.txt"
)

# Read existing Preferences or create a new PSCustomObject
$prefs = if (Test-Path $prefsPath) {
    try {
        Get-Content $prefsPath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        New-Object PSObject
    }
} else {
    New-Object PSObject
}

if ($null -eq $prefs) { $prefs = New-Object PSObject }
if ($null -eq $prefs.filtering) { $prefs | Add-Member -NotePropertyName "filtering" -NotePropertyValue (New-Object PSObject) }
if ($null -eq $prefs.filtering.configurations) { $prefs.filtering | Add-Member -NotePropertyName "configurations" -NotePropertyValue (New-Object PSObject) }

if ($null -eq $prefs.filtering.configurations.adblock) {
    $adblockObj = [PSCustomObject]@{
        enabled = $true
        domains = @()
        filters = @()
        subscriptions = $defaultSubscriptions + $adblockUrl
    }
    $prefs.filtering.configurations | Add-Member -NotePropertyName "adblock" -NotePropertyValue $adblockObj
} else {
    # If adblock config exists, make sure the URL is in the subscriptions array
    $subList = [System.Collections.Generic.List[string]]::new()
    if ($prefs.filtering.configurations.adblock.subscriptions -is [System.Array]) {
        foreach ($sub in $prefs.filtering.configurations.adblock.subscriptions) {
            $subList.Add($sub)
        }
    }
    if (-not $subList.Contains($adblockUrl)) {
        $subList.Add($adblockUrl)
    }
    $prefs.filtering.configurations.adblock.subscriptions = $subList.ToArray()
    $prefs.filtering.configurations.adblock.enabled = $true
}

# Disable Split View and Sidebar
Write-Host "Disabling Cốc Cốc Split View and Sidebar..." -ForegroundColor Cyan
# Disable Split View (pin_split_tab_button)
if ($null -eq $prefs.browser) { $prefs | Add-Member -NotePropertyName "browser" -NotePropertyValue (New-Object PSObject) }
if ($null -eq $prefs.browser.pin_split_tab_button) {
    $prefs.browser | Add-Member -NotePropertyName "pin_split_tab_button" -NotePropertyValue $false -Force
} else {
    $prefs.browser.pin_split_tab_button = $false
}

# Disable Sidebar docking
if ($null -eq $prefs.side_panel) { $prefs | Add-Member -NotePropertyName "side_panel" -NotePropertyValue (New-Object PSObject) }
if ($null -eq $prefs.side_panel.coccoc_sidebar_docking_mode) {
    $prefs.side_panel | Add-Member -NotePropertyName "coccoc_sidebar_docking_mode" -NotePropertyValue $false -Force
} else {
    $prefs.side_panel.coccoc_sidebar_docking_mode = $false
}

$newPrefsJson = $prefs | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($prefsPath, $newPrefsJson, [System.Text.Encoding]::UTF8)

# Disable Cốc Cốc startup launch in Local State
Write-Host "Disabling Cốc Cốc auto-launch on Windows startup..." -ForegroundColor Cyan
$localStatePath = "$env:LOCALAPPDATA\CocCoc\Browser\User Data\Local State"
$localStateDir = Split-Path $localStatePath
if (!(Test-Path $localStateDir)) {
    New-Item -ItemType Directory -Path $localStateDir -Force | Out-Null
}
$localState = if (Test-Path $localStatePath) {
    try {
        Get-Content $localStatePath -Raw -Encoding UTF8 | ConvertFrom-Json
    } catch {
        New-Object PSObject
    }
} else {
    New-Object PSObject
}
if ($null -eq $localState) { $localState = New-Object PSObject }
if ($null -eq $localState.launch_on_login) { 
    $localState | Add-Member -NotePropertyName "launch_on_login" -NotePropertyValue (New-Object PSObject)
}
if ($null -eq $localState.launch_on_login.foreground) { 
    $localState.launch_on_login | Add-Member -NotePropertyName "foreground" -NotePropertyValue (New-Object PSObject)
}
if ($null -eq $localState.launch_on_login.foreground.enabled) {
    $localState.launch_on_login.foreground | Add-Member -NotePropertyName "enabled" -NotePropertyValue $false -Force
} else {
    $localState.launch_on_login.foreground.enabled = $false
}
$newLocalStateJson = $localState | ConvertTo-Json -Depth 20 -Compress
[System.IO.File]::WriteAllText($localStatePath, $newLocalStateJson, [System.Text.Encoding]::UTF8)

# Cleanup temp folder
Remove-Item $tempRoot -Recurse -Force -ErrorAction SilentlyContinue


# Restart Explorer to apply icon/shortcut changes
Write-Host "`nRestarting Explorer..." -ForegroundColor Cyan
Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue

Write-Host "`nCốc Cốc $version ($useArch) installed!" -BackgroundColor DarkGreen

Write-Host "`nNOTICE: To update Cốc Cốc when needed, please:" -ForegroundColor Cyan -BackgroundColor DarkGreen
Write-Host "1. Open PowerShell with Administrator privileges" -ForegroundColor White
Write-Host "2. Run the following command: irm https://go.bibica.net/coccoc | iex" -ForegroundColor Yellow
Write-Host "3. Wait for the installation process to complete" -ForegroundColor White