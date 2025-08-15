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
set "FEATURES=SnippingTool Printing-XPSServices-Features WindowsMediaPlayer SmbDirect MicrosoftWindowsPowerShellV2 MicrosoftWindowsPowerShellV2Root Internet-Explorer-Optional-amd64"

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
set "CAPABILITIES=Microsoft.Windows.SnippingTool~~~~0.0.1.0 App.StepsRecorder~~~~0.0.1.0 App.Support.QuickAssist~~~~0.0.1.0 Browser.InternetExplorer~~~~0.0.11.0 MathRecognizer~~~~0.0.1.0 Media.WindowsMediaPlayer~~~~0.0.12.0 Microsoft.Windows.PowerShell.ISE~~~~0.0.1.0 Microsoft.WordPad~~~~0.0.1.0 OneCoreUAP.OneSync~~~~0.0.1.0"

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

:: Define AppX packages to remove
set "APPX=SnippingTool LinkedIn TikTok Facebook Netflix Instagram OneCalendar Amazon.com.Amazon LinkedInforWindows AmazonVideo.PrimeVideo Microsoft.WindowsCalculator Microsoft.Clipchamp Microsoft.BingNews Microsoft.People Microsoft.Todos MicrosoftTeams Microsoft.GamingApp Microsoft.YourPhone Microsoft.ZuneMusic Microsoft.ZuneVideo Microsoft.Getstarted Microsoft.BingWeather Microsoft.WindowsMaps Microsoft.QuickAssist Microsoft.Office.OneNote Microsoft.MicrosoftFamily Microsoft.OutlookForWindows Microsoft.WindowsFeedbackHub Microsoft.WindowsSoundRecorder Microsoft.MicrosoftOfficeHub Microsoft.PeopleExperienceHost Microsoft.PowerAutomateDesktop Microsoft.windowscommunicationsapps Microsoft.MicrosoftSolitaireCollection"

set "APPX_FOUND=0"
set "APPX_REMOVED=0"
set "APPX_SKIPPED=0"

:: Loop through AppX packages and check if they exist first
for %%P in (%APPX%) do (
    findstr /i "PackageName.*%%P" "%TEMP_APPX%" >nul 2>&1
    if !errorlevel! equ 0 (
        echo   [FOUND] %%P
        set /a "APPX_FOUND+=1"
        dism /Image:"%MOUNT_DIR%" /Remove-ProvisionedAppxPackage /PackageName:"%%P" >nul 2>&1
        if !errorlevel! equ 0 (
            echo     ^> [SUCCESS] Package berhasil dihapus
            set /a "APPX_REMOVED+=1"
        ) else (
            echo     ^> [FAILED] Gagal menghapus package
        )
    ) else (
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

:: ============================================================================
:: Remove Legacy Executable Files (NSudo/Higher Mode)
:: ============================================================================
echo [4/4] Removing Legacy Executable Files...
echo   - Make sure you are running with NSUDO + Higher privileges

:: Define all files to delete (system files and user files combined)
set "ALL_FILES[0]=%MOUNT_DIR%\Windows\System32\SnippingTool.exe"
set "ALL_FILES[1]=%MOUNT_DIR%\Windows\System32\en-US\SnippingTool.exe.mui"
set "ALL_FILES[2]=%MOUNT_DIR%\Windows\SysWOW64\SnippingTool.exe"
set "ALL_FILES[3]=%MOUNT_DIR%\Windows\SysWOW64\en-US\SnippingTool.exe.mui"
set "ALL_FILES[4]=%MOUNT_DIR%\Windows\System32\calc.exe"
set "ALL_FILES[5]=%MOUNT_DIR%\Windows\SysWOW64\calc.exe"
set "ALL_FILES[6]=%MOUNT_DIR%\Windows\System32\en-US\calc.exe.mui"
set "ALL_FILES[7]=%MOUNT_DIR%\Windows\SysWOW64\en-US\calc.exe.mui"
set "ALL_FILES[8]=%MOUNT_DIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\SnippingTool.lnk"
set "ALL_FILES[9]=%MOUNT_DIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Accessories\Calculator.lnk"
set "ALL_FILES[10]=%MOUNT_DIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\SnippingTool.lnk"
set "ALL_FILES[11]=%MOUNT_DIR%\ProgramData\Microsoft\Windows\Start Menu\Programs\Calculator.lnk"
set "ALL_FILES[12]=%MOUNT_DIR%\Windows\System32\id-ID\calc.exe.mui"
set "ALL_FILES[13]=%MOUNT_DIR%\Windows\SysWOW64\id-ID\calc.exe.mui"
set "ALL_FILES[14]=%MOUNT_DIR%\Windows\System32\id-ID\SnippingTool.exe.mui"
set "ALL_FILES[15]=%MOUNT_DIR%\Windows\SysWOW64\id-ID\SnippingTool.exe.mui"

set "FILES_FOUND=0"
set "FILES_DELETED=0"
set "FILES_FAILED=0"

echo   - Processing files with Higher privileges...
echo.

:: Process all files directly (no permission handling needed)
for /L %%i in (0,1,21) do (
    call set "FILE=%%ALL_FILES[%%i]%%"
    if exist "!FILE!" (
        echo   - Deleting "!FILE!"
        set /a "FILES_FOUND+=1"
        
        :: Direct deletion with Higher privileges (via NSudo)
        del /f /q "!FILE!" >nul 2>&1
        
        :: Check if file still exists to determine success
        if exist "!FILE!" (
            echo     ^> [FAILED] Could not delete file
            set /a "FILES_FAILED+=1"
        ) else (
            echo     ^> [SUCCESS] File deleted successfully
            set /a "FILES_DELETED+=1"
        )
    ) else (
        echo   - Skip "!FILE!" (not found)
    )
)

echo.
echo   === File Deletion Summary ===
echo   Found: !FILES_FOUND!
echo   Deleted: !FILES_DELETED!
echo   Failed: !FILES_FAILED!
echo.

echo [MODULE] Features Debloater selesai.
echo.
exit /b 0