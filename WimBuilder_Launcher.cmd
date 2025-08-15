@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: Privilege Detection and Auto-Elevation
:: ============================================================================
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo Meminta hak Administrator...
    powershell -Command "Start-Process cmd -ArgumentList '/c, %~s0' -Verb RunAs"
    exit /b
)

:: ============================================================================
:: WimBuilder Launcher - Main Control Center
:: ============================================================================

:: Definisi path utama (centralized path management)
set "ROOT_DIR=%~dp0"
set "SCRIPT_DIR=%ROOT_DIR%ScriptModules\"
set "BUILDER_MODULE_DIR=%SCRIPT_DIR%BuilderModule\"
set "WIM_FOLDER=%ROOT_DIR%Image_Kitchen"
set "MOUNT_DIR=%ROOT_DIR%Image_Kitchen\TempMount"
set "WIMLIB=%ROOT_DIR%packages\WimLib\wimlib-imagex.exe"

:: AppX Dependencies (Shared untuk semua versi)
set "APPX_DEPENDENCIES_LTSC=%ROOT_DIR%App_LTSC\SharedDepedencies"
set "APPX_DEPENDENCIES_CONSUMER=%ROOT_DIR%App_LTSC\SharedDepedencies\Consumer"

:: AppX Packages untuk Consumer Version (Windows 10/11 Standard)
set "APPX_W10_CONSUMER=%ROOT_DIR%App_LTSC\Consumer_W10"
set "APPX_W11_CONSUMER=%ROOT_DIR%App_LTSC\Consumer_W11"

:: AppX Packages untuk LTSC Version (Windows 10/11 LTSC)
set "APPX_W10_LTSC=%ROOT_DIR%App_LTSC\LTSC_W10"
set "APPX_W11_LTSC=%ROOT_DIR%App_LTSC\LTSC_W11"

:: Target Modified (kosong secara default)
set "TARGET_WINDOWS_VER="
set "TARGET_WINDOWS_TYPE="
set "APPX_INJECT="

:: Check if ScriptModules directory exists
if not exist "%SCRIPT_DIR%" (
    echo ERROR: ScriptModules directory not found!
    echo Please ensure this launcher is in the correct WimBuilder directory.
    pause
    exit /b 1
)

:: Check if directories exist, create if needed
if not exist "%WIM_FOLDER%" (
    echo Creating WimSource directory...
    mkdir "%WIM_FOLDER%" >nul 2>&1
)
if not exist "%MOUNT_DIR%" (
    echo Creating TempMount directory...
    mkdir "%MOUNT_DIR%" >nul 2>&1
)

:: Check for wimlib
if not exist "%WIMLIB%" (
    echo WARNING: WimLib not found at "%WIMLIB%"
    echo Some functions may not work correctly.
    echo.
    pause
)

title WimBuilder Launcher - Main Control Center

:MAIN_MENU
cls
echo ============================================================================
echo                       WimBuilder Launcher v1.0
echo ============================================================================
echo.
echo  [1] WIM Builder (Windows 10/11/LTSC)
echo  [2] WIM Merge Tool
echo  [3] WIM Index Deletion Tool
echo  [4] WIM Info Editor
echo  [5] Check Mounted Directories
echo  [6] Exit
echo.
echo ============================================================================
echo.

set /p "CHOICE=Select an option (1-6): "

if "!CHOICE!"=="" (
    echo [ERROR] Please select an option!
    goto :MAIN_MENU
)

echo !CHOICE!| findstr /r "^[1-6]$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a number between 1-6!
    goto :MAIN_MENU
)

if "!CHOICE!"=="1" goto :BUILDER_MENU
if "!CHOICE!"=="2" goto :MERGE_TOOL
if "!CHOICE!"=="3" goto :DELETE_INDEX_TOOL
if "!CHOICE!"=="4" goto :INFO_EDITOR
if "!CHOICE!"=="5" goto :CHECK_MOUNTED
if "!CHOICE!"=="6" exit /b 0
goto :MAIN_MENU

