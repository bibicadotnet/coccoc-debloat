<#
Cốc Cốc Browser Silent Installer
- Downloads & installs silently
- Disables auto-update & crash reporter
- Creates clean shortcuts
#>

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Require Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm https://go.bibica.net/coccoc | iex`"" -Verb RunAs
    exit
}

Clear-Host
Write-Host "Cốc Cốc Browser Installer v1.2.4" -BackgroundColor DarkGreen
Write-Host "`nStarting Coc Coc download and installation..." -ForegroundColor Cyan

# Kill processes
@("browser", "CocCocUpdate", "CocCocCrashHandler*") | ForEach-Object {
    Get-Process -Name $_ -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
}

# Clean old installation
@("${env:ProgramFiles}\CocCoc", "${env:ProgramFiles(x86)}\CocCoc") | ForEach-Object {
    if (Test-Path $_) {
        takeown /F $_ /R /A /D Y 2>&1 | Out-Null
        icacls $_ /grant:r "Administrators:F" /T /C 2>&1 | Out-Null
        Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Download & install
$installer = "$env:TEMP\coccoc.exe"
$urls = @(
    "https://files.coccoc.com/browser/x64/coccoc_standalone_en.exe",
    "https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe"
)

foreach ($url in $urls) {
    try {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $url -OutFile $installer -UseBasicParsing -TimeoutSec 30
        break
    }
    catch { continue }
}

Start-Process -FilePath $installer -ArgumentList "/silent /install" -Wait

# Disable updater & crash handler
Get-Item "${env:ProgramFiles}\CocCoc\Update\*\CocCocCrashHandler*.exe", "${env:ProgramFiles(x86)}\CocCoc\Update\*\CocCocCrashHandler*.exe", "${env:ProgramFiles}\CocCoc\Update\CocCocUpdate.exe", "${env:ProgramFiles(x86)}\CocCoc\Update\CocCocUpdate.exe" -ErrorAction SilentlyContinue | ForEach-Object {
    Get-Process -Name $_.BaseName -ErrorAction SilentlyContinue | Stop-Process -Force
    $disabled = $_.FullName + ".disabled"
    Rename-Item -Path $_.FullName -NewName $disabled -Force -ErrorAction SilentlyContinue
    New-Item -Path $_.FullName -ItemType File -Force | Out-Null
    (Get-Item $_.FullName -ErrorAction SilentlyContinue).Attributes = "ReadOnly, Hidden, System"
}

# Remove scheduled tasks
Get-ScheduledTask -TaskName "CocCoc*" -ErrorAction SilentlyContinue | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue

# Apply registry tweaks
@(
    @{ "name" = "restore"; "url" = "https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/coccoc-restore.reg" },
    @{ "name" = "debloat"; "url" = "https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/coccoc-debloat.reg" }
) | ForEach-Object {
    try {
        $regFile = "$env:TEMP\$($_.name).reg"
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $_.url -OutFile $regFile -UseBasicParsing -TimeoutSec 15
        Start-Process "regedit.exe" -ArgumentList "/s `"$regFile`"" -Wait -NoNewWindow
        Remove-Item $regFile -ErrorAction SilentlyContinue
    }
    catch { }
}

# Create shortcuts
$browserPath = "${env:ProgramFiles}\CocCoc\Browser\Application\browser.exe"
if (-not (Test-Path $browserPath)) {
    $browserPath = "${env:ProgramFiles(x86)}\CocCoc\Browser\Application\browser.exe"
}

if (Test-Path $browserPath) {
    # Remove old shortcuts from ALL locations
    @(
        [Environment]::GetFolderPath("Desktop"),
        [Environment]::GetFolderPath("CommonDesktopDirectory"), 
        [Environment]::GetFolderPath("Programs"),
        [Environment]::GetFolderPath("CommonPrograms")
    ) | ForEach-Object {
        if (Test-Path $_) {
            Get-ChildItem "$_\*Cốc Cốc*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem "$_\*CocCoc*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
            Get-ChildItem "$_\*Coc Coc*.lnk" -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Create new shortcuts
    @([Environment]::GetFolderPath("Desktop"), [Environment]::GetFolderPath("CommonPrograms")) | ForEach-Object {
        $WshShell = New-Object -ComObject WScript.Shell
        $temp = "$_\temp.lnk"
        $final = "$_\Cốc Cốc.lnk"
        
        $shortcut = $WshShell.CreateShortcut($temp)
        $shortcut.TargetPath = $browserPath
        $shortcut.Arguments = "--no-first-run --no-default-browser-check --disable-features=CocCocSplitView,SidePanel --profile-directory=Default"
        $shortcut.IconLocation = "$browserPath,0"
        $shortcut.Save()
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
        
        # Rename temp to final name and cleanup
        if (Test-Path $temp) {
            Rename-Item $temp $final -ErrorAction SilentlyContinue
        }
        # Remove temp file if rename failed
        Remove-Item $temp -ErrorAction SilentlyContinue
    }
}

# Cleanup
Remove-Item $installer -ErrorAction SilentlyContinue

Write-Host "`nCoc Coc clean installation completed!" -BackgroundColor DarkGreen

Write-Host "`nAutomatic updates are completely disabled." -ForegroundColor Yellow
Write-Host "Recommendation: Restart your computer to apply all changes." -ForegroundColor Yellow

Write-Host "`nNOTICE: To update Cốc Cốc when needed, please:" -ForegroundColor Cyan -BackgroundColor DarkGreen
Write-Host "1. Open PowerShell with Administrator privileges" -ForegroundColor White
Write-Host "2. Run the following command: irm https://go.bibica.net/coccoc | iex" -ForegroundColor Yellow
Write-Host "3. Wait for the installation process to complete" -ForegroundColor White
