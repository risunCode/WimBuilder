@echo off
setlocal enabledelayedexpansion

set "MOUNT_DIR=%~1"

echo [MODULE_W10] Registry Tweaks
echo.

:: Validate parameter
if "%MOUNT_DIR%"=="" (
    echo [ERROR] Mount directory parameter is missing!
    echo Usage: %~nx0 "mount_directory_path"
    exit /b 1
)

if not exist "%MOUNT_DIR%" (
    echo [ERROR] Mount directory does not exist: %MOUNT_DIR%
    exit /b 1
)

echo   - Loading registry hives...
set "SOFTWARE_LOADED=0"
set "DEFAULT_LOADED=0"
set "SYSTEM_LOADED=0"

reg load HKLM\MOUNTED_SOFTWARE "%MOUNT_DIR%\Windows\System32\config\SOFTWARE" >nul 2>&1
if !errorlevel! equ 0 (
    set "SOFTWARE_LOADED=1"
    echo     ^> SOFTWARE hive loaded successfully
) else (
    echo [PERINGATAN] Gagal load SOFTWARE hive
)

reg load HKLM\MOUNTED_DEFAULT "%MOUNT_DIR%\Users\Default\NTUSER.DAT" >nul 2>&1
if !errorlevel! equ 0 (
    set "DEFAULT_LOADED=1"
    echo     ^> DEFAULT hive loaded successfully
) else (
    echo [PERINGATAN] Gagal load DEFAULT hive
)

reg load HKLM\MOUNTED_SYSTEM "%MOUNT_DIR%\Windows\System32\config\SYSTEM" >nul 2>&1
if !errorlevel! equ 0 (
    set "SYSTEM_LOADED=1"
    echo     ^> SYSTEM hive loaded successfully
) else (
    echo [PERINGATAN] Gagal load SYSTEM hive
)

:: Check if any hive was loaded successfully
if !SOFTWARE_LOADED! equ 0 if !DEFAULT_LOADED! equ 0 if !SYSTEM_LOADED! equ 0 (
    echo [ERROR] Tidak dapat memuat registry hives yang diperlukan
    echo [INFO] Registry tweaks akan dilewati
    goto :skip_registry
)

echo.

set "REG_SUCCESS=0"
set "REG_FAILED=0"

:: ========================================
:: SOFTWARE HIVE TWEAKS
:: ========================================
echo   - SOFTWARE Hive Tweaks...

if !SOFTWARE_LOADED! equ 1 (
    echo     - Menghapus Folder Virtual dan Item Menu Klik-Kanan...
    reg delete "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg delete "HKLM\MOUNTED_SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{0DB7E03F-FC29-4DC6-9020-FF41B59E513A}" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg delete "HKLM\MOUNTED_SOFTWARE\Classes\*\shellex\ContextMenuHandlers\ModernSharing" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg delete "HKLM\MOUNTED_SOFTWARE\Classes\*\shellex\ContextMenuHandlers\Sharing" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Menghapus Outlook dan DevHome Update dari OOBE...
    reg query "HKLM\MOUNTED_SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" >nul 2>&1 && reg delete "HKLM\MOUNTED_SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\OutlookUpdate" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg query "HKLM\MOUNTED_SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" >nul 2>&1 && reg delete "HKLM\MOUNTED_SOFTWARE\Microsoft\WindowsUpdate\Orchestrator\UScheduler_Oobe\DevHomeUpdate" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Tweak Explorer dan Policies...
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" /v "SettingsPageVisibility" /t REG_SZ /d "hide:home" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Tweak OOBE, OneDrive, dan Windows Update...
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE" /v "BypassNRO" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\ReserveManager" /v "ShippedWithReserves" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Policies\Microsoft\Windows\OneDrive" /v "DisableFileSyncNGSC" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Menonaktifkan Outlook dan DevHome Updates...
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\OutlookUpdate" /v "workCompleted" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Orchestrator\UScheduler\DevHomeUpdate" /v "workCompleted" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Matikan ContentDeliveryManager untuk semua user baru...
    reg add "HKLM\MOUNTED_SOFTWARE\Policies\Microsoft\Windows\CloudContent" /v "DisableCloudOptimizedContent" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
)

echo     - SOFTWARE: %REG_SUCCESS% success, %REG_FAILED% failed

set "REG_SUCCESS=0"
set "REG_FAILED=0"

:: ========================================
:: DEFAULT HIVE TWEAKS
:: ========================================
echo   - DEFAULT Hive Tweaks...

if !DEFAULT_LOADED! equ 1 (
    echo     - Tweak Explorer dan Search...
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "LaunchTo" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "HideFileExt" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" /v "TaskbarDa" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Matikan ContentDeliveryManager untuk semua user baru...
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "OemPreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "ContentDeliveryAllowed" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "FeatureManagementEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "PreInstalledAppsEverEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SoftLandingEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContentEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-310093Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338388Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338389Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-338393Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353694Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SubscribedContent-353696Enabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" /v "SystemPaneSuggestionsEnabled" /t REG_DWORD /d 0 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    
    echo     - Menghapus Content Delivery Subscriptions...
    reg delete "HKLM\MOUNTED_DEFAULT\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager\Subscriptions" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
)

echo     - DEFAULT: %REG_SUCCESS% success, %REG_FAILED% failed

set "REG_SUCCESS=0"
set "REG_FAILED=0"

:: ========================================
:: SYSTEM HIVE TWEAKS
:: ========================================
echo   - SYSTEM Hive Tweaks...

if !SYSTEM_LOADED! equ 1 (
    echo     - Tweak BitLocker...
    reg add "HKLM\MOUNTED_SYSTEM\ControlSet001\Control\BitLocker" /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
    reg add "HKLM\MOUNTED_SYSTEM\ControlSet001\Control\BitLocker" /v "PreventDeviceEncryption" /t REG_DWORD /d 1 /f >nul 2>&1 && set /a "REG_SUCCESS+=1" || set /a "REG_FAILED+=1"
)

echo     - SYSTEM: %REG_SUCCESS% success, %REG_FAILED% failed

:skip_registry
echo   - Unloading registry hives...
if !SOFTWARE_LOADED! equ 1 (
    reg unload HKLM\MOUNTED_SOFTWARE >nul 2>&1
)
if !DEFAULT_LOADED! equ 1 (
    reg unload HKLM\MOUNTED_DEFAULT >nul 2>&1
)
if !SYSTEM_LOADED! equ 1 (
    reg unload HKLM\MOUNTED_SYSTEM >nul 2>&1
)

echo   Registry tweaks selesai.
echo.
exit /b 0 