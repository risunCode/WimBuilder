@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Launcher Detection - Ensure script is run from WimBuilder
:: ============================================================================
if not defined ROOT_DIR (
    echo ============================================================================
    echo [ERROR] Please launch script from WimBuilder launcher.
    echo ============================================================================
    echo.
    echo This script module requires variables and paths that are set by
    echo WimBuilder_Launcher.cmd. Please run the launcher first.
    echo.
    pause
    exit /b 1
)

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
:: APPX PACKAGES REMOVAL (All Windows Versions)
:: ============================================================================
echo [1/3] Processing AppX Packages...
echo   - Scanning available AppX packages...

dism /Image:"%MOUNT_DIR%" /Get-ProvisionedAppxPackages > "%TEMP_APPX%" 2>&1

:: Define global AppX packages to remove (applies to all Windows versions)
set "GLOBAL_APPX=TikTok Facebook Netflix LinkedIn Instagram OneCalendar Amazon.com.Amazon AmazonVideo.PrimeVideo Clipchamp Microsoft.BingNews Microsoft.People Microsoft.Todos Microsoft.Teams Teams Microsoft.GamingApp Microsoft.YourPhone Microsoft.ZuneMusic Microsoft.ZuneVideo Microsoft.Getstarted Getstarted Microsoft.BingWeather Microsoft.WindowsMaps Microsoft.QuickAssist Microsoft.Office.OneNote Microsoft.MicrosoftFamily Microsoft.OutlookForWindows Microsoft.WindowsFeedbackHub Microsoft.WindowsSoundRecorder Microsoft.MicrosoftOfficeHub Microsoft.PeopleExperienceHost Microsoft.PowerAutomateDesktop Microsoft.windowscommunicationsapps Microsoft.MicrosoftSolitaireCollection MicrosoftFamily WindowsAlarms MicrosoftStickyNotes QuickAssist"
::XboxGamingOverlay
call :PROCESS_APPX_REMOVAL "%GLOBAL_APPX%" "%TEMP_APPX%"

:: ============================================================================
:: GLOBAL FEATURES REMOVAL (All Windows Versions)
:: ============================================================================
echo [2/3] Processing Windows Features...
echo   - Scanning available features...

dism /Image:"%MOUNT_DIR%" /Get-Features > "%TEMP_FEATURES%" 2>&1

:: Define global features to remove (applies to all Windows versions)
set "GLOBAL_FEATURES=Microsoft-Windows-TabletPCMath Printing-XPSServices-Features WindowsMediaPlayer SmbDirect MicrosoftWindowsPowerShellV2 MicrosoftWindowsPowerShellV2Root Internet-Explorer-Optional-amd64"

set "FEATURES_FOUND=0"
set "FEATURES_REMOVED=0"
set "FEATURES_SKIPPED=0"

:: Loop through features and check if they exist first
for %%F in (%GLOBAL_FEATURES%) do (
    echo   Checking for: %%F
    findstr /i "%%F" "%TEMP_FEATURES%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [FOUND] %%F
        set /a "FEATURES_FOUND+=1"
        dism /Image:"%MOUNT_DIR%" /Disable-Feature /FeatureName:"%%F" /Remove >nul 2>&1
        if !errorlevel! equ 0 (
            echo     ^> [SUCCESS] Feature berhasil disabled
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
:: GLOBAL CAPABILITIES REMOVAL (All Windows Versions)
:: ============================================================================
echo [3/3] Processing Windows Capabilities...
echo   - Scanning available capabilities...

dism /Image:"%MOUNT_DIR%" /Get-Capabilities > "%TEMP_CAPABILITIES%" 2>&1

:: Define global capabilities to remove (applies to all Windows versions)
set "GLOBAL_CAPABILITIES=App.StepsRecorder~~~~0.0.1.0 Browser.InternetExplorer~~~~0.0.11.0 App.Support.QuickAssist~~~~0.0.1.0 OneCoreUAP.OneSync~~~~0.0.1.0 MathRecognizer~~~~0.0.1.0 Media.WindowsMediaPlayer~~~~0.0.12.0 Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0 Microsoft.WordPad~~~~0.0.1.0"

:: Add Windows 11 specific capabilities
if "%TARGET_WINDOWS_VER%"=="11" (
    set "GLOBAL_CAPABILITIES=%GLOBAL_CAPABILITIES% Microsoft.Windows.SnippingTool~~~~0.0.1.0 Microsoft.Windows.Clipchamp~~~~0.0.1.0"
)

set "CAPABILITIES_FOUND=0"
set "CAPABILITIES_REMOVED=0"
set "CAPABILITIES_SKIPPED=0"

:: Loop through capabilities and check if they exist first
for %%C in (%GLOBAL_CAPABILITIES%) do (
    echo   Checking for: %%C
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

:: Cleanup temporary files
if exist "%TEMP_FEATURES%" del "%TEMP_FEATURES%"
if exist "%TEMP_CAPABILITIES%" del "%TEMP_CAPABILITIES%"
if exist "%TEMP_APPX%" del "%TEMP_APPX%"

echo [MODULE] Features Debloater selesai.
echo.
exit /b 0

:: ============================================================================
:: APPX PACKAGES PROCESSOR
:: ============================================================================
:PROCESS_APPX_REMOVAL
set "PACKAGES=%~1"
set "SCAN_FILE=%~2"

set "FOUND=0"
set "REMOVED=0"
set "SKIPPED=0"

for %%P in (%PACKAGES%) do (
    set "PACKAGE_FOUND=0"
    echo   Searching for: %%P

    rem Cari lebih fleksibel, tidak bergantung pada "PackageName.*"
    for /f "tokens=2* delims=:" %%A in ('findstr /i "%%P" "%SCAN_FILE%" 2^>nul') do (
        set "FULL_NAME=%%A"
        rem Hapus spasi di depan/ belakang
        for /f "tokens=* delims= " %%B in ("!FULL_NAME!") do set "FULL_NAME=%%B"
        
        if not "!FULL_NAME!"=="" (
            echo   [FOUND] %%P
            echo     Full name: !FULL_NAME!
            set /a "FOUND+=1"
            set "PACKAGE_FOUND=1"

            dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:"!FULL_NAME!" >nul 2>&1
            if !errorlevel! equ 0 (
                echo     ^> [SUCCESS] Package berhasil dihapus
                set /a "REMOVED+=1"
            ) else (
                echo     ^> [FAILED] Gagal menghapus package
            )
        )
    )

    if "!PACKAGE_FOUND!"=="0" (
        echo   [SKIP] %%P - Tidak ditemukan
        set /a "SKIPPED+=1"
    )
)

echo.
echo   === AppX Summary ===
echo   Ditemukan: !FOUND!
echo   Berhasil dihapus: !REMOVED!
echo   Dilewati: !SKIPPED!
echo.
exit /b 0