:BUILDER_MENU
cls
echo ============================================================================
echo                       WIM Builder Selection
echo ============================================================================
echo.
echo  [1] Windows 10 Builder
echo  [2] Windows 11 Builder
echo  [3] Windows 10 LTSC Builder
echo  [4] Windows 11 LTSC Builder
echo  [5] Back to Main Menu
echo.
echo ============================================================================
echo.

set /p "BUILD_CHOICE=Select an option (1-5): "

if "!BUILD_CHOICE!"=="" (
    echo [ERROR] Please select an option!
    goto :BUILDER_MENU
)

echo !BUILD_CHOICE!| findstr /r "^[1-5]$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a number between 1-5!
    goto :BUILDER_MENU
)

if "!BUILD_CHOICE!"=="1" (
    set "TARGET_WINDOWS_VER=10"
    set "TARGET_WINDOWS_TYPE=Standard"
    set "APPX_INJECT=%APPX_W10_CONSUMER%"
    call :RUN_UNIFIED_BUILDER
    goto :MAIN_MENU
)
if "!BUILD_CHOICE!"=="2" (
    set "TARGET_WINDOWS_VER=11"
    set "TARGET_WINDOWS_TYPE=Standard"
    set "APPX_INJECT=%APPX_W11_CONSUMER%"
    call :RUN_UNIFIED_BUILDER
    goto :MAIN_MENU
)
if "!BUILD_CHOICE!"=="3" (
    set "TARGET_WINDOWS_VER=10"
    set "TARGET_WINDOWS_TYPE=LTSC"
    set "APPX_INJECT=%APPX_W10_LTSC%"
    call :RUN_UNIFIED_BUILDER
    goto :MAIN_MENU
)
if "!BUILD_CHOICE!"=="4" (
    set "TARGET_WINDOWS_VER=11"
    set "TARGET_WINDOWS_TYPE=LTSC"
    set "APPX_INJECT=%APPX_W11_LTSC%"
    call :RUN_UNIFIED_BUILDER
    goto :MAIN_MENU
)
if "!BUILD_CHOICE!"=="5" goto :MAIN_MENU
goto :BUILDER_MENU

:MERGE_TOOL
cls
echo Launching WIM Merge Tool...
call :RUN_MODULE "BuilderModule\Wim-Merge-Simple.cmd"
goto :MAIN_MENU

:DELETE_INDEX_TOOL
cls
echo Launching WIM Index Deletion Tool...
call :RUN_MODULE "BuilderModule\Wim-Delete-Index.cmd"
goto :MAIN_MENU

:INFO_EDITOR
cls
echo Launching WIM Info Editor...
call :RUN_MODULE "BuilderModule\WimInfo_Editor.cmd"
goto :MAIN_MENU

:CHECK_MOUNTED
cls
echo Launching CheckMounted Module...
call :RUN_MODULE "BuilderModule\CheckMounted.cmd"
goto :MAIN_MENU

:RUN_UNIFIED_BUILDER
:: Integrated unified builder with centralized path management
cls
echo ============================================================================
echo      Windows %TARGET_WINDOWS_VER% %TARGET_WINDOWS_TYPE% Tiny Builder
echo ============================================================================
echo.

:: 1. Select WIM file
echo [STEP 1/5] Select WIM file to process...
echo.
echo WIM files in: %WIM_FOLDER%
echo.

:: List WIM files
set "WIM_COUNT=0"
for %%W in ("%WIM_FOLDER%\*.wim") do (
    set /a "WIM_COUNT+=1"
    set "WIM[!WIM_COUNT!]=%%W"
    set "WIM_NAME[!WIM_COUNT!]=%%~nxW"
    echo [!WIM_COUNT!] %%~nxW
)

if !WIM_COUNT! equ 0 (
    echo No WIM files found in Image_Kitchen directory!
    echo Please place your WIM files in: %WIM_FOLDER%
    pause
    exit /b 1
)

echo.
echo [0] Cancel
echo.

:: Select WIM file
:WIM_SELECT_LOOP
set /p "WIM_SEL=Select WIM file (1-!WIM_COUNT!, 0 to cancel): "

if "!WIM_SEL!"=="" (
    echo [ERROR] Please enter a selection!
    goto :WIM_SELECT_LOOP
)

