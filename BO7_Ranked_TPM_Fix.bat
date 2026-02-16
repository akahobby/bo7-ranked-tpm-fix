@echo off
setlocal EnableExtensions EnableDelayedExpansion
title BO7 Ranked - TPM Attestation Fix

:: ============================================================
::  BO7 Ranked - TPM Attestation Fix
::  Developer: @akahobby
:: ============================================================

:: -------------------------------
:: Reliable Admin Elevation
:: -------------------------------
net session >nul 2>&1
if %errorlevel% neq 0 (
    echo.
    echo [!] Requesting Administrator privileges...
    powershell -NoProfile -ExecutionPolicy Bypass -Command ^
      "Start-Process -FilePath 'cmd.exe' -ArgumentList '/k','\"%~f0\" --elevated' -Verb RunAs"
    exit /b
)

:: -------------------------------
:: ANSI Color Setup (with fallback)
:: -------------------------------
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

cls
echo %CYN%============================================================%RST%
echo %WHT%   BO7 Ranked - TPM Attestation Fix%RST%
echo %CYN%============================================================%RST%
echo.

:: -------------------------------
:: Check TPM Attestation
:: -------------------------------
echo %CYN%[*] Checking TPM Attestation Status...%RST%
echo.

set "READY=False"
set "CAPABLE=False"
set "TPMTOOL_OK=0"

for /f "usebackq delims=" %%L in (`tpmtool getdeviceinformation 2^>nul`) do (
    set "LINE=%%L"
    set "TPMTOOL_OK=1"

    echo(!LINE! | findstr /i "Ready For Attestation: True" >nul && set READY=True
    echo(!LINE! | findstr /i "Is Capable For Attestation: True" >nul && set CAPABLE=True
)

if "%TPMTOOL_OK%"=="0" (
    echo %RED%[-] Failed to run tpmtool.%RST%
    echo %YLW%Run manually: tpmtool getdeviceinformation%RST%
    echo.
    pause
    exit /b 1
)

if "%READY%"=="True" if "%CAPABLE%"=="True" (
    echo %GRN%[+] TPM Attestation is healthy.%RST%
    echo %GRN%[+] No repair needed.%RST%
    echo.
    pause
    exit /b 0
)

echo %YLW%[!] Attestation not ready. Starting repair...%RST%
echo.

:: -------------------------------
:: Paths
:: -------------------------------
set "TMPDIR=C:\Temp"
set "SRCROOT=%WINDIR%\System32\Tasks\Microsoft\Windows\TPM"
set "TASKROOT=\Microsoft\Windows\TPM"

if not exist "%TMPDIR%" mkdir "%TMPDIR%" >nul 2>&1

call :RestoreTask "Tpm-Maintenance"
call :RestoreTask "Tpm-HASCertRetr"
call :RestoreTask "Tpm-PreAttestationHealthCheck"

echo.
echo %CYN%[*] Running TPM maintenance tasks...%RST%
schtasks /run /tn "%TASKROOT%\Tpm-Maintenance" >nul 2>&1
schtasks /run /tn "%TASKROOT%\Tpm-HASCertRetr" >nul 2>&1

echo %GRN%[+] Repair routine complete.%RST%
echo.
echo %WHT%Reboot your PC, then verify with:%RST%
echo %YLW%tpmtool getdeviceinformation%RST%
echo.
pause
exit /b 0

:: -------------------------------
:: Restore Function
:: -------------------------------
:RestoreTask
set "NAME=%~1"
set "SRC=%SRCROOT%\%NAME%"
set "XML=%TMPDIR%\%NAME%.xml"
set "FULL=%TASKROOT%\%NAME%"

echo %CYN%[*] Restoring:%RST% %WHT%%NAME%%RST%

if not exist "%SRC%" (
    echo %RED%[-] Source task file missing.%RST%
    goto :eof
)

copy /y "%SRC%" "%XML%" >nul 2>&1
schtasks /create /tn "%FULL%" /xml "%XML%" /f >nul 2>&1

if errorlevel 1 (
    echo %RED%[-] Failed to register %NAME%.%RST%
) else (
    echo %GRN%[+] Registered %NAME%.%RST%
)

goto :eof
