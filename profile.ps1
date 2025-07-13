<#
.SYNOPSIS
    Tạo profile mới cho trình duyệt Cốc Cốc (mặc định tắt SplitView và SidePanel)
.DESCRIPTION
    Script tạo shortcut đơn giản trên Desktop
    - Hỗ trợ tên profile: chữ thường, hoa, số và dấu gạch dưới    
    - Hỗ trợ chọn đường dẫn chứa profile (có thể bỏ qua)
#>

# Fix encoding issues
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
chcp 65001 | Out-Null

#region -----[ INITIALIZATION ]-----
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "`n[!] VUI LONG CHAY BANG QUYEN ADMIN`n" -ForegroundColor Red
    pause
    exit
}

Clear-Host
Write-Host "`n====================================" -ForegroundColor Cyan
Write-Host "  TẠO PROFILE CỐC CỐC ĐƠN GIẢN" -ForegroundColor Green
Write-Host "====================================`n" -ForegroundColor Cyan
#endregion

#region -----[ MAIN FUNCTIONS ]-----
function Find-CocCoc {
    $paths = @(
        "$Env:ProgramFiles\CocCoc\Browser\Application\browser.exe",
        "$Env:ProgramFiles(x86)\CocCoc\Browser\Application\browser.exe"
    )
    
    foreach ($path in $paths) {
        if (Test-Path $path) {
            Write-Host "✔ Đã tìm thấy Cốc Cốc" -ForegroundColor Green
            return $path
        }
    }
    
    Write-Host "`n✖ KHÔNG TÌM THẤY CỐC CỐC!`n" -ForegroundColor Red
    pause
    exit
}

