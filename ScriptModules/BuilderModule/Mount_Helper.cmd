@echo off
:: Mount Helper Module - Centralized mount operations with registry cleanup
:: This module provides safe mount/unmount operations with proper registry cleanup

:: Function: Safe Mount Preparation
:: Usage: call :SAFE_MOUNT_PREP
:SAFE_MOUNT_PREP
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
goto :eof

:: Function: Safe Mount with Error Handling
:: Usage: call :SAFE_MOUNT "WIM_FILE" "INDEX" "MOUNT_DIR"
:SAFE_MOUNT
set "WIM_FILE=%~1"
set "WIM_INDEX=%~2"
set "MOUNT_PATH=%~3"

:: Prepare for mount
call :SAFE_MOUNT_PREP

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
        call :SAFE_MOUNT_PREP
        
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

:: Function: Safe Unmount with Error Handling
:: Usage: call :SAFE_UNMOUNT "MOUNT_DIR" "COMMIT_OR_DISCARD"
:SAFE_UNMOUNT
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

:: Function: Force Cleanup All
:: Usage: call :FORCE_CLEANUP_ALL
:FORCE_CLEANUP_ALL
echo   - Force cleaning all mount points and registry hives...
dism /Cleanup-Mountpoints >nul 2>&1

:: Unload all possible registry hives
reg unload HKLM\MOUNTED_SOFTWARE >nul 2>&1
reg unload HKLM\MOUNTED_DEFAULT >nul 2>&1
reg unload HKLM\MOUNTED_SYSTEM >nul 2>&1
reg unload HKLM\MOUNTED_SAM >nul 2>&1
reg unload HKLM\MOUNTED_SECURITY >nul 2>&1

:: Additional cleanup for any other mounted hives
for /f "tokens=*" %%h in ('reg query HKLM /f "MOUNTED_*" 2^>nul ^| findstr "MOUNTED_"') do (
    reg unload "%%h" >nul 2>&1
)

echo   - Force cleanup completed
goto :eof 