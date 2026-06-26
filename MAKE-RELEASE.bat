@echo off
setlocal enabledelayedexpansion
REM ============================================================
REM   Graystone - Build GitHub Release assets
REM   Usage:  MAKE-RELEASE.bat [version]    (e.g. MAKE-RELEASE.bat 1.0.1)
REM   Output: a clean "release\" folder you upload to a GitHub Release.
REM ============================================================
set "VERSION=%~1"
if "%VERSION%"=="" set "VERSION=1.0.0"
echo Building Graystone v%VERSION% release assets...
echo.

where flutter >nul 2>&1
if errorlevel 1 ( echo ERROR: Flutter not in PATH. & pause & exit /b 1 )

if not exist "windows\runner\CMakeLists.txt" (
  echo Generating Windows runner...
  call flutter create --platforms=windows --project-name graystone .
)
if exist "assets\app_icon.ico" copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul

call flutter pub get
echo Building release...
call flutter build windows --release

set "RELDIR=build\windows\x64\runner\Release"
if not exist "%RELDIR%\graystone.exe" set "RELDIR=build\windows\runner\Release"
if not exist "%RELDIR%\graystone.exe" ( echo BUILD FAILED - graystone.exe not found. & pause & exit /b 1 )

REM --- Assemble the installer payload ---
set "STAGE=dist\Graystone-Installer"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%\app"
xcopy /E /I /Y "%RELDIR%\*" "%STAGE%\app\" >nul
copy /Y "installer\install.ps1"   "%STAGE%\" >nul
copy /Y "installer\uninstall.ps1" "%STAGE%\" >nul
> "%STAGE%\Install Graystone.bat" echo @echo off
>>"%STAGE%\Install Graystone.bat" echo powershell -NoProfile -ExecutionPolicy Bypass -File "%%~dp0install.ps1"
>>"%STAGE%\Install Graystone.bat" echo pause

REM --- Clean release output folder ---
set "REL=release"
if exist "%REL%" rmdir /s /q "%REL%"
mkdir "%REL%"
powershell -NoProfile -Command "Compress-Archive -Path '%STAGE%\*' -DestinationPath '%REL%\Graystone-Installer.zip' -Force"

REM --- Optional single-file Setup.exe (if Inno Setup is installed) ---
set "ISCC="
where iscc >nul 2>&1 && set "ISCC=iscc"
if "%ISCC%"=="" if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not "%ISCC%"=="" (
  echo Inno Setup found - building Graystone-Setup.exe ...
  "%ISCC%" "installer\graystone.iss"
  if exist "dist\Graystone-Setup.exe" copy /Y "dist\Graystone-Setup.exe" "%REL%\" >nul
)

REM --- Version manifest (optional, handy for custom update checks) ---
> "%REL%\latest.json" echo {
>>"%REL%\latest.json" echo   "version": "%VERSION%",
>>"%REL%\latest.json" echo   "assets": ["Graystone-Installer.zip", "Graystone-Setup.exe"]
>>"%REL%\latest.json" echo }

echo.
echo ============================================================
echo   DONE. Upload-ready files are in the "release" folder:
echo.
dir /b "%REL%"
echo.
echo   Next steps on GitHub:
echo   1) Create a new Release, tag it  v%VERSION%
echo   2) Drag the files above into the Release "Attach binaries" box
echo   3) Publish. The in-app Updater will then find v%VERSION%.
echo ============================================================
pause
