<#
.SYNOPSIS
    Cốc Cốc Browser Silent Installer - Giúp giao diện Cốc Cốc sạch như nguyên bản Chromium

.DESCRIPTION
Script này sẽ:
1. Dọn dẹp bản Cốc Cốc cũ (nếu có)
2. Tải về phiên bản mới nhất từ nguồn chính thức
3. Cài đặt không cần tương tác (silent install)
4. Xóa các task tự động cập nhật
5. Vô hiệu hóa CocCocUpdate & CrashHandler bằng cách khóa file
6. Áp dụng tối ưu registry để tăng tốc và loại bỏ thành phần không cần thiết
7. Tạo shortcut desktop/start menu tối ưu, xóa shortcut cũ

.NOTES
    Requires: Quyền Administrator
    Version:  1.1
#>

# Kiểm tra quyền Administrator
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "LỖI: Script yêu cầu chạy với quyền Administrator!" -ForegroundColor Red
    exit 1
}

# ---------- BƯỚC 1: DỌN DẸP BẢN CŨ ----------
Write-Host "[1/7] Đang dọn dẹp bản cài cũ..."

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

# ---------- BƯỚC 2: TẢI FILE CÀI ĐẶT MỚI ----------
$setupPath = "$env:TEMP\coccoc_setup.exe"

Write-Host "[2/7] Đang tải bộ cài mới..."
try {
    (New-Object Net.WebClient).DownloadFile('https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe ', $setupPath)
    Write-Host "✓ Tải thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi tải file: $_" -ForegroundColor Red
    exit 1
}

# ---------- BƯỚC 3: CÀI ĐẶT SILENT ----------
Write-Host "[3/7] Đang cài đặt..."
try {
    $process = Start-Process -FilePath $setupPath -ArgumentList "/silent /install" -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Mã lỗi: $($process.ExitCode)" }
    Write-Host "✓ Cài đặt hoàn tất" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi cài đặt: $_" -ForegroundColor Red
    exit 1
}

# ---------- BƯỚC 4: XÓA TASK TỰ ĐỘNG CẬP NHẬT ----------
Write-Host "[4/7] Đang xóa các task tự động cập nhật..."

$tasksToRemove = @(
    "CocCocUpdateTaskMachineCore",
    "CocCocUpdateTaskMachineUA",
    "CocCoc*"
)

foreach ($task in $tasksToRemove) {
    try {
        schtasks /Delete /TN $task /F 2>$null
        Write-Host "Đã xóa task: $task" -ForegroundColor Cyan
    } catch {
        Write-Host "Không tìm thấy task $task để xóa" -ForegroundColor Yellow
    }
}

# ---------- BƯỚC 5: VÔ HIỆU HÓA CocCocUpdate & CrashHandler ----------
Write-Host "[5/7] Đang xử lý CocCocUpdate và CocCocCrashHandler..."

$targetFiles = @(
    # CrashHandlers trong thư mục version (vd: 2.9.3.21)
    "${env:ProgramFiles}\CocCoc\Update\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles}\CocCoc\Update\*\CocCocCrashHandler64.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\*\CocCocCrashHandler.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\*\CocCocCrashHandler64.exe",

    # File update chính
    "${env:ProgramFiles}\CocCoc\Update\CocCocUpdate.exe",
    "${env:ProgramFiles(x86)}\CocCoc\Update\CocCocUpdate.exe"
)

