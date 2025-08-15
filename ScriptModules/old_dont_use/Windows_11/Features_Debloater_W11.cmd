@echo off
setlocal enabledelayedexpansion

set "MOUNT_DIR=%~1"
set "TEMP_FEATURES=%TEMP%\features_list.txt"
set "TEMP_CAPABILITIES=%TEMP%\capabilities_list.txt"
set "TEMP_APPX=%TEMP%\appx_packages.txt"

echo [MODULE] Features Debloater
echo.

:: Validate parameter
if "%MOUNT_DIR%"=="" (
    echo [ERROR] Mount directory parameter is missing!
    echo Usage: %~nx0 "mount_directory_path"
    exit /b 1
)

if not exist "%MOUNT_DIR%" (
    echo [ERROR] Mount directory does not exist: %MOUNT_DIR%
    exit /b 1
)

:: ============================================================================
:: Remove Windows Features
:: ============================================================================
echo [1/3] Removing Windows Features...
echo   - Scanning available features...

:: Get list of available features
dism /Image:"%MOUNT_DIR%" /Get-Features > "%TEMP_FEATURES%" 2>&1

:: Define features to remove
set "FEATURES=Printing-XPSServices-Features WindowsMediaPlayer SmbDirect MicrosoftWindowsPowerShellV2 MicrosoftWindowsPowerShellV2Root Internet-Explorer-Optional-amd64"

set "FEATURES_FOUND=0"
set "FEATURES_REMOVED=0"
set "FEATURES_SKIPPED=0"

:: Loop through features and check if they exist first
for %%F in (%FEATURES%) do (
    findstr /i "%%F" "%TEMP_FEATURES%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [FOUND] %%F
        set /a "FEATURES_FOUND+=1"
        dism /Image:"%MOUNT_DIR%" /Disable-Feature /FeatureName:"%%F" /Remove >nul 2>&1
        if !errorlevel! equ 0 (
            echo     ^> [SUCCESS] Feature berhasil dihapus
            set /a "FEATURES_REMOVED+=1"
        ) else (
            echo     ^> [FAILED] Gagal menghapus feature
        )
    ) else (
        echo   [SKIP] %%F - Tidak ditemukan
        set /a "FEATURES_SKIPPED+=1"
    )
)

echo.
echo   === Features Summary ===
echo   Ditemukan: !FEATURES_FOUND!
echo   Berhasil dihapus: !FEATURES_REMOVED!
echo   Dilewati: !FEATURES_SKIPPED!
echo.

:: ============================================================================
:: Remove Windows Capabilities
:: ============================================================================
echo [2/3] Removing Windows Capabilities...
echo   - Scanning available capabilities...

:: Get list of available capabilities
dism /Image:"%MOUNT_DIR%" /Get-Capabilities > "%TEMP_CAPABILITIES%" 2>&1

:: Define capabilities to remove
set "CAPABILITIES=App.StepsRecorder~~~~0.0.1.0 App.Support.QuickAssist~~~~0.0.1.0 Browser.InternetExplorer~~~~0.0.11.0 MathRecognizer~~~~0.0.1.0 Media.WindowsMediaPlayer~~~~0.0.12.0 Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0 Microsoft.WordPad~~~~0.0.1.0 OneCoreUAP.OneSync~~~~0.0.1.0"

set "CAPABILITIES_FOUND=0"
set "CAPABILITIES_REMOVED=0"
set "CAPABILITIES_SKIPPED=0"

:: Loop through capabilities and check if they exist first
for %%C in (%CAPABILITIES%) do (
    findstr /i "%%C" "%TEMP_CAPABILITIES%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [FOUND] %%C
        set /a "CAPABILITIES_FOUND+=1"
        dism /Image:"%MOUNT_DIR%" /Remove-Capability /CapabilityName:"%%C" >nul 2>&1
        if !errorlevel! equ 0 (
            echo     ^> [SUCCESS] Capability berhasil dihapus
            set /a "CAPABILITIES_REMOVED+=1"
        ) else (
            echo     ^> [FAILED] Gagal menghapus capability
        )
    ) else (
        echo   [SKIP] %%C - Tidak ditemukan
        set /a "CAPABILITIES_SKIPPED+=1"
    )
)

