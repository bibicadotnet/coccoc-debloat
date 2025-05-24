<#
.SYNOPSIS
    Cốc Cốc Browser Silent Installer - Giúp giao diện Cốc Cốc sạch như nguyên bản Chromium
.DESCRIPTION
1. Tự động tải xuống từ nguồn chính thức
2. Cài đặt không cần tương tác (silent install)
3. Gỡ bỏ các tác vụ tự động cập nhật
4. Tối ưu hóa cấu hình Registry
.NOTES
    Requires: Administrator privileges
    Version:  1.1
#>

# Kiểm tra Admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Yêu cầu quyền Administrator!" -ForegroundColor Red
    exit 1
}

Write-Host "`Cốc Cốc Browser Silent Installer v1.0" -BackgroundColor DarkGreen

# ---------- PHẦN CÀI ĐẶT ----------
$setupPath = "$env:TEMP\coccoc_setup.exe"

# 1. Dọn dẹp toàn bộ trước khi cài
Write-Host "n[1/4] Đang dọn dẹp bản cài cũ..."
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

# 2. Tải file mới
Write-Host "[2/4] Đang tải bộ cài mới..."
try {
    (New-Object Net.WebClient).DownloadFile('https://files2.coccoc.com/browser/x64/coccoc_en_machine.exe', $setupPath)
    Write-Host "✓ Tải thành công" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi tải file: $_" -ForegroundColor Red
    exit 1
}

# 3. Cài đặt
Write-Host "[3/4] Đang cài đặt..."
try {
    $process = Start-Process -FilePath $setupPath -ArgumentList "/silent /install" -PassThru -Wait
    if ($process.ExitCode -ne 0) { throw "Mã lỗi: $($process.ExitCode)" }
    Write-Host "✓ Cài đặt hoàn tất" -ForegroundColor Green
} catch {
    Write-Host "✗ Lỗi cài đặt: $_" -ForegroundColor Red
    exit 1
}

# 4. Dọn dẹp file tạm
Write-Host "[4/4] Đang hoàn tất..."
Remove-Item $setupPath -Force -ErrorAction SilentlyContinue

# Bước 3: xóa task tự động update
Write-Host "[3/5] Xóa task tự động update..."
$tasksToRemove = @(
    "CocCocUpdateTaskMachineCore",
    "CocCocUpdateTaskMachineUA",
    "CocCoc*"
)

foreach ($task in $tasksToRemove) {
    try {
        schtasks /Delete /TN $task /F 2>$null
        Write-Host "Đã xóa task: $task" -ForegroundColor Cyan
    }
    catch {
        Write-Host "Không tìm thấy task $task để xóa" -ForegroundColor Yellow
    }
}

# Bước 4: xóa và phân quyền lại CocCocUpdate CocCocCrashHandler CocCocCrashHandler64
# Yêu cầu quyền Admin
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

Write-Host "Đang xử lý CocCocUpdate và CocCocCrashHandler ..." -ForegroundColor Cyan

# Danh sách file cần xử lý (tự động phát hiện cả 32-bit và 64-bit)
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
        # 1. Dừng tiến trình đang chạy
        $processName = $file.BaseName
        Stop-Process -Name $processName -Force -ErrorAction SilentlyContinue

        # 2. Chiếm quyền và xóa
        Takeown /F $file.FullName /A 2>&1 | Out-Null
        Icacls $file.FullName /grant:r "Administrators:F" 2>&1 | Out-Null
        Remove-Item $file.FullName -Force

        # 3. Tạo file khóa (ReadOnly + Hidden + System)
        New-Item -Path $file.FullName -ItemType File -Force | Out-Null
        (Get-Item $file.FullName).Attributes = "ReadOnly, Hidden, System"
        
        Write-Host "[✓] Đã xử lý: $($file.FullName)" -ForegroundColor Green
    }
    catch {
        Write-Host "[!] Lỗi $($file.FullName): $($_.Exception.Message)" -ForegroundColor Red
    }
}

Write-Host "`Đã xử lý xong CocCocUpdate và CocCocCrashHandler" 

# Bước 4: Áp dụng registry optimizations
$regPath = "$env:TEMP\coccoc-debloat.reg"
Write-Host "[5/5] Áp dụng registry optimizations..."
try {
    if (-not (Test-Path "$env:TEMP")) { New-Item -Path "$env:TEMP" -ItemType Directory -Force }

    (New-Object Net.WebClient).DownloadFile(
        'https://raw.githubusercontent.com/bibicadotnet/coccoc-debloat/main/coccoc-debloat.reg',
        $regPath
    )
    
    Start-Process "regedit.exe" -ArgumentList "/s `"$regPath`"" -Wait
    Write-Host "Đã áp dụng registry tweaks" -ForegroundColor Green
}
catch {
    Write-Host "Không tải được file registry: $_" -ForegroundColor Yellow
}

# Dọn dẹp
Remove-Item $setupPath, $regPath -ErrorAction SilentlyContinue

Write-Host "`nHOÀN TẤT!" -BackgroundColor DarkGreen
Write-Host "- Đã cài đặt Cốc Cốc"
Write-Host "- Đã xóa tự động update"
Write-Host "- Đã xóa CrashHandlers"
Write-Host "- Đã áp dụng registry optimizations"
Write-Host "`nTHÔNG BÁO: Để cập nhật Cốc Cốc khi cần, vui lòng:" -ForegroundColor Cyan -BackgroundColor DarkGreen
Write-Host "1. Mở PowerShell với quyền Administrator" -ForegroundColor White
Write-Host "2. Chạy lệnh sau: irm https://go.bibica.net/coccoc | iex" -ForegroundColor Yellow
Write-Host "3. Chờ quá trình cài đặt hoàn tất" -ForegroundColor White
