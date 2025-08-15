@echo off
setlocal EnableDelayedExpansion

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

:: ============================================================================
:: CheckMounted Module - Mount Directory Manager
:: ============================================================================
:: This module checks for mounted WIM directories and provides options to
:: commit or discard changes

title CheckMounted - Mount Directory Manager

echo ============================================================================
echo                    CheckMounted - Mount Directory Manager
echo ============================================================================
echo.

:: Check if MOUNT_DIR is defined from launcher
if not defined MOUNT_DIR (
    echo [ERROR] MOUNT_DIR variable is not defined!
    echo   This variable should be set by WimBuilder_Launcher.cmd
    echo   Current working directory: %CD%
    echo.
    echo Attempting to detect mount directories...
    set "MOUNT_DIR=%CD%\Image_Kitchen\TempMount"
    echo Using default mount directory: %MOUNT_DIR%
    echo.
)

:: Initialize variables
set "MOUNT_COUNT=0"

echo [1/3] Scanning for mounted directories...

:: Check default mount directory
if exist "%MOUNT_DIR%\Windows" (
    echo   Found mounted: %MOUNT_DIR%
    set /a "MOUNT_COUNT+=1"
) else if exist "%MOUNT_DIR%" (
    echo   Found empty directory: %MOUNT_DIR%
) else (
    echo   Not found: %MOUNT_DIR%
)

:: Check for DISM mounted images
echo   Checking DISM mounted images...
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   Found DISM mount: !MOUNT_PATH!
        set /a "MOUNT_COUNT+=1"
    ) else if exist "!MOUNT_PATH!" (
        echo   Found empty DISM mount: !MOUNT_PATH!
    )
)

if %MOUNT_COUNT% equ 0 (
    echo   [INFO] No mounted directories found
    echo.
    pause
    exit /b 0
)

echo   Total mounted directories found: %MOUNT_COUNT%
echo.

:: Display mounted directories
echo [2/3] Mounted Directories:
echo   ==========================================
if exist "%MOUNT_DIR%\Windows" (
    echo   1: %MOUNT_DIR%
)
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   !MOUNT_COUNT!: !MOUNT_PATH!
    )
)
echo   ==========================================
echo.

:: Select mount directory
echo [3/3] Select action:
echo.
echo   [0] Exit without action
if exist "%MOUNT_DIR%\Windows" (
    echo   [1] Manage: %MOUNT_DIR%
)
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   [!MOUNT_COUNT!] Manage: !MOUNT_PATH!
    )
)
echo.

set /p "MOUNT_SEL=Select mounted directory index: "

if "%MOUNT_SEL%"=="0" (
    echo Operation cancelled.
    exit /b 0
)

:: Determine selected mount directory
set "SELECTED_MOUNT="
if "%MOUNT_SEL%"=="1" (
    if exist "%MOUNT_DIR%\Windows" (
        set "SELECTED_MOUNT=%MOUNT_DIR%"
    )
) else (
    :: For DISM mounts, find the corresponding one
    set "DISM_INDEX=1"
    for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
        set "MOUNT_PATH=%%M"
        set "MOUNT_PATH=!MOUNT_PATH: =!"
        if exist "!MOUNT_PATH!\Windows" (
            set /a "DISM_INDEX+=1"
            if !DISM_INDEX! equ %MOUNT_SEL% (
                set "SELECTED_MOUNT=!MOUNT_PATH!"
            )
        )
    )
)

if not defined SELECTED_MOUNT (
    echo [ERROR] Invalid selection or mount directory not found
    pause
    exit /b 1
)

echo.
echo Selected: %SELECTED_MOUNT%
echo.

:: Show mount action menu
:MOUNT_ACTION_MENU
cls
echo ============================================================================
echo                    Mount Directory Actions
echo ============================================================================
echo.
echo Selected Mount: %SELECTED_MOUNT%
echo.
echo Available Actions:
echo   [1] Commit Mount (save changes)
echo   [2] Discard Mount (no changes applied)
echo   [3] Show Mount Info
echo   [4] Force Cleanup All (emergency cleanup)
echo   [5] Back to mount selection
echo   [0] Exit
echo.
echo ============================================================================
echo.

set /p "ACTION_SEL=Select action (0-5): "

