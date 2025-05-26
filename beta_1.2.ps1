<#
.SYNOPSIS
    Cốc Cốc Browser Silent Installer - Makes the Cốc Cốc interface as clean as the original Chromium
.DESCRIPTION
    - Automatically downloads from the official source
    - Installation without user interaction (silent install)
    - Removes automatic update tasks and supports manual updates
    - Optimizes Registry settings
    - Creates Desktop and Start Menu shortcuts for Cốc Cốc (SplitView and SidePanel disabled by default)
.NOTES
    Requires: Administrator privileges
    Version: 1.2
#>

# Fix encoding issues
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

# Require Administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "This script requires Administrator rights. Please run PowerShell as Administrator." -ForegroundColor Red
    exit
}

Write-Host "`nCốc Cốc Browser Silent Installer v1.2" -BackgroundColor DarkGreen

# Function to perform operation with retry logic
function Invoke-WithRetry {
    param (
        [ScriptBlock]$ScriptBlock,
        [string]$OperationName,
        [int]$MaxRetries = 3,
        [int]$RetryDelay = 5
    )
    
    $attempt = 1
    $lastError = $null
    
    while ($attempt -le $MaxRetries) {
        try {
            Write-Host "[Attempt $attempt/$MaxRetries] $OperationName" -ForegroundColor Cyan
            $result = & $ScriptBlock
            return $result
        }
        catch {
            $lastError = $_
            Write-Host "Attempt $attempt failed: $_" -ForegroundColor Yellow
            $attempt++
            
            if ($attempt -le $MaxRetries) {
                Write-Host "Retrying in $RetryDelay seconds..." -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryDelay
            }
        }
    }
    
    Write-Host "Operation failed after $MaxRetries attempts." -ForegroundColor Red
    Write-Host "Last error details: $lastError" -ForegroundColor Red
    throw $lastError
}

# Force terminate all CocCoc processes without prompts
function Stop-CocCocProcesses {
    Write-Host "`nTerminating all CocCoc processes..." -ForegroundColor Cyan
    
    # List all CocCoc-related process names
    $targetProcesses = @(
        "browser",          # Main browser process
        "CocCocUpdate",     # Updater
        "CocCocCrashHandler", # Crash reporter
        "CocCocCrashHandler64" # 64-bit crash reporter
    )

    # Kill all instances immediately
    foreach ($proc in $targetProcesses) {
        try {
            Get-Process -Name $proc -ErrorAction SilentlyContinue | 
            Stop-Process -Force -ErrorAction SilentlyContinue
        }
        catch { 
            # Silent fail - we don't care if process wasn't running
        }
    }

    # Double-tap to ensure everything is dead
    Start-Sleep -Milliseconds 500
    foreach ($proc in $targetProcesses) {
        try {
            Get-Process -Name $proc -ErrorAction SilentlyContinue | 
            Stop-Process -Force -ErrorAction SilentlyContinue
        }
        catch { }
    }

    Write-Host "All CocCoc processes terminated." -ForegroundColor Green
}

# Execute immediately
Stop-CocCocProcesses

# 1. Download and install Coc Coc silently with retry
Write-Host "`nCleaning up old installation..." -ForegroundColor Cyan
$cocPaths = @(
    "${env:ProgramFiles}\CocCoc",
    "${env:ProgramFiles(x86)}\CocCoc"
)

foreach ($path in $cocPaths) {
    if (Test-Path $path) {
        try {
            Stop-Process -Name "browser*" -Force -ErrorAction SilentlyContinue
            Takeown /F $path /R /A /D Y 2>&1 | Out-Null
            Icacls $path /grant:r "Administrators:F" /T /C 2>&1 | Out-Null
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleaned up: $path" -ForegroundColor Green
        } catch {
            Write-Host "Could not delete: $path" -ForegroundColor Yellow
        }
    }
}

