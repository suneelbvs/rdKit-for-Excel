@echo off
REM build.bat — Atomicas ChemTools Windows build pipeline
REM
REM Prerequisites (run once):
REM   conda activate cadd
REM   pip install pyinstaller
REM   npm install   (in project root)
REM
REM Run from the project root:
REM   packaging\windows\build.bat
REM
REM Output:
REM   release\windows\ChemToolsSetup.exe

setlocal enabledelayedexpansion

set "PROJECT_ROOT=%~dp0..\.."
set "PACKAGING_DIR=%~dp0"
set "RELEASE_DIR=%PROJECT_ROOT%\release\windows"
set "DIST_DIR=%RELEASE_DIR%\pyinstaller_dist"
set "BUILD_DIR=%RELEASE_DIR%\pyinstaller_build"
set "INSTALLER_DIR=%RELEASE_DIR%\ChemToolsSetup"

echo.
echo ==========================================
echo   Atomicas ChemTools Windows Build
echo ==========================================
echo.

REM --- Step 1: Build JS/CSS/HTML with webpack ---
echo [1/4] Building frontend (webpack)...
cd /d "%PROJECT_ROOT%"
call npm run build
if errorlevel 1 ( echo ERROR: webpack build failed & exit /b 1 )
echo       Done. Output: dist\

REM --- Step 2: Bundle Python server with PyInstaller ---
echo [2/4] Bundling Python server (PyInstaller)...
call conda run -n cadd pyinstaller "%PACKAGING_DIR%chemtools_windows.spec" ^
    --clean -y ^
    --distpath "%DIST_DIR%" ^
    --workpath "%BUILD_DIR%"
if errorlevel 1 ( echo ERROR: PyInstaller failed & exit /b 1 )
echo       Done. Output: %DIST_DIR%\chemtools-server\

REM --- Step 3: Assemble installer folder ---
echo [3/4] Assembling installer folder...
if exist "%INSTALLER_DIR%" rmdir /s /q "%INSTALLER_DIR%"
mkdir "%INSTALLER_DIR%"
xcopy /e /i /q "%DIST_DIR%\chemtools-server" "%INSTALLER_DIR%\chemtools-server\"
copy "%PROJECT_ROOT%\manifest.xml" "%INSTALLER_DIR%\manifest.xml"
copy "%PACKAGING_DIR%install.bat" "%INSTALLER_DIR%\Install ChemTools.bat"
echo       Done.

REM --- Step 4: Create setup .exe with Inno Setup (if available) ---
echo [4/4] Creating Setup installer...
set "INNO=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not exist "%INNO%" set "INNO=%ProgramFiles%\Inno Setup 6\ISCC.exe"

if exist "%INNO%" (
    "%INNO%" "%PACKAGING_DIR%chemtools_setup.iss"
    echo       Done. Output: %RELEASE_DIR%\ChemToolsSetup.exe
) else (
    echo       Inno Setup not found — packaging as ZIP instead.
    powershell -Command "Compress-Archive -Path '%INSTALLER_DIR%\*' -DestinationPath '%RELEASE_DIR%\ChemToolsSetup.zip' -Force"
    echo       Done. Output: %RELEASE_DIR%\ChemToolsSetup.zip
    echo       Install Inno Setup 6 for a proper .exe installer:
    echo       https://jrsoftware.org/isdl.php
)

echo.
echo ==========================================
echo   Build complete!
echo   Output: release\windows\
echo ==========================================
echo.
echo End-user workflow:
echo   1. Run "Install ChemTools.bat" as Administrator
echo   2. Open Excel - ChemTools will be ready
