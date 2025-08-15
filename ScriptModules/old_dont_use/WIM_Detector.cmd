@echo off
setlocal enabledelayedexpansion

:: ============================================================================
:: WIM Detector Module - Auto-detect WIM files in Image_Kitchen
:: ============================================================================
:: Usage: call "WIM_Detector.cmd" [RETURN_VAR_NAME]
:: Returns: Selected WIM file path in %RETURN_VAR_NAME%

set "WIM_FOLDER=%~dp0..\Image_Kitchen"
set "WIMLIB=%~dp0..\packages\WimLib\wimlib-imagex.exe"

:: Check if WIM folder exists
if not exist "%WIM_FOLDER%" (
    echo ERROR: Image_Kitchen directory not found!
    echo Expected location: %WIM_FOLDER%
    pause
    exit /b 1
)

:: Auto-detect WIMs
set "COUNT=0"
set "WIM_LIST="

:: Clear screen for clean UI
cls

echo ============================================================================
echo                    WIM File Detection
echo ============================================================================
echo WIM files detected at path: %WIM_FOLDER%
echo.

:: Scan for WIM files
for %%W in ("%WIM_FOLDER%\*.wim") do (
    if exist "%%W" (
        set /a "COUNT+=1"
        set "WIM[!COUNT!]=%%W"
        set "NAME[!COUNT!]=%%~nxW"
        set "WIM_LIST=!WIM_LIST![!COUNT!] %%~nxW"
        echo [!COUNT!] %%~nxW
    )
)

:: Check if any WIM files found
if !COUNT! equ 0 (
    echo No WIM files found in Image_Kitchen directory!
    echo.
    echo Please place your WIM files in: %WIM_FOLDER%
    pause
    exit /b 1
)

echo.
echo [0] Cancel
echo.
echo Total WIM files found: !COUNT!
echo.

:: Auto-select if only one WIM found
if !COUNT! equ 1 (
    set "SEL=1"
    echo Auto-selected: !NAME[1]!
) else (
    :: Multiple WIMs - ask user to select
    :SELECT_WIM
    set /p "SEL=Select WIM number (0-!COUNT!): "
    
    :: Validate input
    if "!SEL!"=="" goto :SELECT_WIM
    if !SEL! lss 0 goto :SELECT_WIM
    if !SEL! gtr !COUNT! goto :SELECT_WIM
    
    :: Check for cancel
    if !SEL! equ 0 (
        echo Operation cancelled by user.
        exit /b 1
    )
)

:: Get selected WIM info
call set "SELECTED_WIM=%%WIM[!SEL!]%%"
call set "SELECTED_NAME=%%NAME[!SEL!]%%"

echo.
echo Selected: !SELECTED_NAME!
echo Path: !SELECTED_WIM!
echo.

:: Show WIM info if wimlib is available
if exist "%WIMLIB%" (
    echo WIM Information:
    echo ================
    "%WIMLIB%" info "!SELECTED_WIM!" | findstr /C:"Boot Index:" /C:"Index:" /C:"Name:" /C:"Description:" /C:"Edition ID:" /C:"Build:" /C:"WIMBoot compatible:"
    echo.
)

:: Return the selected WIM path to calling script
if not "%~1"=="" (
    endlocal & set "%~1=%SELECTED_WIM%" & set "%~1_NAME=%SELECTED_NAME%"
)

exit /b 0 