Write-Host "`nStarting Coc Coc download and installation..." -ForegroundColor Cyan
$CocCocInstaller = "$env:TEMP\coccoc_en_machine.exe"

try {
    # Download Coc Coc installer with retry
    Invoke-WithRetry -OperationName "Downloading Coc Coc installer" -ScriptBlock {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri "https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe" -OutFile $CocCocInstaller -UseBasicParsing
    }
    
    # Install Coc Coc with retry
    $installProcess = Invoke-WithRetry -OperationName "Installing Coc Coc" -ScriptBlock {
        $process = Start-Process -FilePath $CocCocInstaller -ArgumentList "/silent /install" -PassThru -Wait
        return $process
    }
    
    if ($installProcess.ExitCode -eq 0) {
        Write-Host "Coc Coc installed successfully." -ForegroundColor Green
    } else {
        Write-Host "Coc Coc installation completed with exit code $($installProcess.ExitCode)" -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Fatal error during Coc Coc installation: $_" -ForegroundColor Red
    exit
}

# 2. Configure Coc Coc Update policies
Write-Host "`nConfiguring Coc Coc Update policies..." -ForegroundColor Cyan

# Create registry keys if they don't exist
$CocCocUpdateRegPath = "HKLM:\SOFTWARE\Policies\CocCoc\CocCocUpdate"
if (-not (Test-Path $CocCocUpdateRegPath)) {
    New-Item -Path $CocCocUpdateRegPath -Force | Out-Null
}

# Set registry values to disable auto-updates but allow manual updates
$updateSettings = @{
    "AutoUpdateCheckPeriodMinutes" = 0
    "UpdateDefault" = 0
    "DisableAutoUpdateChecksCheckboxValue" = 1
    "InstallDefault" = 0
    "AllowManualUpdateCheck" = 1  # This enables manual updates from Settings
}

foreach ($key in $updateSettings.Keys) {
    Set-ItemProperty -Path $CocCocUpdateRegPath -Name $key -Value $updateSettings[$key] -Type DWord
}

# 3. Completely stop and disable CocCocUpdate CocCocCrashHandler processes
Write-Host "`nStopping all CocCocUpdate CocCocCrashHandler processes..." -ForegroundColor Cyan
try {
    $processNames = @("CocCocUpdate*", "CocCocCrashHandler", "CocCocCrashHandler64")
    
    foreach ($name in $processNames) {
        try {
            $processes = Get-Process -Name $name -ErrorAction Stop
            if ($processes) {
                $processes | Stop-Process -Force
                Write-Host "[SUCCESS] Stopped all $name processes" -ForegroundColor Green
            }
        }
        catch [Microsoft.PowerShell.Commands.ProcessCommandException] {
            Write-Host "[INFO] No $name processes found" -ForegroundColor Cyan
        }
        catch {
            Write-Host "[ERROR] Failed to stop $name processes: $_" -ForegroundColor Red
        }
    }
}
catch {
    Write-Host "[CRITICAL] General error in process termination: $_" -ForegroundColor Red
    Write-Host "[DEBUG] Try running as Administrator" -ForegroundColor Yellow
}

# 4. Disable CocCocCrashHandler processes
Write-Host "`nDisabling CocCocCrashHandler components..." -ForegroundColor Cyan

# Target all CrashHandler variants (both 32-bit and 64-bit)
$crashHandlerFiles = @(
    "${env:ProgramFiles}\CocCoc\Application\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles}\CocCoc\Application\*\CocCocCrashHandler64.exe", 
    "${env:ProgramFiles(x86)}\CocCoc\Application\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Application\*\CocCocCrashHandler64.exe"
)

foreach ($file in (Get-Item $crashHandlerFiles -ErrorAction SilentlyContinue | Where-Object { $_.Exists })) {
    try {
        # 1. Stop any running instances
        $processName = $file.BaseName
        Get-Process -Name $processName -ErrorAction SilentlyContinue | Stop-Process -Force

        # 2. Disable by renaming executable
        $disabledPath = $file.FullName + ".disabled"
        Rename-Item -Path $file.FullName -NewName $disabledPath -Force

        Write-Host "[SUCCESS] Disabled: $($file.Name)" -ForegroundColor Green
    }
    catch {
        Write-Host "[ERROR] Failed to disable $($file.Name): $_" -ForegroundColor Red
    }
}

Write-Host "CocCocCrashHandler components disabled" -ForegroundColor Cyan

# 5. Remove scheduled update tasks with retry
Write-Host "`nRemoving Coc Coc scheduled tasks..." -ForegroundColor Cyan

$TasksToRemove = @("CocCoc*")

foreach ($taskName in $TasksToRemove) {
    try {
        Invoke-WithRetry -OperationName "Removing task $taskName" -ScriptBlock {
            $task = Get-ScheduledTask -TaskName $taskName -ErrorAction SilentlyContinue
            if ($task) {
                # Disable task first if enabled
                if ($task.State -ne "Disabled") {
                    $task | Disable-ScheduledTask -ErrorAction SilentlyContinue | Out-Null
                }
                # Delete the task
                $task | Unregister-ScheduledTask -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
                Write-Host "Removed task: $taskName" -ForegroundColor Green
            }
        }
    }
    catch {
        Write-Host "Failed to remove task ${taskName} after retries: $_" -ForegroundColor Red
    }
}

# 6. Apply additional registry tweaks with retry
Write-Host "`nApplying additional registry tweaks..." -ForegroundColor Cyan

# First, apply restore registry
$RestoreRegFileUrl = "https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/coccoc-restore.reg"
$RestoreRegFile = "$env:TEMP\coccoc_restore.reg"

try {
    Write-Host "Downloading and applying coccoc-restore.reg..." -ForegroundColor Cyan
    Invoke-WithRetry -OperationName "Downloading restore registry file" -ScriptBlock {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $RestoreRegFileUrl -OutFile $RestoreRegFile -UseBasicParsing
    }
    
    Invoke-WithRetry -OperationName "Applying restore registry tweaks" -ScriptBlock {
        Start-Process "regedit.exe" -ArgumentList "/s `"$RestoreRegFile`"" -Wait -NoNewWindow
    }
    
    Write-Host "Restore registry tweaks applied successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error applying restore registry tweaks: $_" -ForegroundColor Red
}

# Then apply the debloat registry settings
$DebloatRegFileUrl = "https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/refs/heads/main/coccoc-debloat.reg"
$DebloatRegFile = "$env:TEMP\coccoc_debloat.reg"

try {
    Invoke-WithRetry -OperationName "Downloading debloat registry tweaks" -ScriptBlock {
        $ProgressPreference = 'SilentlyContinue'
        Invoke-WebRequest -Uri $DebloatRegFileUrl -OutFile $DebloatRegFile -UseBasicParsing
    }
    
    Invoke-WithRetry -OperationName "Applying debloat registry tweaks" -ScriptBlock {
        Start-Process "regedit.exe" -ArgumentList "/s `"$DebloatRegFile`"" -Wait -NoNewWindow
    }
    
    Write-Host "Debloat registry tweaks applied successfully." -ForegroundColor Green
}
catch {
    Write-Host "Error applying debloat registry tweaks after retries: $_" -ForegroundColor Red
}

# 7. Creating shortcut with new arguments
Write-Host "`nCreating new shortcut..." -ForegroundColor Cyan

# Remove old Cốc Cốc shortcuts
$desktopPath = [Environment]::GetFolderPath("Desktop")
$publicDesktopPath = [Environment]::GetFolderPath("CommonDesktopDirectory")
$startMenuPath = [Environment]::GetFolderPath("CommonPrograms")

$oldShortcuts = @(
    "$desktopPath\Cốc Cốc.lnk",
    "$desktopPath\CocCoc.lnk", 
    "$publicDesktopPath\Cốc Cốc.lnk",
    "$publicDesktopPath\CocCoc.lnk",
    "$startMenuPath\Cốc Cốc.lnk",
    "$startMenuPath\CocCoc.lnk"
)

foreach ($oldShortcut in $oldShortcuts) {
    if (Test-Path $oldShortcut) {
        Remove-Item $oldShortcut -Force -ErrorAction SilentlyContinue
        Write-Host "[SUCCESS] Removed old shortcut: $oldShortcut" -ForegroundColor Yellow
    }
}

# Find browser.exe path
$browserPath = "${env:ProgramFiles}\CocCoc\Browser\Application\browser.exe"
if (-not (Test-Path $browserPath)) {
    $browserPath = "${env:ProgramFiles(x86)}\CocCoc\Browser\Application\browser.exe"
}

# Shortcut paths
$tempDesktopShortcut = Join-Path $desktopPath "CocCoc_Temp.lnk"
$finalDesktopShortcut = Join-Path $desktopPath "Cốc Cốc.lnk"

$tempStartMenuShortcut = Join-Path $startMenuPath "CocCoc_Temp.lnk"
$finalStartMenuShortcut = Join-Path $startMenuPath "Cốc Cốc.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    
    # Create Desktop shortcut
    Write-Host "Creating Desktop shortcut..." -ForegroundColor Gray
    $DesktopShortcut = $WshShell.CreateShortcut($tempDesktopShortcut)
    $DesktopShortcut.TargetPath = "$browserPath"
    $DesktopShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel --profile-directory=Default"
    $DesktopShortcut.IconLocation = "$browserPath, 0"
    $DesktopShortcut.Save()
    
    # Rename Desktop shortcut
    Rename-Item -Path $tempDesktopShortcut -NewName "Cốc Cốc.lnk" -Force
    
    if (Test-Path $finalDesktopShortcut) {
        Write-Host "[SUCCESS] Created Desktop shortcut: $finalDesktopShortcut" -ForegroundColor Green
    }
    
    # Create Start Menu shortcut
    Write-Host "Creating Start Menu shortcut..." -ForegroundColor Gray
    $StartMenuShortcut = $WshShell.CreateShortcut($tempStartMenuShortcut)
    $StartMenuShortcut.TargetPath = "$browserPath"
    $StartMenuShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel --profile-directory=Default"
    $StartMenuShortcut.IconLocation = "$browserPath, 0"
    $StartMenuShortcut.Save()
    
    # Rename Start Menu shortcut
    Rename-Item -Path $tempStartMenuShortcut -NewName "Cốc Cốc.lnk" -Force
    
    if (Test-Path $finalStartMenuShortcut) {
        Write-Host "[SUCCESS] Created Start Menu shortcut: $finalStartMenuShortcut" -ForegroundColor Green
    }
}
catch {
    Write-Host "[ERROR] Failed to create shortcut: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Release COM object
    if ($WshShell) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    }

    # Clean up temporary files
    if (Test-Path $tempDesktopShortcut) {
        Remove-Item $tempDesktopShortcut -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $tempStartMenuShortcut) {
        Remove-Item $tempStartMenuShortcut -Force -ErrorAction SilentlyContinue
    }
}




# Cleanup temporary files
Remove-Item -Path $CocCocInstaller -ErrorAction SilentlyContinue
Remove-Item -Path $RestoreRegFile -ErrorAction SilentlyContinue
Remove-Item -Path $DebloatRegFile -ErrorAction SilentlyContinue

Write-Host "`nCoc Coc clean installation completed!" -ForegroundColor Green
Write-Host "Manual updates from Settings -> About Cốc Cốc will work, but automatic updates are completely disabled." -ForegroundColor Yellow
Write-Host "Recommendation: Restart your computer to apply all changes." -ForegroundColor Yellow
