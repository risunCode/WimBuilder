@echo off
setlocal enabledelayedexpansion

set "MOUNT_DIR=%~dp0..\Image_Kitchen\TempMount"
set "WIMLIB=%~dp0..\packages\WimLib\wimlib-imagex.exe"

echo WIM Compressor - Simple Version
echo =================================

net session >nul || (echo Need Admin! & pause & exit /b 1)
if not exist "%WIMLIB%" (echo WimLib not found! & pause & exit /b 1)

:: Use WIM Detector to get WIM file
call "%~dp0WIM_Detector.cmd" "SOURCE"
if !errorlevel! neq 0 (
    echo WIM detection failed!
    pause
    exit /b 1
)

:: Get WIM info
set "SOURCE_NAME=!SOURCE_NAME!"

:: Show indexes and select
dism /Get-WimInfo /WimFile:"!SOURCE!" | findstr "Index\|Name"
set /p "INDEX=Index: "

:: Get output name
set /p "OUTPUT=Output name: "
if "%OUTPUT%"=="" set "OUTPUT=!SOURCE_NAME:~0,-4!_compressed"

:: Get original image info to preserve
echo Getting original image info...
for /f "tokens=*" %%a in ('dism /Get-WimInfo /WimFile:"!SOURCE!" /Index:!INDEX! ^| findstr "Name :"') do (
    for /f "tokens=2*" %%b in ("%%a") do set "ORIG_NAME=%%c"
)
for /f "tokens=*" %%a in ('dism /Get-WimInfo /WimFile:"!SOURCE!" /Index:!INDEX! ^| findstr "Description :"') do (
    for /f "tokens=2*" %%b in ("%%a") do set "ORIG_DESC=%%c"
)

:: Clean mount
dism /Get-MountedImageInfo | findstr /i "%MOUNT_DIR%" >nul
if !errorlevel! equ 0 dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Discard >nul
if exist "%MOUNT_DIR%" (
    rmdir /s /q "%MOUNT_DIR%" >nul 2>&1
    timeout /t 2 >nul
)
mkdir "%MOUNT_DIR%" >nul

echo.
echo Source: !SOURCE_NAME! (Index !INDEX!)
echo Output: %OUTPUT%.wim
echo Original Name: !ORIG_NAME!
echo.

:: Mount
echo Mounting...
dism /Mount-Image /ImageFile:"!SOURCE!" /Index:!INDEX! /MountDir:"%MOUNT_DIR%"
if !errorlevel! neq 0 (echo Mount failed! & pause & exit /b 1)

:: Capture with original image info
echo Capturing with LZX compression...
if defined ORIG_NAME (
    if defined ORIG_DESC (
        "%WIMLIB%" capture "%MOUNT_DIR%" "%~dp0..\Image_Kitchen\%OUTPUT%.wim" "!ORIG_NAME!" "!ORIG_DESC!" --compress=lzx --check
    ) else (
        "%WIMLIB%" capture "%MOUNT_DIR%" "%~dp0..\Image_Kitchen\%OUTPUT%.wim" "!ORIG_NAME!" --compress=lzx --check
    )
) else (
    "%WIMLIB%" capture "%MOUNT_DIR%" "%~dp0..\Image_Kitchen\%OUTPUT%.wim" --compress=lzx --check
)

set "RESULT=!errorlevel!"

:: Cleanup with force
echo Cleaning up mount...
dism /Unmount-Image /MountDir:"%MOUNT_DIR%" /Discard >nul
timeout /t 2 >nul
rmdir /s /q "%MOUNT_DIR%" >nul 2>&1

if !RESULT! equ 0 (
    echo.
    echo SUCCESS!
    
    :: Set proper permissions on output WIM
    echo Setting file permissions...
    icacls "%~dp0..\Image_Kitchen\%OUTPUT%.wim" /grant Administrators:F >nul 2>&1
    attrib -R "%~dp0..\Image_Kitchen\%OUTPUT%.wim" >nul 2>&1
    
    :: Simple file size check using dir
    echo Checking file sizes...
    for /f %%a in ('dir "!SOURCE!" ^| findstr /E "!SOURCE_NAME!" ^| findstr /O bytes') do (
        for /f "tokens=3" %%b in ("%%a") do (
            set "OLD_SIZE_STR=%%b"
            set "OLD_SIZE_STR=!OLD_SIZE_STR:,=!"
        )
    )
    
    for /f %%a in ('dir "%~dp0..\Image_Kitchen\%OUTPUT%.wim" ^| findstr /E "%OUTPUT%.wim" ^| findstr /O bytes') do (
        for /f "tokens=3" %%b in ("%%a") do (
            set "NEW_SIZE_STR=%%b"
            set "NEW_SIZE_STR=!NEW_SIZE_STR:,=!"
        )
    )
    
    echo Original: !OLD_SIZE_STR! bytes
    echo New: !NEW_SIZE_STR! bytes
    
    echo.
    echo [ARCHITECTURE CHECK] Verifying architecture preservation...
    "%WIMLIB%" info "%~dp0..\Image_Kitchen\%OUTPUT%.wim"
    
    echo.
    echo [FILE ACCESS] Setting WIM file permissions for modification...
    echo WIM file should now be modifiable like your original files.
) else (
    echo FAILED! Trying basic compression...
    "%WIMLIB%" capture "%MOUNT_DIR%" "%~dp0..\Image_Kitchen\%OUTPUT%.wim" --compress=lzx
    if !errorlevel! equ 0 (echo SUCCESS!) else (echo CAPTURE FAILED!)
)

pause 