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

:: WIM Index Deletion Tool using DISM
:: Direct delete method (safer than mount-delete-commit)

echo.
echo ===== WIM INDEX DELETION TOOL =====
echo.

:: Quick checks
if not exist "%WIM_FOLDER%" (
    echo ERROR: WIM folder not found: %WIM_FOLDER%
    pause
    exit /b 1
)

:: Check if DISM is available
dism /? >nul 2>&1
if errorlevel 1 (
    echo ERROR: DISM not found or not working!
    echo Please ensure DISM is available in your system.
    pause
    exit /b 1
)

:: Initialize variables
set "SELECTED_WIM="
set "SELECTED_INDEX="

:SELECT_WIM_MENU
cls
echo ===== WIM INDEX DELETION TOOL =====
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
echo === OPTIONS ===
echo [S] Select WIM file and show indexes
echo [D] Delete selected index
echo [C] Force Cleanup All (emergency)
echo [X] Exit
echo.

set /p "CHOICE=Select option (S/D/C/X): "

if /i "!CHOICE!"=="S" goto :SELECT_WIM
if /i "!CHOICE!"=="D" goto :DELETE_INDEX
if /i "!CHOICE!"=="C" goto :FORCE_CLEANUP
if /i "!CHOICE!"=="X" exit /b 0
goto :SELECT_WIM_MENU

:SELECT_WIM
echo.

:WIM_SELECT_LOOP
set /p "WIM_SEL=Select WIM file (1-!WIM_COUNT!): "

if "!WIM_SEL!"=="" (
    echo [ERROR] Input cannot be empty!
    goto :WIM_SELECT_LOOP
)

echo !WIM_SEL!| findstr /r "^[0-9]*$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a valid number!
    goto :WIM_SELECT_LOOP
)

if !WIM_SEL! lss 1 (
    echo [ERROR] Selection must be at least 1!
    goto :WIM_SELECT_LOOP
)

if !WIM_SEL! gtr !WIM_COUNT! (
    echo [ERROR] Selection must be at most !WIM_COUNT!
    goto :WIM_SELECT_LOOP
)

call set "SELECTED_WIM=%%WIM[!WIM_SEL!]%%"
call set "SELECTED_WIM_NAME=%%WIM_NAME[!WIM_SEL!]%%"

echo.
echo === WIM FILE INFO ===
echo File: !SELECTED_WIM_NAME!
echo Path: !SELECTED_WIM!
echo.

:: Show available indexes
echo === AVAILABLE INDEXES ===
dism /get-wiminfo /wimfile:"!SELECTED_WIM!" | findstr /C:"Index:" /C:"Name:" /C:"Description:" /C:"Size:"
echo.

:: Count total indexes
set "TOTAL_INDEXES=0"
for /f "tokens=2 delims=:" %%i in ('dism /get-wiminfo /wimfile:"!SELECTED_WIM!" ^| findstr /C:"Index:"') do (
    set /a "TOTAL_INDEXES+=1"
)

if !TOTAL_INDEXES! leq 1 (
    echo WARNING: This WIM file has only 1 index!
    echo Deleting the last index will make the WIM file unusable.
    echo.
    set /p "CONTINUE_LAST=Are you sure you want to continue? (Y/N): "
    if /i not "!CONTINUE_LAST!"=="Y" (
        echo Operation cancelled.
        pause
        goto :SELECT_WIM_MENU
    )
)

:: Ask for index to delete
:INDEX_SELECT_LOOP
set /p "INDEX_SEL=Enter index number to delete: "

if "!INDEX_SEL!"=="" (
    echo [ERROR] Index number cannot be empty!
    goto :INDEX_SELECT_LOOP
)

echo !INDEX_SEL!| findstr /r "^[0-9]*$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a valid number!
    goto :INDEX_SELECT_LOOP
)

set "SELECTED_INDEX=!INDEX_SEL!"

