@echo off
setlocal enabledelayedexpansion

set "WIMLIB=%~dp0..\packages\WimLib\wimlib-imagex.exe"

echo WIM Info Editor
echo ================

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

echo.
echo Current WIM Info:
echo =================
"%WIMLIB%" info "!SOURCE!"

echo.
echo Select index to edit:
"%WIMLIB%" info "!SOURCE!" | findstr "Index:"
set /p "INDEX=Index: "

echo.
echo Current details for Index !INDEX!:
"%WIMLIB%" info "!SOURCE!" !INDEX!

echo.
echo [1] Rename image
echo [2] Set description  
echo [3] Both rename and description
set /p "ACTION=Choose (1-3): "

if "!ACTION!"=="1" goto :rename_only
if "!ACTION!"=="2" goto :desc_only
if "!ACTION!"=="3" goto :both
goto :end

:rename_only
set /p "NEW_NAME=New name: "
if "!NEW_NAME!"=="" goto :end

echo Renaming...
"%WIMLIB%" info "!SOURCE!" !INDEX! "!NEW_NAME!"
if !errorlevel! equ 0 (echo SUCCESS!) else (echo FAILED!)
goto :show_result

:desc_only
set /p "NEW_DESC=New description: "
if "!NEW_DESC!"=="" goto :end

echo Setting description...
"%WIMLIB%" info "!SOURCE!" !INDEX! "" "!NEW_DESC!"
if !errorlevel! equ 0 (echo SUCCESS!) else (echo FAILED!)
goto :show_result

:both
set /p "NEW_NAME=New name (leave empty to keep current): "
set /p "NEW_DESC=New description (leave empty to keep current): "

:: Check if both are empty
if "!NEW_NAME!"=="" if "!NEW_DESC!"=="" (
    echo No changes specified.
    goto :end
)

echo Updating name and description...

:: If NEW_NAME is empty, use empty string to keep current name
:: If NEW_DESC is empty, don't pass description parameter to keep current
if "!NEW_NAME!"=="" (
    if "!NEW_DESC!"=="" (
        echo No changes to apply.
        goto :end
    ) else (
        "%WIMLIB%" info "!SOURCE!" !INDEX! "" "!NEW_DESC!"
    )
) else (
    if "!NEW_DESC!"=="" (
        "%WIMLIB%" info "!SOURCE!" !INDEX! "!NEW_NAME!"
    ) else (
        "%WIMLIB%" info "!SOURCE!" !INDEX! "!NEW_NAME!" "!NEW_DESC!"
    )
)

if !errorlevel! equ 0 (echo SUCCESS!) else (echo FAILED!)
goto :show_result

:show_result
echo.
echo Updated WIM Info:
echo =================
"%WIMLIB%" info "!SOURCE!" !INDEX!

:end
echo.
pause 