if "!WIM_SEL!"=="0" (
    echo Operation cancelled.
    exit /b 0
)

echo !WIM_SEL!| findstr /r "^[0-9]*$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a valid number!
    goto :WIM_SELECT_LOOP
)

if !WIM_SEL! lss 0 (
    echo [ERROR] Selection must be 0 or higher!
    goto :WIM_SELECT_LOOP
)

if !WIM_SEL! gtr !WIM_COUNT! (
    echo [ERROR] Selection must be at most !WIM_COUNT!
    goto :WIM_SELECT_LOOP
)

call set "WIM_SOURCE=%%WIM[%WIM_SEL%]%%"
call set "WIM_SOURCE_NAME=%%WIM_NAME[%WIM_SEL%]%%"

echo.
echo Selected: %WIM_SOURCE_NAME%
echo.

:: Get WIM index with validation and edition names
echo [INFO] Available Windows editions in this WIM:
dism /Get-WimInfo /WimFile:"%WIM_SOURCE%"
if !errorlevel! neq 0 (
    echo [ERROR] Invalid WIM file!
    pause
    exit /b 1
)

echo.
:WIM_INDEX_INPUT
set /p "WIM_INDEX=Enter WIM index: "

if "!WIM_INDEX!"=="" (
    echo [ERROR] WIM index required!
    goto :WIM_INDEX_INPUT
)

echo !WIM_INDEX!| findstr /r "^[0-9]*$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a valid number for WIM index!
    goto :WIM_INDEX_INPUT
)

if !WIM_INDEX! lss 1 (
    echo [ERROR] WIM index must be 1 or higher!
    goto :WIM_INDEX_INPUT
)

:: Get the actual number of images in the WIM by counting indices
set "MAX_INDEX=0"
for /f "tokens=2 delims=:" %%i in ('dism /Get-WimInfo /WimFile:"%WIM_SOURCE%" ^| findstr /c:"Index :"') do (
    set "CURRENT_INDEX=%%i"
    set "CURRENT_INDEX=!CURRENT_INDEX: =!"
    if !CURRENT_INDEX! gtr !MAX_INDEX! set "MAX_INDEX=!CURRENT_INDEX!"
)

if !WIM_INDEX! gtr !MAX_INDEX! (
    echo [ERROR] WIM index !WIM_INDEX! is out of range! Maximum index is !MAX_INDEX!.
    goto :WIM_INDEX_INPUT
)

:: Get the edition name for the selected index
for /f "tokens=2 delims=:" %%e in ('dism /Get-WimInfo /WimFile:"%WIM_SOURCE%" /Index:!WIM_INDEX! ^| findstr /c:"Name"') do (
    set "EDITION_NAME=%%e"
    set "EDITION_NAME=!EDITION_NAME: =!"
)

echo.
echo [INFO] Selected edition: !EDITION_NAME!
echo.

:: 2. Ask for backup option
echo [STEP 2/5] Backup Options...
echo.
echo [INFO] Creating a backup is recommended before modifying WIM files.
echo [INFO] Backup will be saved in: %WIM_FOLDER%\Backup\
echo.
set /p "CREATE_BACKUP=Do you want to create a backup? (Y/N, default: Y): "

if "!CREATE_BACKUP!"=="" set "CREATE_BACKUP=Y"

if /i "!CREATE_BACKUP!"=="Y" (
    echo   - Creating backup...
    call :CREATE_WIM_BACKUP "%WIM_SOURCE%" "%WIM_SOURCE_NAME%" "%WIM_INDEX%"
    if !errorlevel! neq 0 (
        echo [WARNING] Backup creation failed, but continuing...
        echo.
    ) else (
        echo   - Backup created successfully
        echo.
    )
) else (
    echo   - Skipping backup creation
    echo.
)

:: 3. Scan AppX packages (show what's available)
echo [STEP 3/5] Scanning AppX packages...
set "DEPS_COUNT=0"
set "APPS_COUNT=0"

:: Set appropriate dependencies folder based on Windows type
if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
    set "APPX_DEPENDENCIES=%APPX_DEPENDENCIES_LTSC%"
    set "DEPS_FOLDER_NAME=LTSC Shared Dependencies"
) else (
    set "APPX_DEPENDENCIES=%APPX_DEPENDENCIES_CONSUMER%"
    set "DEPS_FOLDER_NAME=Consumer Shared Dependencies"
)

