 @echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Windows 11 LTSC Tiny Builder - Clean Version (FIXED)
:: ============================================================================
set "SCRIPT_DIR=%~dp0..\"
set "MOUNT_DIR=%SCRIPT_DIR%Image_Kitchen\TempMount"
set "WIMLIB=%~dp0..\..\packages\WimLib\wimlib-imagex.exe"
set "AppXDepedencies=%~dp0..\..\App_LTSC\SharedDepedencies"
set "AppXInject=%~dp0..\..\App_LTSC\LTSC_W11"

echo ============================================================================
echo      Windows 11 LTSC Tiny Builder - Clean Version (FIXED)
echo ============================================================================
echo.

:: Use WIM Detector to get WIM file
echo [WIM DETECTION] Detecting WIM files...
call "%~dp0..\WIM_Detector.cmd" "WIM_SOURCE"
if !errorlevel! neq 0 (
    echo [ERROR] WIM detection failed!
    pause & exit /b 1
)

:: Get WIM info
set "WIM_SOURCE_NAME=!WIM_SOURCE_NAME!"

:: Debug: Check if WIM_SOURCE is set
echo [DEBUG] WIM_SOURCE value: "!WIM_SOURCE!"
echo [DEBUG] WIM_SOURCE_NAME value: "!WIM_SOURCE_NAME!"
echo.

:: Quick validation
if not exist "%WIMLIB%" (
    echo [ERROR] wimlib-imagex.exe not found!
    pause & exit /b 1
)

if not exist "%MOUNT_DIR%" mkdir "%MOUNT_DIR%" >nul 2>&1

:: Scan AppX packages
echo [INFO] Scanning AppX packages...
set "DEPS_COUNT=0"
set "APPS_COUNT=0"

if exist "%AppXDepedencies%" (
    echo   - Scanning Dependencies folder...
    for %%D in ("%AppXDepedencies%\*.Appx" "%AppXDepedencies%\*.Msix") do (
        if exist "%%D" (
            set /a "DEPS_COUNT+=1"
            echo     Found: %%~nxD
        )
    )
)

if exist "%AppXInject%" (
    echo   - Scanning LTSC_W11 folder...
    for %%B in ("%AppXInject%\*.Msixbundle" "%AppXInject%\*.AppxBundle" "%AppXInject%\*.Msix") do (
        if exist "%%B" (
            set /a "APPS_COUNT+=1"
            echo     Found: %%~nxB
        )
    )
)

echo.
echo   - Dependencies found: !DEPS_COUNT!
echo   - Apps found: !APPS_COUNT!

:: Ask if user wants to inject AppX
set /a "TOTAL_PACKAGES=!DEPS_COUNT!+!APPS_COUNT!"
if !TOTAL_PACKAGES! gtr 0 (
    set /p "INJECT_APPX=Inject AppX packages? (Y/N, default: Y): "
    
    REM Trim spaces and set default if empty
    if "!INJECT_APPX!"=="" set "INJECT_APPX=Y"
    
    REM Check for No/N responses (case insensitive)
    if /i "!INJECT_APPX!"=="N" (
        set "SKIP_APPX=1"
        echo   - AppX injection skipped
    ) else if /i "!INJECT_APPX!"=="NO" (
        set "SKIP_APPX=1"
        echo   - AppX injection skipped
    ) else (
        REM Default to inject for any other input (Y/Yes/other)
        echo   - AppX injection will proceed
    )
) else (
    set "SKIP_APPX=1"
    echo   - No AppX packages found, skipping injection
)
echo.

:: Get WIM index
dism /Get-WimInfo /WimFile:"!WIM_SOURCE!"
set /p "WIM_INDEX=Enter WIM index: "
echo.

:: Mount image
echo [1/5] Mounting image...
dism /Mount-Image /ImageFile:"!WIM_SOURCE!" /Index:%WIM_INDEX% /MountDir:"%MOUNT_DIR%" >nul || (
    echo [ERROR] Mount failed!
    pause & exit /b 1
)

:: Remove features
echo [2/5] Removing features...
call "%SCRIPT_DIR%ScriptModules\Features_Debloater_W11_LTSC.cmd" "%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [WARNING] Features_Debloater module had issues, but continuing...
)

:: Registry tweaks
echo [3/5] Applying registry tweaks...
call "%SCRIPT_DIR%ScriptModules\Registry_Tweaks_W11_LTSC.cmd" "%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [WARNING] Registry_Tweaks module had issues, but continuing...
)

:: Inject AppX packages
if not defined SKIP_APPX (
    echo [4/5] Injecting AppX packages...
    if exist "%AppXDepedencies%" (
        echo   - Installing Dependencies...
        for %%D in ("%AppXDepedencies%\*.Appx" "%AppXDepedencies%\*.Msix") do (
            if exist "%%D" (
                echo     Installing: %%~nxD
                dism /Image:"%MOUNT_DIR%" /Add-ProvisionedAppxPackage /PackagePath:"%%D" /SkipLicense >nul 2>&1
            )
        )
    )

    if exist "%AppXInject%" (
        echo   - Installing Apps...
        for %%B in ("%AppXInject%\*.Msixbundle" "%AppXInject%\*.AppxBundle" "%AppXInject%\*.Msix") do (
            if exist "%%B" (
                echo     Installing: %%~nxB
                dism /Image:"%MOUNT_DIR%" /Add-ProvisionedAppxPackage /PackagePath:"%%B" /SkipLicense >nul 2>&1
            )
        )
    )
) else (
    echo [4/5] Skipping AppX injection...
)

:: Export
echo [5/5] Exporting WIM...
set /p "OUTPUT_NAME=Output filename (without .wim): "
if "%OUTPUT_NAME%"=="" set "OUTPUT_NAME=install_tiny"

dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Commit >nul || (
    echo [ERROR] Commit failed!
    dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Discard >nul 2>&1
    pause & exit /b 1
)

"%WIMLIB%" export "!WIM_SOURCE!" %WIM_INDEX% "%SCRIPT_DIR%Image_Kitchen\%OUTPUT_NAME%.wim" --compress=lzx

echo.
echo ============================================================================
echo      DONE! File: %OUTPUT_NAME%.wim
echo ============================================================================
pause