if "%ACTION_SEL%"=="0" (
    echo Exiting...
    exit /b 0
)
if "%ACTION_SEL%"=="1" goto :COMMIT_MOUNT
if "%ACTION_SEL%"=="2" goto :DISCARD_MOUNT
if "%ACTION_SEL%"=="3" goto :SHOW_MOUNT_INFO
if "%ACTION_SEL%"=="4" goto :FORCE_CLEANUP
if "%ACTION_SEL%"=="5" goto :RESTART
goto :MOUNT_ACTION_MENU

:COMMIT_MOUNT
echo.
echo [ACTION] Commit Mount - Save Changes
echo   Mount Directory: %SELECTED_MOUNT%
echo.
echo This will save all changes made to the mounted image.
echo.
set /p "CONFIRM_COMMIT=Are you sure you want to commit changes? (Y/N): "
if /i not "!CONFIRM_COMMIT!"=="Y" (
    echo Operation cancelled.
    goto :MOUNT_ACTION_MENU
)

echo.
echo Committing changes...
call "%BUILDER_MODULE_DIR%Mount_Helper.cmd"
call :SAFE_UNMOUNT "%SELECTED_MOUNT%" "COMMIT"

if !errorlevel! equ 0 (
    echo [SUCCESS] Changes committed successfully!
    echo   Mount directory has been unmounted and changes saved.
) else (
    echo [ERROR] Failed to commit changes!
    echo   Please check if the mount directory is still valid.
)

echo.
pause
goto :MOUNT_ACTION_MENU

:DISCARD_MOUNT
echo.
echo [ACTION] Discard Mount - No Changes Applied
echo   Mount Directory: %SELECTED_MOUNT%
echo.
echo This will discard all changes and unmount the image.
echo.
set /p "CONFIRM_DISCARD=Are you sure you want to discard changes? (Y/N): "
if /i not "!CONFIRM_DISCARD!"=="Y" (
    echo Operation cancelled.
    goto :MOUNT_ACTION_MENU
)

echo.
echo Discarding changes...
call "%BUILDER_MODULE_DIR%Mount_Helper.cmd"
call :SAFE_UNMOUNT "%SELECTED_MOUNT%" "DISCARD"

if !errorlevel! equ 0 (
    echo [SUCCESS] Changes discarded successfully!
    echo   Mount directory has been unmounted and changes discarded.
) else (
    echo [ERROR] Failed to discard changes!
    echo   Please check if the mount directory is still valid.
)

echo.
pause
goto :MOUNT_ACTION_MENU

:SHOW_MOUNT_INFO
echo.
echo [INFO] Mount Directory Information
echo   ==========================================
echo   Path: %SELECTED_MOUNT%
echo   Exists: %SELECTED_MOUNT%
echo.
echo   Directory Contents:
if exist "%SELECTED_MOUNT%\Windows" (
    echo   ✓ Windows directory found
    if exist "%SELECTED_MOUNT%\Windows\System32" (
        echo   ✓ System32 directory found
    ) else (
        echo   ✗ System32 directory not found
    )
    if exist "%SELECTED_MOUNT%\Users" (
        echo   ✓ Users directory found
    ) else (
        echo   ✗ Users directory not found
    )
) else (
    echo   ✗ Windows directory not found
)
echo.
echo   Disk Space:
for /f "tokens=3" %%S in ('dir "%SELECTED_MOUNT%" 2^>nul ^| findstr /i "bytes free"') do (
    echo   Free space: %%S
)
echo   ==========================================
echo.
pause
goto :MOUNT_ACTION_MENU

:FORCE_CLEANUP
echo.
echo [ACTION] Force Cleanup All - Emergency Cleanup
echo.
echo WARNING: This will force cleanup ALL mount points and registry hives!
echo This is an emergency operation that should only be used when normal
echo unmount operations fail.
echo.
set /p "CONFIRM_FORCE=Are you sure you want to force cleanup? (Y/N): "
if /i not "!CONFIRM_FORCE!"=="Y" (
    echo Operation cancelled.
    goto :MOUNT_ACTION_MENU
)

echo.
echo Performing force cleanup...
call "%BUILDER_MODULE_DIR%Mount_Helper.cmd"
call :FORCE_CLEANUP_ALL

if !errorlevel! equ 0 (
    echo [SUCCESS] Force cleanup completed successfully!
    echo   All mount points and registry hives have been cleaned up.
) else (
    echo [ERROR] Force cleanup failed!
    echo   Manual intervention may be required.
)

echo.
pause
goto :MOUNT_ACTION_MENU

:RESTART
cls
goto :START