if exist "%APPX_DEPENDENCIES%" (
    echo   - Scanning %DEPS_FOLDER_NAME% folder...
    for %%D in ("%APPX_DEPENDENCIES%\*.Appx" "%APPX_DEPENDENCIES%\*.Msix") do (
        if exist "%%D" (
            set /a "DEPS_COUNT+=1"
            echo     Found: %%~nxD
        )
    )
)

if exist "%APPX_INJECT%" (
    if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
        echo   - Scanning LTSC_W%TARGET_WINDOWS_VER% folder...
    ) else (
        echo   - Scanning Consumer_W%TARGET_WINDOWS_VER% folder...
    )
    for %%B in ("%APPX_INJECT%\*.Msixbundle" "%APPX_INJECT%\*.AppxBundle" "%APPX_INJECT%\*.Msix") do (
        if exist "%%B" (
            set /a "APPS_COUNT+=1"
            echo     Found: %%~nxB
        )
    )
)

echo.
echo   - Dependencies found: !DEPS_COUNT!
echo   - Apps found: !APPS_COUNT!

:: 4. Ask if user wants to inject AppX
set /a "TOTAL_PACKAGES=!DEPS_COUNT!+!APPS_COUNT!"
if !TOTAL_PACKAGES! gtr 0 (
    if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
        set /p "INJECT_APPX=Inject AppX packages? (Y/N, default: Y): "
    ) else (
        echo   [NOTE] Consumer versions typically have built-in AppX packages.
        echo   [NOTE] Only inject if you need additional apps not included by default.
        set /p "INJECT_APPX=Inject additional AppX packages? (Y/N, default: N): "
    )
    
    REM Trim spaces and set default if empty
    if "!INJECT_APPX!"=="" (
        if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
            set "INJECT_APPX=Y"
        ) else (
            set "INJECT_APPX=N"
        )
    )
    
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

:: 5. Ask for output filename
echo [STEP 4/5] Set output filename...
set /p "OUTPUT_NAME=Output filename (without .wim): "
if "%OUTPUT_NAME%"=="" (
    if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
        set "OUTPUT_NAME=install_tiny_w%TARGET_WINDOWS_VER%_ltsc"
    ) else (
        set "OUTPUT_NAME=install_tiny_w%TARGET_WINDOWS_VER%"
    )
)
echo Output will be saved as: %OUTPUT_NAME%.wim
echo.

:: 6. Mount image
echo [STEP 5/5] Mounting image...

:: Use safe mount function
call :SAFE_MOUNT "%WIM_SOURCE%" "%WIM_INDEX%" "%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [ERROR] Mount operation failed!
    pause
    exit /b 1
)

:: 7. Process image (features, registry, appx)
echo [STEP 6/6] Processing image...
echo   - Removing features...
call "%BUILDER_MODULE_DIR%Features_Debloater.cmd" "%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [WARNING] Features_Debloater module had issues, but continuing...
)

echo   - Applying registry tweaks...
call "%BUILDER_MODULE_DIR%Registry_Tweaks.cmd" "%MOUNT_DIR%"
if !errorlevel! neq 0 (
    echo [WARNING] Registry_Tweaks module had issues, but continuing...
)

if not defined SKIP_APPX (
    echo   - Injecting AppX packages...
    if exist "%APPX_DEPENDENCIES%" (
        echo   - Installing %DEPS_FOLDER_NAME%...
        for %%D in ("%APPX_DEPENDENCIES%\*.Appx" "%APPX_DEPENDENCIES%\*.Msix") do (
            if exist "%%D" (
                echo     Installing: %%~nxD
                dism /Image:"%MOUNT_DIR%" /Add-ProvisionedAppxPackage /PackagePath:"%%D" /SkipLicense >nul 2>&1
            )
        )
    )

    if exist "%APPX_INJECT%" (
        if "%TARGET_WINDOWS_TYPE%"=="LTSC" (
            echo   - Installing LTSC Apps...
        ) else (
            echo   - Installing Consumer Apps...
        )
        for %%B in ("%APPX_INJECT%\*.Msixbundle" "%APPX_INJECT%\*.AppxBundle" "%APPX_INJECT%\*.Msix") do (
            if exist "%%B" (
                echo     Installing: %%~nxB
                dism /Image:"%MOUNT_DIR%" /Add-ProvisionedAppxPackage /PackagePath:"%%B" /SkipLicense >nul 2>&1
            )
        )
    )
) else (
    echo   - Skipping AppX injection...
)

