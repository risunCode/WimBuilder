@echo off
setlocal enabledelayedexpansion

if not defined ROOT_DIR (
    echo [ERROR] Please launch script from WimBuilder launcher.
    pause
    exit /b 1
)

echo ===== MULTI-WIM MERGER =====

if not exist "%WIMLIB%" (echo ERROR: wimlib tidak ditemukan & pause & exit)
if not exist "%WIM_FOLDER%" (echo ERROR: Direktori tidak ditemukan & pause & exit)

:: Initialize arrays
for /L %%i in (1,1,100) do (
    set "SELECTED_WIMS[%%i]="
    set "SELECTED_NAMES[%%i]="
    set "SELECTED_DESCS[%%i]="
)
set "SELECTED_COUNT=0"

:SELECT_WIM_MENU
cls
echo ===== MULTI-WIM MERGER =====

if !SELECTED_COUNT! gtr 0 (
    echo === CURRENT SELECTION ===
    for /L %%i in (1,1,!SELECTED_COUNT!) do (
        echo [%%i] !SELECTED_NAMES[%%i]!
    )
    echo.
) else (
    echo No WIM files selected yet.
    echo.
)

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
    pause
    exit /b 1
)

echo.
echo === OPTIONS ===
echo [A] Add WIM file to selection
echo [R] Remove WIM file from selection
echo [M] Merge selected WIM files
echo [C] Clear all selections
echo [X] Exit
echo.

set /p "CHOICE=Select option (A/R/M/C/X): "

if /i "!CHOICE!"=="A" goto :ADD_WIM
if /i "!CHOICE!"=="R" goto :REMOVE_WIM
if /i "!CHOICE!"=="M" goto :MERGE_WIMS
if /i "!CHOICE!"=="C" goto :CLEAR_SELECTION
if /i "!CHOICE!"=="X" exit /b 0
goto :SELECT_WIM_MENU

:ADD_WIM
if !SELECTED_COUNT! gtr 0 (
    echo Current selection: !SELECTED_COUNT! WIM files
)
echo.

:WIM_SELECT_LOOP
set /p "WIM_SEL=Select WIM file to add (1-!WIM_COUNT!): "

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

for /L %%i in (1,1,!SELECTED_COUNT!) do (
    if "!SELECTED_WIMS[%%i]!"=="!SELECTED_WIM!" (
        echo WIM file already selected!
        pause
        goto :SELECT_WIM_MENU
    )
)

echo.
echo Info WIM file:
"%WIMLIB%" info "!SELECTED_WIM!" 2>nul | findstr /C:"Boot Index:" /C:"Index:" /C:"Name:" /C:"Description:" /C:"Edition ID:" /C:"Build:" /C:"WIMBoot compatible:"

:NAME_INPUT_LOOP
set /p "WIM_NAME=Name for this image: "
if "!WIM_NAME!"=="" (
    echo [ERROR] Name cannot be empty!
    goto :NAME_INPUT_LOOP
)

set /p "WIM_DESC=Description for this image: "

set /a "SELECTED_COUNT+=1"
set "SELECTED_WIMS[!SELECTED_COUNT!]=!SELECTED_WIM!"
set "SELECTED_NAMES[!SELECTED_COUNT!]=!WIM_NAME!"
set "SELECTED_DESCS[!SELECTED_COUNT!]=!WIM_DESC!"

echo ✓ Added: !WIM_NAME!
pause
goto :SELECT_WIM_MENU

:REMOVE_WIM
if !SELECTED_COUNT! equ 0 (
    echo No WIM files selected to remove.
    pause
    goto :SELECT_WIM_MENU
)

echo === REMOVE WIM FILE ===
for /L %%i in (1,1,!SELECTED_COUNT!) do (
    echo [%%i] !SELECTED_NAMES[%%i]!
)

:REMOVE_SELECT_LOOP
set /p "REMOVE_SEL=Select WIM file to remove (1-!SELECTED_COUNT!): "

if "!REMOVE_SEL!"=="" (
    echo [ERROR] Input cannot be empty!
    goto :REMOVE_SELECT_LOOP
)

echo !REMOVE_SEL!| findstr /r "^[0-9]*$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter a valid number!
    goto :REMOVE_SELECT_LOOP
)

if !REMOVE_SEL! lss 1 (
    echo [ERROR] Selection must be at least 1!
    goto :REMOVE_SELECT_LOOP
)

if !REMOVE_SEL! gtr !SELECTED_COUNT! (
    echo [ERROR] Selection must be at most !SELECTED_COUNT!
    goto :REMOVE_SELECT_LOOP
)

for /L %%i in (!REMOVE_SEL!,1,!SELECTED_COUNT!) do (
    set /a "NEXT=%%i+1"
    if !NEXT! leq !SELECTED_COUNT! (
        set "SELECTED_WIMS[%%i]=!SELECTED_WIMS[!NEXT!]!"
        set "SELECTED_NAMES[%%i]=!SELECTED_NAMES[!NEXT!]!"
        set "SELECTED_DESCS[%%i]=!SELECTED_DESCS[!NEXT!]!"
    )
)

