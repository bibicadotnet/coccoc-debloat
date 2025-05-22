<#
.SYNOPSIS
    Automated Coc Coc Browser Silent Installer
.DESCRIPTION
    This script performs silent installation of Coc Coc browser with:
    - Automatic download from official source
    - Silent installation
    - Removal of auto-update tasks
    - Registry optimizations
.NOTES
    Requires: Administrator privileges
    Version:  1.1
#>

# Check for administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "This script requires Administrator privileges!" -ForegroundColor Red
    Write-Host "Please run PowerShell as Administrator and try again." -ForegroundColor Yellow
    Start-Sleep 3
    exit 1
}

# Step 1: Download installer
$setupPath = "$env:TEMP\coccoc_setup.exe"
Write-Host "[1/4] Downloading Coc Coc installer..."

try {
    # Using WebClient for better compatibility
    (New-Object Net.WebClient).DownloadFile(
        'https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe',
        $setupPath
    )
    Write-Host "Download completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Download failed: $_" -ForegroundColor Red
    exit 1
}

# Step 2: Silent installation
Write-Host "[2/4] Installing Coc Coc (silent mode)..."
try {
    $installProcess = Start-Process -FilePath $setupPath -ArgumentList "/silent /install" -PassThru -Wait
    
    if ($installProcess.ExitCode -ne 0) {
        throw "Installation failed with exit code $($installProcess.ExitCode)"
    }
    Write-Host "Installation completed successfully" -ForegroundColor Green
}
catch {
    Write-Host "Installation error: $_" -ForegroundColor Red
    exit 1
}

# Step 3: Remove auto-update tasks
Write-Host "[3/4] Removing auto-update tasks..."
$tasksToRemove = @(
    "CocCocUpdateTaskMachineCore",
    "CocCocUpdateTaskMachineUA"
)

foreach ($task in $tasksToRemove) {
    try {
        schtasks /Delete /TN $task /F 2>$null
        Write-Host "Removed task: $task" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Warning: Could not remove task $task" -ForegroundColor Yellow
    }
}

# Step 4: Apply registry optimizations
$regPath = "$env:TEMP\coccoc-debloat.reg"
Write-Host "[4/4] Applying performance tweaks..."

try {
    (New-Object Net.WebClient).DownloadFile(
        'https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/main/coccoc-debloat.reg',
        $regPath
    )
    
    # Import registry silently
    Start-Process "regedit.exe" -ArgumentList "/s `"$regPath`"" -Wait
    Write-Host "Registry optimizations applied" -ForegroundColor Green
}
catch {
    Write-Host "Warning: Could not apply registry tweaks: $_" -ForegroundColor Yellow
}

# Cleanup temporary files
Remove-Item $setupPath -ErrorAction SilentlyContinue
Remove-Item $regPath -ErrorAction SilentlyContinue

# Completion message
Write-Host "`nCoc Coc installation completed successfully!" -ForegroundColor Green
Write-Host "Optimizations applied:" -ForegroundColor White
Write-Host "- Disabled auto-update tasks" -ForegroundColor White
Write-Host "- Applied performance tweaks" -ForegroundColor White