:: 8. Export
echo   - Committing and unmounting image...
call :SAFE_UNMOUNT "%MOUNT_DIR%" "COMMIT"
if !errorlevel! neq 0 (
    echo [ERROR] Unmount operation failed!
    pause
    exit /b 1
)

echo   - Creating final WIM file...
"%WIMLIB%" export "%WIM_SOURCE%" %WIM_INDEX% "%WIM_FOLDER%\%OUTPUT_NAME%.wim" --compress=lzx >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] WIM export failed! Check WimLib installation.
    pause
    exit /b 1
)

echo.
echo ============================================================================
echo      DONE! File: %OUTPUT_NAME%.wim
echo ============================================================================
pause
exit /b 0

:SAFE_MOUNT
:: Function: Safe Mount with Error Handling
:: Usage: call :SAFE_MOUNT "WIM_FILE" "INDEX" "MOUNT_DIR"
set "WIM_FILE=%~1"
set "WIM_INDEX=%~2"
set "MOUNT_PATH=%~3"

:: Prepare for mount
echo   - Preparing for safe mount operation...
echo   - Cleaning up previous mount points...
dism /Cleanup-Mountpoints >nul 2>&1

echo   - Unloading registry hives...
reg unload HKLM\MOUNTED_SOFTWARE >nul 2>&1
reg unload HKLM\MOUNTED_DEFAULT >nul 2>&1
reg unload HKLM\MOUNTED_SYSTEM >nul 2>&1
reg unload HKLM\MOUNTED_SAM >nul 2>&1
reg unload HKLM\MOUNTED_SECURITY >nul 2>&1

echo   - Registry hives unloaded successfully

:: Check if mount directory is already in use
if exist "%MOUNT_PATH%\Windows" (
    echo   - Unmounting previous image...
    dism /Unmount-Image /MountDir:"%MOUNT_PATH%" /Discard >nul 2>&1
)

:: Create mount directory if needed
if not exist "%MOUNT_PATH%" mkdir "%MOUNT_PATH%" >nul 2>&1

:: Mount image
echo   - Mounting image...
dism /Mount-Image /ImageFile:"%WIM_FILE%" /Index:%WIM_INDEX% /MountDir:"%MOUNT_PATH%" >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Mount failed! Error code: !errorlevel!
    
    :: Handle specific error codes
    if !errorlevel! equ -1052638937 (
        echo.
        echo This error usually means:
        echo - Mount directory is already in use
        echo - Previous mount was not properly unmounted
        echo.
        echo Attempting to clean up and retry...
        
        :: Force cleanup
        echo   - Force cleaning all mount points and registry hives...
        dism /Cleanup-Mountpoints >nul 2>&1
        
        :: Unload all possible registry hives
        reg unload HKLM\MOUNTED_SOFTWARE >nul 2>&1
        reg unload HKLM\MOUNTED_DEFAULT >nul 2>&1
        reg unload HKLM\MOUNTED_SYSTEM >nul 2>&1
        reg unload HKLM\MOUNTED_SAM >nul 2>&1
        reg unload HKLM\MOUNTED_SECURITY >nul 2>&1
        
        :: Force unmount
        dism /Unmount-Image /MountDir:"%MOUNT_PATH%" /Discard >nul 2>&1
        
        :: Wait a moment
        timeout /t 3 >nul
        
        :: Retry mount
        echo Retrying mount...
        dism /Mount-Image /ImageFile:"%WIM_FILE%" /Index:%WIM_INDEX% /MountDir:"%MOUNT_PATH%" >nul 2>&1
        if !errorlevel! neq 0 (
            echo [ERROR] Mount still failed after cleanup!
            echo Try restarting computer to clear all locks.
            exit /b 1
        )
        echo   - Mount successful after cleanup
    ) else (
        echo.
        echo Common fixes:
        echo - Run as Administrator  
        echo - Check if WIM file exists and index is valid
        echo - Ensure at least 10GB free disk space
        echo - Try: dism /Cleanup-Mountpoints
        exit /b 1
    )
) else (
    echo   - Mount successful
)
goto :eof

