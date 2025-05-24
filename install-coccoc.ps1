<#
.SYNOPSIS
    Cài đặt Cốc Cốc sạch - không tự động update, không rác
.DESCRIPTION
    1. Tải về bộ cài chính thức
    2. Cài đặt im lặng (không hiện giao diện)
    3. Gỡ bỏ các tác vụ và tiến trình tự động cập nhật
    4. Chặn update và crash handler
    5. Áp dụng tinh chỉnh registry
    6. Tạo shortcut tối ưu
.NOTES
    Yêu cầu: Quyền Administrator
    Phiên bản: 1.1
#>

# Kiểm tra quyền Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu quyền Administrator!" -ForegroundColor Red
    exit 1
}

# [1/6] Dọn dẹp bản Cốc Cốc cũ nếu có
Write-Host "[1/6] Đang dọn dẹp bản cài cũ..."
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
            Write-Host "✓ Đã dọn dẹp: $path" -ForegroundColor Green
        } catch {
            Write-Host "! Không thể xóa: $path" -ForegroundColor Yellow
        }
    }
}

# [2/6] Tải bộ cài Cốc Cốc mới nhất
Write-Host "[2/6] Đang tải bộ cài mới..."
$setupPath = "$env:TEMP\coccoc_setup.exe"
try {
    (New-Object Net.WebClient).DownloadFile('https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe ', $setupPath)
    Write-Host "✓ Tải thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi tải file: $_" -ForegroundColor Red
    exit 1
}

# [3/6] Cài đặt Cốc Cốc
Write-Host "[3/6] Đang cài đặt..."
try {
    $process = Start-Process -FilePath $setupPath -ArgumentList "/silent /install" -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Mã lỗi: $($process.ExitCode)" }
    Write-Host "✓ Cài đặt hoàn tất" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi cài đặt: $_" -ForegroundColor Red
    exit 1
}

# Dọn file tạm
Remove-Item $setupPath -Force -ErrorAction SilentlyContinue

# [4/6] Xóa tác vụ tự động cập nhật
Write-Host "[4/6] Đang xóa tác vụ tự động update..."
$tasksToRemove = @(
    "CocCocUpdateTaskMachineCore",
    "CocCocUpdateTaskMachineUA",
    "CocCoc*"
)
foreach ($task in $tasksToRemove) {
    try {
        schtasks /Delete /TN $task /F 2>$null
        Write-Host "✓ Đã xóa task: $task" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Không tìm thấy task $task để xóa" -ForegroundColor Yellow
    }
}

# Xóa file CocCocUpdate, CocCocCrashHandler, tạo file giả để chặn
Write-Host "Đang xử lý CocCocUpdate và CocCocCrashHandler..." -ForegroundColor Cyan
$targetFiles = @(
    "${env:ProgramFiles}\CocCoc\Update\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles}\CocCoc\Update\*\CocCocCrashHandler64.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\*\CocCocCrashHandler64.exe",
    "${env:ProgramFiles}\CocCoc\Update\CocCocUpdate.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\CocCocUpdate.exe"
)
foreach ($file in (Get-Item $targetFiles -ErrorAction SilentlyContinue)) {
    try {
        Stop-Process -Name $file.BaseName -Force -ErrorAction SilentlyContinue
        Takeown /F $file.FullName /A 2>&1 | Out-Null
        Icacls $file.FullName /grant:r "Administrators:F" 2>&1 | Out-Null
        Remove-Item $file.FullName -Force
        New-Item -Path $file.FullName -ItemType File -Force | Out-Null
        (Get-Item $file.FullName).Attributes = "ReadOnly, Hidden, System"
        Write-Host "[✓] Đã xử lý: $($file.FullName)" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Lỗi $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`n✓ Đã chặn update và crash handler" -BackgroundColor DarkGreen

# [5/6] Áp dụng tối ưu hóa Registry
Write-Host "[5/6] Áp dụng tinh chỉnh registry..."
$regPath = "$env:TEMP\coccoc-debloat.reg"
try {
    if (-not (Test-Path "$env:TEMP")) { New-Item -Path "$env:TEMP" -ItemType Directory -Force }
    (New-Object Net.WebClient).DownloadFile(
        'https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/main/coccoc-debloat.reg ',
        $regPath
    )
    Start-Process "regedit.exe" -ArgumentList "/s `"$regPath`"" -Wait
    Write-Host "✓ Đã áp dụng registry tweaks" -ForegroundColor Green
}
catch {
    Write-Host "✗ Không tải được file registry: $_" -ForegroundColor Yellow
}

# [6/6] Tạo shortcut tối ưu
Write-Host "[6/6] Đang tạo shortcut tối ưu..." -ForegroundColor Cyan
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
        Write-Host "✓ Đã xóa shortcut cũ: $oldShortcut" -ForegroundColor Yellow
    }
}

