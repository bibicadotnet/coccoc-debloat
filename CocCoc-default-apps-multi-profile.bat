@echo off

:: ==============================================
:: CONFIGURATION SECTION - EDIT THESE VALUES
:: ==============================================
set "CHROMIUM_PATH=C:\Program Files\CocCoc\Browser\Application\browser.exe"
set "PROFILE_PATH=C:\Private\coccoc_lamviec"
set "BROWSER_NAME=CocCoc"
set "BROWSER_DESC=CocCoc with custom profile"

:: ==============================================
:: SYSTEM CHECKS
:: ==============================================
:: Check if running as administrator
net session >nul 2>&1
if %ERRORLEVEL% neq 0 (
    echo ERROR: This script requires administrator privileges.
    echo Please right-click and select "Run as administrator".
    pause
    exit /b 1
)

:: Check if Chromium exists
if not exist "%CHROMIUM_PATH%" (
    echo ERROR: Chromium not found at:
    echo "%CHROMIUM_PATH%"
    pause
    exit /b 1
)

:: Check if profile directory exists
if not exist "%PROFILE_PATH%" (
    echo WARNING: Profile directory doesn't exist:
    echo "%PROFILE_PATH%"
    echo Creating it now...
    mkdir "%PROFILE_PATH%"
)

:: ==============================================
:: REGISTRY CONFIGURATION
:: ==============================================
echo Configuring registry settings...

:: Clean up any existing settings first
reg delete "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%" /f >nul 2>&1
reg delete "HKLM\Software\Classes\%BROWSER_NAME%HTML" /f >nul 2>&1
reg delete "HKLM\Software\Classes\%BROWSER_NAME%URL" /f >nul 2>&1

:: Register browser capabilities
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%" /ve /d "%BROWSER_NAME%" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\DefaultIcon" /ve /d "\"%CHROMIUM_PATH%\"" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\shell\open\command" /ve /d "\"%CHROMIUM_PATH%\" --user-data-dir=\"%PROFILE_PATH%\" \"%%1\"" /f

:: Register file associations
reg add "HKLM\Software\Classes\%BROWSER_NAME%HTML" /ve /d "%BROWSER_NAME% Document" /f
reg add "HKLM\Software\Classes\%BROWSER_NAME%HTML\DefaultIcon" /ve /d "\"%CHROMIUM_PATH%\"" /f
reg add "HKLM\Software\Classes\%BROWSER_NAME%HTML\shell\open\command" /ve /d "\"%CHROMIUM_PATH%\" --user-data-dir=\"%PROFILE_PATH%\" \"%%1\"" /f

:: Register URL protocols
reg add "HKLM\Software\Classes\%BROWSER_NAME%URL" /ve /d "%BROWSER_NAME% URL" /f
reg add "HKLM\Software\Classes\%BROWSER_NAME%URL" /v "URL Protocol" /d "" /f
reg add "HKLM\Software\Classes\%BROWSER_NAME%URL\DefaultIcon" /ve /d "\"%CHROMIUM_PATH%\"" /f
reg add "HKLM\Software\Classes\%BROWSER_NAME%URL\shell\open\command" /ve /d "\"%CHROMIUM_PATH%\" --user-data-dir=\"%PROFILE_PATH%\" \"%%1\"" /f

:: Set capabilities
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities" /v "ApplicationName" /d "%BROWSER_NAME%" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities" /v "ApplicationDescription" /d "%BROWSER_DESC%" /f

:: File associations
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\FileAssociations" /v ".htm" /d "%BROWSER_NAME%HTML" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\FileAssociations" /v ".html" /d "%BROWSER_NAME%HTML" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\FileAssociations" /v ".pdf" /d "%BROWSER_NAME%HTML" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\FileAssociations" /v ".svg" /d "%BROWSER_NAME%HTML" /f

:: URL associations
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\URLAssociations" /v "http" /d "%BROWSER_NAME%URL" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\URLAssociations" /v "https" /d "%BROWSER_NAME%URL" /f
reg add "HKLM\Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities\URLAssociations" /v "ftp" /d "%BROWSER_NAME%URL" /f

:: Register with Windows
reg add "HKLM\Software\RegisteredApplications" /v "%BROWSER_NAME%" /d "Software\Clients\StartMenuInternet\%BROWSER_NAME%\Capabilities" /f

:: ==============================================
:: SET AS DEFAULT BROWSER
:: ==============================================
echo Setting %BROWSER_NAME% as default browser...

:: For Windows 10/11
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\http\UserChoice" /v "ProgId" /d "%BROWSER_NAME%URL" /f
reg add "HKCU\Software\Microsoft\Windows\Shell\Associations\UrlAssociations\https\UserChoice" /v "ProgId" /d "%BROWSER_NAME%URL" /f

:: Open default apps settings to verify
start "" "ms-settings:defaultapps"

:: ==============================================
:: COMPLETION
:: ==============================================
echo.
echo Configuration complete!
echo Please verify %BROWSER_NAME% is set as default in Windows Settings.
echo.
pause