:SAFE_UNMOUNT
:: Function: Safe Unmount with Error Handling
:: Usage: call :SAFE_UNMOUNT "MOUNT_DIR" "COMMIT_OR_DISCARD"
set "MOUNT_PATH=%~1"
set "UNMOUNT_MODE=%~2"

if "%UNMOUNT_MODE%"=="" set "UNMOUNT_MODE=COMMIT"

echo   - Unmounting image (%UNMOUNT_MODE%)...
dism /Unmount-Image /MountDir:"%MOUNT_PATH%" /%UNMOUNT_MODE% >nul 2>&1
if !errorlevel! neq 0 (
    echo [ERROR] Unmount failed! Attempting discard...
    dism /Unmount-Image /MountDir:"%MOUNT_PATH%" /Discard >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Unmount completely failed!
        echo Manual cleanup may be required.
        exit /b 1
    )
    echo   - Unmounted with discard
) else (
    echo   - Unmounted successfully
)

:: Clean up registry hives after unmount
echo   - Cleaning up registry hives...
reg unload HKLM\MOUNTED_SOFTWARE >nul 2>&1
reg unload HKLM\MOUNTED_DEFAULT >nul 2>&1
reg unload HKLM\MOUNTED_SYSTEM >nul 2>&1
reg unload HKLM\MOUNTED_SAM >nul 2>&1
reg unload HKLM\MOUNTED_SECURITY >nul 2>&1
goto :eof

:CREATE_WIM_BACKUP
:: Function to create backup of WIM file before modification
:: Usage: call :CREATE_WIM_BACKUP "WIM_FILE_PATH" "WIM_FILE_NAME" "WIM_INDEX"
set "BACKUP_WIM_FILE=%~1"
set "BACKUP_WIM_NAME=%~2"
set "BACKUP_WIM_INDEX=%~3"

:: Create backup directory if it doesn't exist
set "BACKUP_DIR=%WIM_FOLDER%\Backup"
if not exist "%BACKUP_DIR%" (
    echo     Creating backup directory...
    mkdir "%BACKUP_DIR%" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Failed to create backup directory
        exit /b 1
    )
)

:: Generate backup filename with timestamp
for /f "tokens=1-3 delims=/ " %%a in ('date /t') do set "BACKUP_DATE=%%a%%b%%c"
for /f "tokens=1-2 delims=: " %%a in ('time /t') do set "BACKUP_TIME=%%a%%b"
set "BACKUP_TIME=!BACKUP_TIME: =0!"

:: Remove .wim extension from original name for backup
set "BACKUP_BASE_NAME=%BACKUP_WIM_NAME:.wim=%"
set "BACKUP_FILENAME=!BACKUP_BASE_NAME!_backup_!BACKUP_DATE!_!BACKUP_TIME!.wim"
set "BACKUP_FULL_PATH=%BACKUP_DIR%\!BACKUP_FILENAME!"

echo     Creating backup: !BACKUP_FILENAME!

:: Check available disk space (need at least the size of original WIM)
for %%A in ("%BACKUP_WIM_FILE%") do set "WIM_SIZE=%%~zA"
for %%A in ("%BACKUP_DIR%") do set "FREE_SPACE=%%~zA"

if !WIM_SIZE! gtr !FREE_SPACE! (
    echo [ERROR] Insufficient disk space for backup
    echo   Required: !WIM_SIZE! bytes
    echo   Available: !FREE_SPACE! bytes
    exit /b 1
)

