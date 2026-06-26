@echo off
setlocal enabledelayedexpansion
echo ========================================
echo   Graystone Windows Build + Installer
echo ========================================
echo.

where flutter >nul 2>&1
if errorlevel 1 (
  echo ERROR: Flutter not found in PATH.
  echo Install from: https://flutter.dev/docs/get-started/install/windows
  echo Then add flutter\bin to your PATH and re-run this script.
  pause & exit /b 1
)

REM --- Scaffold the Windows runner if it is missing ---
if not exist "windows\runner\CMakeLists.txt" (
  echo Windows runner not found. Generating it...
  call flutter create --platforms=windows --project-name graystone .
)

REM --- Apply the Graystone icon to the EXE ---
if exist "assets\app_icon.ico" (
  echo Applying app icon...
  copy /Y "assets\app_icon.ico" "windows\runner\resources\app_icon.ico" >nul
)

echo.
echo Getting dependencies...
call flutter pub get

echo.
echo Building Graystone for Windows (release)...
call flutter build windows --release

REM --- Locate the release output (path differs across Flutter versions) ---
set "RELDIR=build\windows\x64\runner\Release"
if not exist "%RELDIR%\graystone.exe" set "RELDIR=build\windows\runner\Release"
if not exist "%RELDIR%\graystone.exe" (
  echo BUILD FAILED - graystone.exe not found. Check the output above.
  pause & exit /b 1
)
echo Build OK: %RELDIR%\graystone.exe

REM --- Stage a self-contained, no-dependency installer ---
echo.
echo Staging installer...
set "STAGE=dist\Graystone-Installer"
if exist "%STAGE%" rmdir /s /q "%STAGE%"
mkdir "%STAGE%\app"
xcopy /E /I /Y "%RELDIR%\*" "%STAGE%\app\" >nul
copy /Y "installer\install.ps1"   "%STAGE%\" >nul
copy /Y "installer\uninstall.ps1" "%STAGE%\" >nul
> "%STAGE%\Install Graystone.bat" echo @echo off
>>"%STAGE%\Install Graystone.bat" echo powershell -NoProfile -ExecutionPolicy Bypass -File "%%~dp0install.ps1"
>>"%STAGE%\Install Graystone.bat" echo pause

powershell -NoProfile -Command "Compress-Archive -Path '%STAGE%\*' -DestinationPath 'dist\Graystone-Installer.zip' -Force"
echo Installer staged: dist\Graystone-Installer.zip   (and folder %STAGE%)

REM --- Optional: nicer single-file Setup.exe if Inno Setup is present ---
set "ISCC="
where iscc >nul 2>&1 && set "ISCC=iscc"
if "%ISCC%"=="" if exist "%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe" set "ISCC=%ProgramFiles(x86)%\Inno Setup 6\ISCC.exe"
if not "%ISCC%"=="" (
  echo Inno Setup found - also building dist\Graystone-Setup.exe ...
  "%ISCC%" "installer\graystone.iss"
)

REM --- Offer to install right now on this PC ---
echo.
echo ========================================
echo   BUILD COMPLETE
echo ========================================
echo.
set "INSTALLNOW=Y"
set /p INSTALLNOW=Install Graystone on THIS PC now? (Y/N) [default Y]: 
if /i "%INSTALLNOW%"=="Y" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "installer\install.ps1" -Source "%RELDIR%"
  echo.
  echo ============================================================
  echo   INSTALLED. Graystone is now on this PC.
  echo   A "Graystone" icon is on your DESKTOP and START MENU.
  echo   Double-click that icon to launch the app. You are done.
  echo ============================================================
) else (
  echo Skipped install. To install later, run this BUILD.bat again and press Y,
  echo or open the "dist\Graystone-Installer" folder and run "Install Graystone.bat".
)
echo.
pause