function New-CocCocProfile {
    param (
        [string]$browserPath
    )

    $defaultProfileBasePath = "$Env:LocalAppData\CocCoc\Browser\User Data"

    do {
        Write-Host "`n── NHẬP THÔNG TIN PROFILE ──" -ForegroundColor Cyan
        $profileName = Read-Host "Nhập tên profile (a-z, A-Z, 0-9, _)"
        
        if (-not $profileName) {
            Write-Host "❗ Tên không được để trống!" -ForegroundColor Red
            continue
        }

        if ($profileName -notmatch '^[A-Za-z0-9_]+$') {
            Write-Host "❗ Tên không hợp lệ! Chỉ dùng:" -ForegroundColor Red
            Write-Host "  - Chữ cái (a-z, A-Z)" -ForegroundColor Yellow
            Write-Host "  - Số (0-9)" -ForegroundColor Yellow
            Write-Host "  - Dấu gạch dưới (_)`n" -ForegroundColor Yellow
            continue
        }

        # Nhập và kiểm tra đường dẫn chứa profile
        do {
            $customBasePath = Read-Host "Nhập đường dẫn chứa profile (ấn Enter để bỏ qua)"

            if ([string]::IsNullOrWhiteSpace($customBasePath)) {
                $useCustomPath = $false
                $profileBasePath = $defaultProfileBasePath
                break
            }

            $customBasePath = $customBasePath.Trim()

            # Kiểm tra ký tự không hợp lệ
        	$folderName = Split-Path -Path $customBasePath -Leaf
        	if ($folderName -match '[<>:"/|?*\x00-\x1F]') {
        	    Write-Host "❗ Đường dẫn chứa ký tự không hợp lệ!" -ForegroundColor Red
        	    continue
        	}

            # Phải bắt đầu bằng ổ đĩa (C:\, D:\)
            if ($customBasePath -notmatch '^[a-zA-Z]:\\') {
                Write-Host "❗ Đường dẫn không hợp lệ! Phải có dạng ổ đĩa như C:\ hoặc D:\" -ForegroundColor Red
                continue
            }

            $profileBasePath = $customBasePath.TrimEnd('\')

            try {
                $testPath = Join-Path $profileBasePath "___testfolder_temp"
                New-Item -ItemType Directory -Path $testPath -Force -ErrorAction Stop | Out-Null
                Remove-Item -Path $testPath -Recurse -Force -ErrorAction SilentlyContinue
                $useCustomPath = $true
                break
            }
            catch {
                Write-Host "❗ Không thể ghi vào đường dẫn này! Vui lòng nhập lại." -ForegroundColor Red
            }
        } while ($true)

        $profileFolder = "coccoc_$profileName"
        $fullProfileDir = Join-Path $profileBasePath $profileFolder

        if (Test-Path $fullProfileDir) {
            Write-Host "`n⚠ PROFILE ĐÃ TỒN TẠI!" -ForegroundColor Yellow
            Write-Host "Đường dẫn: $fullProfileDir`n" -ForegroundColor White
            continue
        }

        # Tạo thư mục profile
        try {
            if (!(Test-Path $profileBasePath)) {
                New-Item -ItemType Directory -Path $profileBasePath -Force | Out-Null
                Write-Host "`n✔ Đã tạo thư mục chứa profile mới: $profileBasePath" -ForegroundColor Green
            }

            New-Item -ItemType Directory -Path $fullProfileDir -Force | Out-Null
            Write-Host "`n✔ Đã tạo profile thành công!" -ForegroundColor Green
            Write-Host "Đường dẫn: $fullProfileDir" -ForegroundColor White
        }
        catch {
            Write-Host "`n✖ LỖI KHI TẠO PROFILE!" -ForegroundColor Red
            Write-Host "Chi tiết: $($_.Exception.Message)`n" -ForegroundColor Yellow
            return $false
        }

        # Tạo shortcut
        try {
            $desktop = [Environment]::GetFolderPath('Desktop')
            $shortcutName = if ($useCustomPath) {
                "coccoc_custom_$profileName.lnk"
            } else {
                "coccoc_$profileName.lnk"
            }
            $shortcutPath = Join-Path $desktop $shortcutName

            $arguments = "--no-first-run --no-default-browser-check --disable-features=CocCocSplitView,SidePanel --profile-directory=`"$profileFolder`""
            if ($useCustomPath) {
                $escapedPath = $profileBasePath -replace '/', '\'
                $arguments += " --user-data-dir=`"$escapedPath\$profileFolder`""
            }

            $WshShell = New-Object -ComObject WScript.Shell
            $shortcut = $WshShell.CreateShortcut($shortcutPath)
            $shortcut.TargetPath = $browserPath
            $shortcut.Arguments = $arguments
            $shortcut.WorkingDirectory = Split-Path $browserPath
            $shortcut.IconLocation = "$browserPath, 0"
            $shortcut.Save()

            Write-Host "`n✔ Đã tạo shortcut trên Desktop!" -ForegroundColor Green
            Write-Host "Tên file: $shortcutName" -ForegroundColor White
            Write-Host "Vị trí: $desktop`n" -ForegroundColor White
        }
        catch {
            Write-Host "`n⚠ ĐÃ TẠO PROFILE NHƯNG LỖI KHI TẠO SHORTCUT!" -ForegroundColor Yellow
            Write-Host "Chi tiết: $($_.Exception.Message)`n" -ForegroundColor Yellow
        }

        return $true
    } while ($true)
}
#endregion

#region -----[ MAIN EXECUTION ]-----
$browserPath = Find-CocCoc

do {
    $success = New-CocCocProfile -browserPath $browserPath

do {
    Write-Host "`n───────────────────────────────" -ForegroundColor DarkGray
    $choice = Read-Host "Tạo profile khác? (y/n)"
    
    if ($choice -match '^[yYnN]$') {
        break
    }

    Write-Host "❗ Chỉ được nhập 'y' hoặc 'n'" -ForegroundColor Red
} while ($true)

if ($choice -in 'n','N') {
    Write-Host "`n✔ HOÀN TẤT`n" -ForegroundColor Green
    pause
    break
}


    Clear-Host
    Write-Host "`n====================================" -ForegroundColor Cyan
    Write-Host "  TẠO PROFILE MỚI" -ForegroundColor Green
    Write-Host "====================================`n" -ForegroundColor Cyan

} while ($true)
#endregion