:: Create backup using wimlib (faster and more reliable than copy)
if exist "%WIMLIB%" (
    echo     Using WimLib for backup...
    "%WIMLIB%" export "%BACKUP_WIM_FILE%" %BACKUP_WIM_INDEX% "!BACKUP_FULL_PATH!" --compress=lzx >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] WimLib backup failed, trying copy method...
        copy "%BACKUP_WIM_FILE%" "!BACKUP_FULL_PATH!" >nul 2>&1
        if !errorlevel! neq 0 (
            echo [ERROR] Backup creation failed
            exit /b 1
        )
    )
) else (
    echo     Using copy method for backup...
    copy "%BACKUP_WIM_FILE%" "!BACKUP_FULL_PATH!" >nul 2>&1
    if !errorlevel! neq 0 (
        echo [ERROR] Backup creation failed
        exit /b 1
    )
)

:: Verify backup was created successfully
if exist "!BACKUP_FULL_PATH!" (
    echo     Backup created successfully: !BACKUP_FILENAME!
    echo     Location: !BACKUP_FULL_PATH!
    exit /b 0
) else (
    echo [ERROR] Backup file not found after creation
    exit /b 1
)

:RUN_MODULE
:: Run module with error handling and pass all necessary variables
set "MODULE_SCRIPT=%SCRIPT_DIR%%~1"
if not exist "%MODULE_SCRIPT%" (
    echo ERROR: Module script not found: %~1
    echo Please check if the script exists in ScriptModules\
    pause
    exit /b 1
)

echo Running: %~1

:: Export all path variables so they're available to the module
setlocal
set "PATH_VARS_FILE=%TEMP%\wimbuilder_path_vars.cmd"

:: Create a temporary file with all path variables
echo @echo off > "%PATH_VARS_FILE%"
echo set "ROOT_DIR=%ROOT_DIR%" >> "%PATH_VARS_FILE%"
echo set "SCRIPT_DIR=%SCRIPT_DIR%" >> "%PATH_VARS_FILE%"
echo set "BUILDER_MODULE_DIR=%BUILDER_MODULE_DIR%" >> "%PATH_VARS_FILE%"
echo set "WIM_FOLDER=%WIM_FOLDER%" >> "%PATH_VARS_FILE%"
echo set "MOUNT_DIR=%MOUNT_DIR%" >> "%PATH_VARS_FILE%"
echo set "WIMLIB=%WIMLIB%" >> "%PATH_VARS_FILE%"
echo set "APPX_DEPENDENCIES_LTSC=%APPX_DEPENDENCIES_LTSC%" >> "%PATH_VARS_FILE%"
echo set "APPX_DEPENDENCIES_CONSUMER=%APPX_DEPENDENCIES_CONSUMER%" >> "%PATH_VARS_FILE%"
echo set "APPX_W10_CONSUMER=%APPX_W10_CONSUMER%" >> "%PATH_VARS_FILE%"
echo set "APPX_W11_CONSUMER=%APPX_W11_CONSUMER%" >> "%PATH_VARS_FILE%"
echo set "APPX_W10_LTSC=%APPX_W10_LTSC%" >> "%PATH_VARS_FILE%"
echo set "APPX_W11_LTSC=%APPX_W11_LTSC%" >> "%PATH_VARS_FILE%"
echo set "TARGET_WINDOWS_VER=%TARGET_WINDOWS_VER%" >> "%PATH_VARS_FILE%"
echo set "TARGET_WINDOWS_TYPE=%TARGET_WINDOWS_TYPE%" >> "%PATH_VARS_FILE%"
echo set "APPX_INJECT=%APPX_INJECT%" >> "%PATH_VARS_FILE%"

:: Call the module with the path variables
call "%PATH_VARS_FILE%" && call "%MODULE_SCRIPT%"
set "MODULE_ERROR=%errorlevel%"

:: Clean up
if exist "%PATH_VARS_FILE%" del "%PATH_VARS_FILE%"
endlocal & set "MODULE_ERROR=%MODULE_ERROR%"

if %MODULE_ERROR% neq 0 (
    echo.
    echo WARNING: Module script exited with error code %MODULE_ERROR%
    echo Returning to main menu...
    pause
)
exit /b 0 