:: Validate index exists
dism /get-wiminfo /wimfile:"!SELECTED_WIM!" | findstr /C:"Index: !SELECTED_INDEX!" >nul
if errorlevel 1 (
    echo [ERROR] Index !SELECTED_INDEX! not found in WIM file!
    goto :INDEX_SELECT_LOOP
)

echo.
echo ✓ WIM file and index selected for deletion
echo File: !SELECTED_WIM_NAME!
echo Index: !SELECTED_INDEX!
pause
goto :SELECT_WIM_MENU

:DELETE_INDEX
if not defined SELECTED_WIM (
    echo Please select a WIM file first (option S)
    pause
    goto :SELECT_WIM_MENU
)

if not defined SELECTED_INDEX (
    echo Please select an index first (option S)
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo === DELETE INDEX CONFIRMATION ===
echo.
echo WARNING: This will permanently delete the selected index!
echo.
echo File: !SELECTED_WIM_NAME!
echo Index: !SELECTED_INDEX!
echo.
echo This operation will:
echo 1. Delete the specified index from WIM file
echo 2. Update WIM file structure
echo 3. Cannot be undone!
echo.
set /p "CONFIRM=Are you sure you want to proceed? (Y/N): "

if /i not "!CONFIRM!"=="Y" (
    echo Operation cancelled.
    pause
    goto :SELECT_WIM_MENU
)

echo.
echo === STARTING DELETE OPERATION ===
echo.

:: Create backup first
echo [1/3] Creating backup...
set "BACKUP_FILE=!SELECTED_WIM!.backup_%date:~-4,4%%date:~-10,2%%date:~-7,2%_%time:~0,2%%time:~3,2%%time:~6,2%"
set "BACKUP_FILE=!BACKUP_FILE: =0!"
copy "!SELECTED_WIM!" "!BACKUP_FILE!" >nul
if errorlevel 1 (
    echo ERROR: Failed to create backup!
    pause
    goto :SELECT_WIM_MENU
)
echo ✓ Backup created: !BACKUP_FILE!

:: Delete index using DISM
echo.
echo [2/3] Deleting index !SELECTED_INDEX!...
dism /delete-image /imagefile:"!SELECTED_WIM!" /index:!SELECTED_INDEX!
if errorlevel 1 (
    echo ERROR: Failed to delete index!
    echo Backup is available at: !BACKUP_FILE!
    pause
    goto :SELECT_WIM_MENU
)
echo ✓ Index deleted successfully

:: Verify deletion
echo.
echo [3/3] Verifying deletion...
dism /get-wiminfo /wimfile:"!SELECTED_WIM!" | findstr /C:"Index: !SELECTED_INDEX!" >nul
if not errorlevel 1 (
    echo ERROR: Index still exists after deletion!
    echo Backup is available at: !BACKUP_FILE!
    pause
    goto :SELECT_WIM_MENU
)
echo ✓ Deletion verified successfully

echo.
echo ===== DELETE OPERATION COMPLETED =====
echo.
echo ✓ Index !SELECTED_INDEX! successfully deleted from !SELECTED_WIM_NAME!
echo ✓ Backup saved as: !BACKUP_FILE!
echo.
echo Updated WIM file information:
dism /get-wiminfo /wimfile:"!SELECTED_WIM!" | findstr /C:"Index:" /C:"Name:" /C:"Description:" /C:"Size:"
echo.

:: Reset selection
set "SELECTED_WIM="
set "SELECTED_INDEX="

echo 🎉 Index deletion successful!
echo.
set /p "CONTINUE=Press any key to continue..."
goto :SELECT_WIM_MENU

:FORCE_CLEANUP
echo.
echo === FORCE CLEANUP ALL ===
echo.
echo WARNING: This will force cleanup ALL mount points and registry hives!
echo This is an emergency operation that should only be used when normal
echo operations fail.
echo.
set /p "CONFIRM_FORCE=Are you sure you want to force cleanup? (Y/N): "
if /i not "!CONFIRM_FORCE!"=="Y" (
    echo Operation cancelled.
    pause
    goto :SELECT_WIM_MENU
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
goto :SELECT_WIM_MENU 