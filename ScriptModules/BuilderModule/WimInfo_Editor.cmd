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

:: WIM Info Editor Module - Optimized for Launcher Integration
:: Path akan diteruskan dari launcher utama

echo.
echo ===== WIM INFO EDITOR - Module Version =====
echo.

:: Quick validation
if not exist "%WIMLIB%" (
    echo ERROR: wimlib tidak ditemukan di: %WIMLIB%
    echo Please ensure WimLib is properly installed.
    pause
    exit /b 1
)

if not exist "%WIM_FOLDER%" (
    echo ERROR: WIM folder tidak ditemukan: %WIM_FOLDER%
    echo Please ensure the WIM folder exists.
    pause
    exit /b 1
)

:SELECT_WIM_MENU
cls
echo ===== WIM INFO EDITOR =====
echo.

:: List available WIM files
echo === AVAILABLE WIM FILES ===
echo WIM files in: %WIM_FOLDER%
echo.

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
echo [0] Back to Main Menu
echo.

:: Select WIM file
set /p "WIM_SEL=Select WIM file to edit (1-!WIM_COUNT!, 0 to cancel): "
if "%WIM_SEL%"=="0" (
    echo Returning to main menu...
    exit /b 0
)

if !WIM_SEL! lss 1 (
    echo Invalid selection.
    pause
    goto :SELECT_WIM_MENU
)

if !WIM_SEL! gtr !WIM_COUNT! (
    echo Invalid selection.
    pause
    goto :SELECT_WIM_MENU
)

call set "SELECTED_WIM=%%WIM[%WIM_SEL%]%%"
call set "SELECTED_WIM_NAME=%%WIM_NAME[%WIM_SEL%]%%"

echo.
echo Selected: %SELECTED_WIM_NAME%
echo.

:: Show current WIM info
echo === CURRENT WIM INFORMATION ===
"%WIMLIB%" info "!SELECTED_WIM!"
echo.

:: Show available indices
echo === AVAILABLE INDICES ===
"%WIMLIB%" info "!SELECTED_WIM!" | findstr "Index:"
echo.

:: Select index to edit
set /p "INDEX=Select index to edit: "
if "%INDEX%"=="" (
    echo No index selected.
    pause
    goto :SELECT_WIM_MENU
)

:: Validate index exists
"%WIMLIB%" info "!SELECTED_WIM!" !INDEX! >nul 2>&1
if !errorlevel! neq 0 (
    echo Invalid index: !INDEX!
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo === CURRENT DETAILS FOR INDEX !INDEX! ===
"%WIMLIB%" info "!SELECTED_WIM!" !INDEX!
echo.

:: Show edit options
echo === EDIT OPTIONS ===
echo [1] Rename image only
echo [2] Set description only  
echo [3] Both rename and description
echo [4] Back to WIM selection
echo.

set /p "ACTION=Choose option (1-4): "

if "!ACTION!"=="1" goto :RENAME_ONLY
if "!ACTION!"=="2" goto :DESC_ONLY
if "!ACTION!"=="3" goto :BOTH_EDIT
if "!ACTION!"=="4" goto :SELECT_WIM_MENU
goto :SELECT_WIM_MENU

:RENAME_ONLY
echo.
echo === RENAME IMAGE ===
set /p "NEW_NAME=New name for index !INDEX!: "
if "!NEW_NAME!"=="" (
    echo No name provided. Cancelling...
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo Renaming index !INDEX! to: !NEW_NAME!
"%WIMLIB%" info "!SELECTED_WIM!" !INDEX! "!NEW_NAME!"
if !errorlevel! equ 0 (
    echo ✓ SUCCESS: Image renamed successfully!
) else (
    echo ✗ FAILED: Could not rename image
)
goto :SHOW_RESULT

:DESC_ONLY
echo.
echo === SET DESCRIPTION ===
set /p "NEW_DESC=New description for index !INDEX!: "
if "!NEW_DESC!"=="" (
    echo No description provided. Cancelling...
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo Setting description for index !INDEX!...
"%WIMLIB%" info "!SELECTED_WIM!" !INDEX! "" "!NEW_DESC!"
if !errorlevel! equ 0 (
    echo ✓ SUCCESS: Description updated successfully!
) else (
    echo ✗ FAILED: Could not update description
)
goto :SHOW_RESULT

:BOTH_EDIT
echo.
echo === EDIT BOTH NAME AND DESCRIPTION ===
set /p "NEW_NAME=New name for index !INDEX! (leave empty to keep current): "
set /p "NEW_DESC=New description for index !INDEX! (leave empty to keep current): "

:: Check if both are empty
if "!NEW_NAME!"=="" if "!NEW_DESC!"=="" (
    echo No changes specified. Cancelling...
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo Updating index !INDEX!...

:: Handle different combinations of empty/non-empty values
if "!NEW_NAME!"=="" (
    if "!NEW_DESC!"=="" (
        echo No changes to apply.
        pause
        goto :SELECT_WIM_MENU
    ) else (
        echo Setting description only...
        "%WIMLIB%" info "!SELECTED_WIM!" !INDEX! "" "!NEW_DESC!"
    )
) else (
    if "!NEW_DESC!"=="" (
        echo Setting name only...
        "%WIMLIB%" info "!SELECTED_WIM!" !INDEX! "!NEW_NAME!"
    ) else (
        echo Setting both name and description...
        "%WIMLIB%" info "!SELECTED_WIM!" !INDEX! "!NEW_NAME!" "!NEW_DESC!"
    )
)

if !errorlevel! equ 0 (
    echo ✓ SUCCESS: Changes applied successfully!
) else (
    echo ✗ FAILED: Could not apply changes
)

:SHOW_RESULT
echo.
echo === UPDATED WIM INFORMATION ===
"%WIMLIB%" info "!SELECTED_WIM!" !INDEX!
echo.
echo === FULL WIM OVERVIEW ===
"%WIMLIB%" info "!SELECTED_WIM!"
echo.

set /p "CONTINUE=Press any key to continue..."
goto :SELECT_WIM_MENU 