:START
cls
goto :MAIN_MENU

:MAIN_MENU
cls
echo ============================================================================
echo                    CheckMounted - Mount Directory Manager
echo ============================================================================
echo.

:: Check if MOUNT_DIR is defined from launcher
if not defined MOUNT_DIR (
    echo [ERROR] MOUNT_DIR variable is not defined!
    echo   This variable should be set by WimBuilder_Launcher.cmd
    echo   Current working directory: %CD%
    echo.
    echo Attempting to detect mount directories...
    set "MOUNT_DIR=%CD%\Image_Kitchen\TempMount"
    echo Using default mount directory: %MOUNT_DIR%
    echo.
)

:: Initialize variables
set "MOUNT_COUNT=0"

echo [1/3] Scanning for mounted directories...

:: Check default mount directory
if exist "%MOUNT_DIR%\Windows" (
    echo   Found mounted: %MOUNT_DIR%
    set /a "MOUNT_COUNT+=1"
) else if exist "%MOUNT_DIR%" (
    echo   Found empty directory: %MOUNT_DIR%
) else (
    echo   Not found: %MOUNT_DIR%
)

:: Check for DISM mounted images
echo   Checking DISM mounted images...
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   Found DISM mount: !MOUNT_PATH!
        set /a "MOUNT_COUNT+=1"
    ) else if exist "!MOUNT_PATH!" (
        echo   Found empty DISM mount: !MOUNT_PATH!
    )
)

if %MOUNT_COUNT% equ 0 (
    echo   [INFO] No mounted directories found
    echo.
    pause
    exit /b 0
)

echo   Total mounted directories found: %MOUNT_COUNT%
echo.

:: Display mounted directories
echo [2/3] Mounted Directories:
echo   ==========================================
if exist "%MOUNT_DIR%\Windows" (
    echo   1: %MOUNT_DIR%
)
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   !MOUNT_COUNT!: !MOUNT_PATH!
    )
)
echo   ==========================================
echo.

:: Select mount directory
echo [3/3] Select action:
echo.
echo   [0] Exit without action
if exist "%MOUNT_DIR%\Windows" (
    echo   [1] Manage: %MOUNT_DIR%
)
for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
    set "MOUNT_PATH=%%M"
    set "MOUNT_PATH=!MOUNT_PATH: =!"
    if exist "!MOUNT_PATH!\Windows" (
        echo   [!MOUNT_COUNT!] Manage: !MOUNT_PATH!
    )
)
echo.

set /p "MOUNT_SEL=Select mounted directory index: "

if "%MOUNT_SEL%"=="0" (
    echo Operation cancelled.
    exit /b 0
)

:: Determine selected mount directory
set "SELECTED_MOUNT="
if "%MOUNT_SEL%"=="1" (
    if exist "%MOUNT_DIR%\Windows" (
        set "SELECTED_MOUNT=%MOUNT_DIR%"
    )
) else (
    :: For DISM mounts, find the corresponding one
    set "DISM_INDEX=1"
    for /f "tokens=2 delims=:" %%M in ('dism /Get-MountedWimInfo 2^>nul ^| findstr /i "Mount Dir"') do (
        set "MOUNT_PATH=%%M"
        set "MOUNT_PATH=!MOUNT_PATH: =!"
        if exist "!MOUNT_PATH!\Windows" (
            set /a "DISM_INDEX+=1"
            if !DISM_INDEX! equ %MOUNT_SEL% (
                set "SELECTED_MOUNT=!MOUNT_PATH!"
            )
        )
    )
)

if not defined SELECTED_MOUNT (
    echo [ERROR] Invalid selection or mount directory not found
    pause
    exit /b 1
)

echo.
echo Selected: %SELECTED_MOUNT%
echo.

:: Show mount action menu
goto :MOUNT_ACTION_MENU

:: ============================================================================
:: Helper Functions
:: ============================================================================

:show_help
echo.
echo CheckMounted Module - Mount Directory Manager
echo ============================================
echo.
echo This module helps you manage mounted WIM image directories.
echo.
echo Features:
echo   - Scan for mounted directories
echo   - List all detected mounts
echo   - Commit changes (save modifications)
echo   - Discard changes (no modifications applied)
echo   - Show mount information
echo.
echo The module will automatically detect:
echo   - Default mount directory (from launcher)
echo   - Directories with 'Mount' in the name
echo   - DISM mounted images
echo.
exit /b 0 