foreach ($file in (Get-Item $targetFiles -ErrorAction SilentlyContinue)) {
    try {
        # Dừng tiến trình đang chạy
        $processName = $file.BaseName
        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue

        # Chiếm quyền và xóa
        Takeown /F $file.FullName /A 2>&1 | Out-Null
        Icacls $file.FullName /grant:r "Administrators:F" 2>&1 | Out-Null
        Remove-Item $file.FullName -Force

        # Tạo file khóa (ReadOnly + Hidden + System)
        New-Item -Path $file.FullName -ItemType File -Force | Out-Null
        (Get-Item $file.FullName).Attributes = "ReadOnly, Hidden, System"

        Write-Host "[✓] Đã xử lý: $($file.FullName)" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Lỗi $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`nĐã xử lý xong CocCocUpdate và CocCocCrashHandler" -ForegroundColor Green

# ---------- BƯỚC 6: ÁP DỤNG REGISTRY TWEAKS ----------
$regPath = "$env:TEMP\coccoc-debloat.reg"

Write-Host "[6/7] Áp dụng tối ưu hóa registry..."
try {
    if (-not (Test-Path "$env:TEMP")) {
        New-Item -Path "$env:TEMP" -ItemType Directory -Force
    }

    (New-Object Net.WebClient).DownloadFile(
        'https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/main/coccoc-debloat.reg ',
        $regPath
    )

    Start-Process "regedit.exe" -ArgumentList "/s `"$regPath`"" -Wait
    Write-Host "✓ Đã áp dụng tối ưu hóa registry" -ForegroundColor Green
}
catch {
    Write-Host "✗ Không tải được file registry: $_" -ForegroundColor Yellow
}

# ---------- BƯỚC 7: TẠO SHORTCUT TỐI ƯU ----------
Write-Host "[7/7] Đang tạo shortcut tối ưu..." -ForegroundColor Cyan

# Xóa các shortcut Cốc Cốc cũ trước
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

# Đường dẫn browser.exe
$browserPath = "${env:ProgramFiles}\CocCoc\Browser\Application\browser.exe"
if (-not (Test-Path $browserPath)) {
    $browserPath = "${env:ProgramFiles(x86)}\CocCoc\Browser\Application\browser.exe"
}

# Tạo shortcut cho Desktop
$tempDesktopShortcut = Join-Path $desktopPath "CocCoc_Temp.lnk"
$finalDesktopShortcut = Join-Path $desktopPath "Cốc Cốc.lnk"

# Tạo shortcut cho Start Menu
$tempStartMenuShortcut = Join-Path $startMenuPath "CocCoc_Temp.lnk"
$finalStartMenuShortcut = Join-Path $startMenuPath "Cốc Cốc.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell

    # Tạo shortcut Desktop
    Write-Host "Đang tạo shortcut Desktop..." -ForegroundColor Gray
    $DesktopShortcut = $WshShell.CreateShortcut($tempDesktopShortcut)
    $DesktopShortcut.TargetPath = "`"$browserPath`""
    $DesktopShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel"
    $DesktopShortcut.IconLocation = "$browserPath, 0"
    $DesktopShortcut.Save()

    # Đổi tên Desktop shortcut
    Rename-Item -Path $tempDesktopShortcut -NewName "Cốc Cốc.lnk" -Force

    if (Test-Path $finalDesktopShortcut) {
        Write-Host "✓ Đã tạo Desktop shortcut: $finalDesktopShortcut" -ForegroundColor Green
    }

    # Tạo shortcut Start Menu
    Write-Host "Đang tạo shortcut Start Menu..." -ForegroundColor Gray
    $StartMenuShortcut = $WshShell.CreateShortcut($tempStartMenuShortcut)
    $StartMenuShortcut.TargetPath = "`"$browserPath`""
    $StartMenuShortcut.Arguments = "--disable-features=CocCocSplitView,SidePanel"
    $StartMenuShortcut.IconLocation = "$browserPath, 0"
    $StartMenuShortcut.Save()

    # Đổi tên Start Menu shortcut
    Rename-Item -Path $tempStartMenuShortcut -NewName "Cốc Cốc.lnk" -Force

    if (Test-Path $finalStartMenuShortcut) {
        Write-Host "✓ Đã tạo Start Menu shortcut: $finalStartMenuShortcut" -ForegroundColor Green
    }
}
catch {
    Write-Host "!! Lỗi: $($_.Exception.Message)" -ForegroundColor Red
}
finally {
    # Dọn dẹp COM Object
    if ($WshShell) {
        [System.Runtime.Interopservices.Marshal]::ReleaseComObject($WshShell) | Out-Null
    }
    # Dọn dẹp file temp nếu còn sót
    if (Test-Path $tempDesktopShortcut) {
        Remove-Item $tempDesktopShortcut -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path $tempStartMenuShortcut) {
        Remove-Item $tempStartMenuShortcut -Force -ErrorAction SilentlyContinue
    }
}

# Dọn dẹp cuối cùng
Remove-Item $setupPath, $regPath -ErrorAction SilentlyContinue

# Hoàn tất
Write-Host "`nHOÀN TẤT MỌI QUÁ TRÌNH!" -BackgroundColor DarkGreen

Write-Host "`nTHÔNG BÁO: Để cập nhật Cốc Cốc khi cần, vui lòng:" -ForegroundColor Cyan -BackgroundColor DarkGreen
Write-Host "1. Mở PowerShell với quyền Administrator" -ForegroundColor White
Write-Host "2. Chạy lệnh sau: irm https://go.bibica.net/coccoc  | iex" -ForegroundColor Yellow
Write-Host "3. Chờ quá trình cài đặt hoàn tất" -ForegroundColor White
