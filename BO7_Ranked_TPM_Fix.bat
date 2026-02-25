@echo off
setlocal EnableExtensions EnableDelayedExpansion
title BO7 Ranked - TPM Attestation Fix

:: ============================================================
::  BO7 Ranked - TPM Attestation Fix
::  Refactored workflow for readability and maintainability
:: ============================================================

call :InitColors
call :DrawHeader
call :RequireAdmin %*
if errorlevel 1 exit /b 0
call :CheckAttestation
if errorlevel 2 goto :Fatal
if errorlevel 1 goto :RepairNeeded
goto :Healthy

:Healthy
echo %GRN%[+] TPM attestation is already healthy.%RST%
echo %GRN%[+] No repair actions were required.%RST%
echo.
pause
exit /b 0

:RepairNeeded
echo %YLW%[!] Attestation is not ready. Running repair workflow...%RST%
echo.
call :PreparePaths
call :RestoreTpmTask "Tpm-Maintenance"
call :RestoreTpmTask "Tpm-HASCertRetr"
call :RestoreTpmTask "Tpm-PreAttestationHealthCheck"
call :RunMaintenanceTasks
echo.
echo %GRN%[+] Repair routine completed.%RST%
echo %WHT%Reboot your PC, then verify again with:%RST%
echo %YLW%tpmtool getdeviceinformation%RST%
echo.
pause
exit /b 0

:Fatal
echo.
pause
exit /b 1

:: -------------------------------
:: Setup + UX helpers
:: -------------------------------
:InitColors
set "ANSI=0"
for /f "delims=" %%A in ('powershell -NoProfile -Command "[char]27" 2^>nul') do set "ESC=%%A"
if defined ESC set "ANSI=1"

if "%ANSI%"=="1" (
    set "RST=%ESC%[0m"
    set "RED=%ESC%[91m"
    set "GRN=%ESC%[92m"
    set "YLW=%ESC%[93m"
    set "CYN=%ESC%[96m"
    set "WHT=%ESC%[97m"
) else (
    color 07
    set "RST="
    set "RED="
    set "GRN="
    set "YLW="
    set "CYN="
    set "WHT="
)
exit /b 0

:DrawHeader
cls
echo %CYN%============================================================%RST%
echo %WHT%   BO7 Ranked - TPM Attestation Fix%RST%
echo %CYN%============================================================%RST%
echo.
exit /b 0

:: -------------------------------
:: Privilege + checks
:: -------------------------------
:RequireAdmin
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo %YLW%[!] Administrator privileges are required.%RST%
    echo %CYN%[*] Requesting elevation...%RST%
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath 'cmd.exe' -ArgumentList '/c','\"%~f0\" --elevated' -Verb RunAs"
    exit /b 1
)
exit /b 0

:CheckAttestation
echo %CYN%[*] Checking TPM attestation status...%RST%
echo.

set "READY=False"
set "CAPABLE=False"
set "TPMTOOL_OK=0"

for /f "usebackq delims=" %%L in (`tpmtool getdeviceinformation 2^>nul`) do (
    set "LINE=%%L"
    set "TPMTOOL_OK=1"
    echo(!LINE! | findstr /i "Ready For Attestation: True" >nul && set "READY=True"
    echo(!LINE! | findstr /i "Is Capable For Attestation: True" >nul && set "CAPABLE=True"
)

if "%TPMTOOL_OK%"=="0" (
    echo %RED%[-] Failed to run tpmtool.%RST%
    echo %YLW%Run manually: tpmtool getdeviceinformation%RST%
    exit /b 2
)

if "%READY%"=="True" if "%CAPABLE%"=="True" exit /b 0
exit /b 1

:: -------------------------------
:: Repair workflow
:: -------------------------------
:PreparePaths
set "TMPDIR=C:\Temp"
set "SRCROOT=%WINDIR%\System32\Tasks\Microsoft\Windows\TPM"
set "TASKROOT=\Microsoft\Windows\TPM"

if not exist "%TMPDIR%" mkdir "%TMPDIR%" >nul 2>&1
exit /b 0

:RestoreTpmTask
set "TASK_NAME=%~1"
set "SOURCE_FILE=%SRCROOT%\%TASK_NAME%"
set "TASK_XML=%TMPDIR%\%TASK_NAME%.xml"
set "TASK_PATH=%TASKROOT%\%TASK_NAME%"

echo %CYN%[*] Restoring task:%RST% %WHT%%TASK_NAME%%RST%

if not exist "%SOURCE_FILE%" (
    echo %RED%[-] Source task file not found: %SOURCE_FILE%%RST%
    exit /b 0
)

copy /y "%SOURCE_FILE%" "%TASK_XML%" >nul 2>&1
schtasks /create /tn "%TASK_PATH%" /xml "%TASK_XML%" /f >nul 2>&1

if errorlevel 1 (
    echo %RED%[-] Failed to register %TASK_NAME%.%RST%
) else (
    echo %GRN%[+] Registered %TASK_NAME%.%RST%
)
exit /b 0

:RunMaintenanceTasks
echo.
echo %CYN%[*] Starting TPM maintenance tasks...%RST%
schtasks /run /tn "%TASKROOT%\Tpm-Maintenance" >nul 2>&1
schtasks /run /tn "%TASKROOT%\Tpm-HASCertRetr" >nul 2>&1
exit /b 0
