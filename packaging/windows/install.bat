@echo off
REM install.bat — Atomicas ChemTools Windows installer
REM Double-click "Install ChemTools.bat" to install.
REM
REM What it does:
REM   1. Copies chemtools-server to %LOCALAPPDATA%\ChemTools\
REM   2. Registers the Excel add-in manifest
REM   3. Creates a startup shortcut so the server auto-starts with Windows
REM   4. Starts the server and opens Excel

setlocal enabledelayedexpansion

set "INSTALLER_DIR=%~dp0"
set "INSTALL_DIR=%LOCALAPPDATA%\ChemTools"
set "SERVER_EXE=%INSTALL_DIR%\chemtools-server\chemtools-server.exe"
set "MANIFEST=%INSTALL_DIR%\manifest.xml"
set "LOG_DIR=%LOCALAPPDATA%\ChemTools\logs"

echo.
echo ==========================================
echo   Atomicas ChemTools Installer
echo ==========================================
echo.

REM --- Step 1: Copy server to AppData ---
echo [1/4] Installing ChemTools to %INSTALL_DIR%...
if exist "%INSTALL_DIR%" rmdir /s /q "%INSTALL_DIR%"
mkdir "%INSTALL_DIR%"
mkdir "%LOG_DIR%"
xcopy /e /i /q "%INSTALLER_DIR%chemtools-server" "%INSTALL_DIR%\chemtools-server\"
copy "%INSTALLER_DIR%manifest.xml" "%MANIFEST%"
echo       Done.

REM --- Step 2: Register Excel add-in manifest ---
echo [2/4] Registering Excel add-in...
set "WEF_DIR=%APPDATA%\Microsoft\Excel\XLSTART"
set "WEF_DIR2=%LOCALAPPDATA%\Microsoft\Office\16.0\Wef"

REM Try both common Excel WEF locations
if exist "%APPDATA%\Microsoft\Excel" (
    mkdir "%WEF_DIR%" 2>nul
    copy "%MANIFEST%" "%WEF_DIR%\ChemTools.xml" >nul
    echo       Registered at %WEF_DIR%
)
if exist "%LOCALAPPDATA%\Microsoft\Office\16.0" (
    mkdir "%WEF_DIR2%" 2>nul
    copy "%MANIFEST%" "%WEF_DIR2%\ChemTools.xml" >nul
    echo       Registered at %WEF_DIR2%
)
echo       Done.

REM --- Step 3: Create startup entry so server runs on login ---
echo [3/4] Adding server to Windows startup...
set "STARTUP_KEY=HKCU\Software\Microsoft\Windows\CurrentVersion\Run"
reg add "%STARTUP_KEY%" /v "ChemToolsServer" /t REG_SZ /d "\"%SERVER_EXE%\"" /f >nul
echo       Done.

REM --- Step 4: Start server and open Excel ---
echo [4/4] Starting ChemTools server...
start "" /B "%SERVER_EXE%" > "%LOG_DIR%\server.log" 2>&1

REM Wait up to 15 seconds for server to be ready
set /a attempts=0
:wait_loop
timeout /t 1 /nobreak >nul
curl -s http://localhost:8000/ >nul 2>&1
if %errorlevel% equ 0 goto server_ready
set /a attempts+=1
if !attempts! lss 15 goto wait_loop
echo WARNING: Server may not have started. Check %LOG_DIR%\server.log
goto open_excel

:server_ready
echo       Server ready on http://localhost:8000

:open_excel
echo.
echo ==========================================
echo   Installation complete!
echo   ChemTools will auto-start with Windows.
echo ==========================================
echo.

set /p OPEN_EXCEL="Open Excel now? [Y/n]: "
if /i not "!OPEN_EXCEL!"=="n" (
    start excel.exe
)