set /a "SELECTED_COUNT-=1"
echo ✓ Removed WIM file from selection
pause
goto :SELECT_WIM_MENU

:CLEAR_SELECTION
for /L %%i in (1,1,100) do (
    set "SELECTED_WIMS[%%i]="
    set "SELECTED_NAMES[%%i]="
    set "SELECTED_DESCS[%%i]="
)
set "SELECTED_COUNT=0"
echo ✓ All selections cleared
pause
goto :SELECT_WIM_MENU

:MERGE_WIMS
if !SELECTED_COUNT! lss 2 (
    echo Need at least 2 WIM files to merge!
    echo Current selection: !SELECTED_COUNT! WIM files
    pause
    goto :SELECT_WIM_MENU
)

echo === MERGE CONFIGURATION ===
echo Selected WIM files (!SELECTED_COUNT!):
for /L %%i in (1,1,!SELECTED_COUNT!) do (
    echo [%%i] !SELECTED_NAMES[%%i]!
)

:OUTPUT_NAME_LOOP
set /p "OUTPUT_NAME=Output filename (without .wim): "
if "!OUTPUT_NAME!"=="" (
    echo [ERROR] Output filename cannot be empty!
    goto :OUTPUT_NAME_LOOP
)

echo Compression options:
echo [0] LZX - Universal, smaller files (default)
echo [1] XPRESS + WIMBoot - Modern only, larger files

:COMPRESS_LOOP
set /p "COMPRESS_CHOICE=Choice (0/1, default=0): "

if "!COMPRESS_CHOICE!"=="" set "COMPRESS_CHOICE=0"

echo !COMPRESS_CHOICE!| findstr /r "^[01]$" >nul
if !errorlevel! neq 0 (
    echo [ERROR] Please enter 0 or 1!
    goto :COMPRESS_LOOP
)

if "!COMPRESS_CHOICE!"=="1" (
    set "COMPRESS=--compress=XPRESS"
    set "WIMBOOT_FLAG=--wimboot"
    set "MODE=XPRESS + WIMBoot"
) else (
    set "COMPRESS=--compress=LZX"
    set "WIMBOOT_FLAG="
    set "MODE=LZX Universal"
)

echo ===== MERGE SUMMARY =====
echo WIM files to merge: !SELECTED_COUNT!
for /L %%i in (1,1,!SELECTED_COUNT!) do (
    echo   [%%i] !SELECTED_NAMES[%%i]!
)
echo Output: !OUTPUT_NAME!.wim
echo Mode: !MODE!

:CONFIRM_LOOP
set /p "CONFIRM=Proceed with merge? (Y/N): "

if "!CONFIRM!"=="" (
    echo [ERROR] Please enter Y or N!
    goto :CONFIRM_LOOP
)

if /i "!CONFIRM!"=="Y" goto :DO_MERGE
if /i "!CONFIRM!"=="N" (
    echo Merge cancelled
    pause
    goto :SELECT_WIM_MENU
)

echo [ERROR] Please enter Y or N!
goto :CONFIRM_LOOP

:DO_MERGE
echo === STARTING MERGE ===

echo [1/!SELECTED_COUNT!] Exporting first image...
"%WIMLIB%" export "!SELECTED_WIMS[1]!" 1 "%WIM_FOLDER%\!OUTPUT_NAME!.wim" "!SELECTED_NAMES[1]!" "!SELECTED_DESCS[1]!" !COMPRESS! !WIMBOOT_FLAG!
if errorlevel 1 (
    echo ERROR: Failed to export first image!
    pause
    goto :SELECT_WIM_MENU
)
echo ✓ Image 1 exported successfully

for /L %%i in (2,1,!SELECTED_COUNT!) do (
    echo [%%i/!SELECTED_COUNT!] Exporting image %%i...
    "%WIMLIB%" export "!SELECTED_WIMS[%%i]!" 1 "%WIM_FOLDER%\!OUTPUT_NAME!.wim" "!SELECTED_NAMES[%%i]!" "!SELECTED_DESCS[%%i]!" !COMPRESS! !WIMBOOT_FLAG!
    if errorlevel 1 (
        echo ERROR: Failed to export image %%i!
        pause
        goto :SELECT_WIM_MENU
    )
    echo ✓ Image %%i exported successfully
)

echo ===== MERGE COMPLETED =====
echo File created: !OUTPUT_NAME!.wim
echo Mode: !MODE!
echo.
echo WIM file information:
"%WIMLIB%" info "%WIM_FOLDER%\!OUTPUT_NAME!.wim"

if "!COMPRESS_CHOICE!"=="1" (
    echo === WIMBOOT VERIFICATION ===
    "%WIMLIB%" info "%WIM_FOLDER%\!OUTPUT_NAME!.wim" | findstr /C:"WIMBoot compatible.*yes" >nul 2>&1
    if errorlevel 1 (
        echo ⚠️ WARNING: WIMBoot may not be active
    ) else (
        echo ✅ SUCCESS: WIMBoot compatible
    )
)

echo 🎉 Merge successful! !SELECTED_COUNT! images combined.
pause
goto :SELECT_WIM_MENU