# Tạo shortcut mới với các flags tối ưu
$browserPath = "${env:ProgramFiles}\CocCoc\Browser\Application\browser.exe"
if (-not (Test-Path $browserPath)) {
    $browserPath = "${env:ProgramFiles(x86)}\CocCoc\Browser\Application\browser.exe"
}
$tempDesktopShortcut = Join-Path $desktopPath "CocCoc_Temp.lnk"
$finalDesktopShortcut = Join-Path $desktopPath "Cốc Cốc.lnk"
$tempStartMenuShortcut = Join-Path $startMenuPath "CocCoc_Temp.lnk"
$finalStartMenuShortcut = Join-Path $startMenuPath "Cốc Cốc.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $DesktopShortcut = $WshShell.CreateShortcut($tempDesktopShortcut)
    $DesktopShortcut.TargetPath = "`"$browserPath`""
    $DesktopShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel"
    $DesktopShortcut.IconLocation = "$browserPath, 0"
    $DesktopShortcut.Save()
    Rename-Item -Path $tempDesktopShortcut -NewName "Cốc Cốc.lnk" -Force
    if (Test-Path $finalDesktopShortcut) {
        Write-Host "✓ Đã tạo Desktop shortcut: $finalDesktopShortcut" -ForegroundColor Green
    }

    $StartMenuShortcut = $WshShell.CreateShortcut($tempStartMenuShortcut)
    $StartMenuShortcut.TargetPath = "`"$browserPath`""
    $StartMenuShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel"
    $StartMenuShortcut.IconLocation = "$browserPath, 0"
    $StartMenuShortcut.Save()
    Rename-Item -Path $tempStartMenuShortcut -NewName "Cốc Cốc.lnk" -Force
    if (Test-Path $finalStartMenuShortcut) {
        Write-Host "✓ Đã tạo Start Menu shortcut: $finalStartMenuShortcut" -ForegroundColor Green
    }
}
catch {
    Write-Host "‼️ Lỗi tạo shortcut: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    if ($WshShell) { [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null }
    if (Test-Path $tempDesktopShortcut) { Remove-Item $tempDesktopShortcut -Force -ErrorAction SilentlyContinue }
    if (Test-Path $tempStartMenuShortcut) { Remove-Item $tempStartMenuShortcut -Force -ErrorAction SilentlyContinue }
}

# Dọn rác cuối cùng
Remove-Item $setupPath, $regPath -ErrorAction SilentlyContinue

# Thông báo hoàn tất
Write-Host "`nHOÀN TẤT!" -BackgroundColor DarkGreen
Write-Host "- Đã cài đặt Cốc Cốc"
Write-Host "- Đã xóa tự động update"
Write-Host "- Đã xóa CrashHandlers"
Write-Host "- Đã áp dụng registry optimizations"
Write-Host "`nTHÔNG BÁO: Nếu muốn cập nhật Cốc Cốc sau này, vui lòng:" -ForegroundColor Cyan
Write-Host "1. Mở PowerShell với quyền Administrator"
Write-Host "2. Chạy lệnh: irm https://go.bibica.net/coccoc | iex" -ForegroundColor Yellow
Write-Host "3. Chờ quá trình hoàn tất"