echo.
echo   === Capabilities Summary ===
echo   Ditemukan: !CAPABILITIES_FOUND!
echo   Berhasil dihapus: !CAPABILITIES_REMOVED!
echo   Dilewati: !CAPABILITIES_SKIPPED!
echo.

:: ============================================================================
:: Remove AppX Packages
:: ============================================================================
echo [3/3] Removing AppX Packages...
echo   - Scanning available AppX packages...

:: Get list of available AppX packages
dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages > "%TEMP_APPX%" 2>&1

:: Define AppX packages to remove (partial names for matching)
set "APPX=LinkedIn TikTok Facebook Netflix Instagram OneCalendar Amazon.com.Amazon LinkedInforWindows AmazonVideo.PrimeVideo Microsoft.Clipchamp Microsoft.BingNews Microsoft.People Microsoft.Todos MicrosoftTeams Microsoft.GamingApp Microsoft.YourPhone Microsoft.ZuneMusic Microsoft.ZuneVideo Microsoft.Getstarted Microsoft.BingWeather Microsoft.WindowsMaps Microsoft.QuickAssist Microsoft.Office.OneNote Microsoft.MicrosoftFamily Microsoft.OutlookForWindows Microsoft.WindowsFeedbackHub Microsoft.WindowsSoundRecorder Microsoft.MicrosoftOfficeHub Microsoft.PeopleExperienceHost Microsoft.PowerAutomateDesktop Microsoft.windowscommunicationsapps Microsoft.MicrosoftSolitaireCollection"

set "APPX_FOUND=0"
set "APPX_REMOVED=0" 
set "APPX_SKIPPED=0"

:: Process each AppX package
for %%P in (%APPX%) do (
    set "PACKAGE_FOUND=0"
    echo   Searching for: %%P
    
    REM Search for package and extract full name
    for /f "tokens=2* delims=:" %%A in ('findstr /i "PackageName.*%%P" "%TEMP_APPX%" 2^>nul') do (
        set "FULL_NAME=%%A"
        
        REM Remove leading/trailing spaces
        for /f "tokens=*" %%B in ("!FULL_NAME!") do set "FULL_NAME=%%B"
        
        if not "!FULL_NAME!"=="" (
            echo   [FOUND] %%P
            echo     Full name: !FULL_NAME!
            set /a "APPX_FOUND+=1"
            set "PACKAGE_FOUND=1"
            
            REM Remove the package
            echo     Attempting removal with DISM...
            dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:"!FULL_NAME!" >nul 2>&1
            set "DISM_ERROR=!errorlevel!"
            if !DISM_ERROR! equ 0 (
                echo     ^> [SUCCESS] Package berhasil dihapus
                set /a "APPX_REMOVED+=1"
            ) else (
                echo     ^> [FAILED] DISM gagal dengan error: !DISM_ERROR!
                echo     ^> [RETRY] Mencoba PowerShell method...
                
                REM Try PowerShell method as fallback
                powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $pkg = Get-AppxProvisionedPackage -Path '%MOUNT_DIR%' | Where-Object {$_.PackageName -eq '!FULL_NAME!'}; if ($pkg) { Remove-AppxProvisionedPackage -Path '%MOUNT_DIR%' -PackageName $pkg.PackageName -ErrorAction Stop; Write-Host '     > [SUCCESS] Berhasil dihapus via PowerShell' } else { Write-Host '     > [ERROR] Package tidak ditemukan di PowerShell' } } catch { Write-Host ('     > [FAILED] PowerShell error: ' + $_.Exception.Message) }" 2>nul
            )
        )
    )
    
    if "!PACKAGE_FOUND!"=="0" (
        echo   [SKIP] %%P - Tidak ditemukan
        set /a "APPX_SKIPPED+=1"
    )
)

echo.
echo   === AppX Summary ===
echo   Ditemukan: !APPX_FOUND!
echo   Berhasil dihapus: !APPX_REMOVED!
echo   Dilewati: !APPX_SKIPPED!
echo.

:: Cleanup temporary files
if exist "%TEMP_FEATURES%" del "%TEMP_FEATURES%"
if exist "%TEMP_CAPABILITIES%" del "%TEMP_CAPABILITIES%"
if exist "%TEMP_APPX%" del "%TEMP_APPX%"

echo [MODULE] Features Debloater selesai.
echo.
exit /b 0 