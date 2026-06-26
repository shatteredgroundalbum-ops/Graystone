import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';

/// Thrown when generating, writing, or launching a batch script fails.
class BatServiceException implements Exception {
  final String message;
  final Object? cause;
  BatServiceException(this.message, [this.cause]);
  @override
  String toString() => cause == null ? message : '$message ($cause)';
}

class BatService {
  /// The .bat / PowerShell automation only works on the Windows build.
  static bool get isWindows => !kIsWeb && Platform.isWindows;

  static String get _userProfile => Platform.environment['USERPROFILE'] ?? '';
  static String get desktop => '$_userProfile\\Desktop';

  /// Escapes a value for safe embedding inside a single-quoted PowerShell
  /// string literal (single quotes are escaped by doubling them).
  static String _ps(String s) => s.replaceAll("'", "''");

  static const anythingLlmPaths = {
    'Install':   r'%LOCALAPPDATA%\Programs\AnythingLLM\resources',
    'Storage':   r'%APPDATA%\anythingllm-desktop\storage',
    'ASAR':      r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar',
    'Extracted': r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar.extracted',
    'HTTP':      r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar.extracted\http',
  };

  static String header() => '''@echo off
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath(\\"Desktop\\")"') do set DESKTOP=%%i
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath(\\"LocalApplicationData\\")"') do set LOCALAPP=%%i
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath(\\"ApplicationData\\")"') do set APPDATA_DIR=%%i
set ANYTHINGLLM=%LOCALAPP%\\Programs\\AnythingLLM\\resources
set EXTRACTED=%LOCALAPP%\\Programs\\AnythingLLM\\resources\\app.asar.extracted
set HTTP=%LOCALAPP%\\Programs\\AnythingLLM\\resources\\app.asar.extracted\\http
set STORAGE=%APPDATA_DIR%\\anythingllm-desktop\\storage
''';

  static Future<String> writeBat(String name, String content) async {
    try {
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}\\$name');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      throw BatServiceException('Could not write script "$name"', e);
    }
  }

  static Future<String> runBat(String content, String name) async {
    if (!isWindows) {
      throw BatServiceException(
        'This tool runs a Windows script and is only available on the Windows build of Graystone.');
    }
    final path = await writeBat(name, content);
    try {
      await Process.start('cmd', ['/c', 'start', 'cmd', '/k', path],
        runInShell: true, mode: ProcessStartMode.detached);
      return path;
    } catch (e) {
      throw BatServiceException('Could not launch script "$name"', e);
    }
  }

  static Future<void> saveBatToDesktop(String name, String content) async {
    if (_userProfile.isEmpty) {
      throw BatServiceException('USERPROFILE is not set; cannot locate Desktop');
    }
    try {
      final file = File('$desktop\\$name');
      await file.writeAsString(content);
    } catch (e) {
      throw BatServiceException('Could not save "$name" to Desktop', e);
    }
  }

  /// Writes [content] to a user-retrievable file and returns its full path.
  /// On Windows this is the Desktop; on Android/other platforms it is the
  /// app's external (or documents) directory, which works without cmd.exe.
  static Future<String> exportFile(String name, String content) async {
    try {
      final String dirPath;
      if (isWindows) {
        if (_userProfile.isEmpty) {
          throw BatServiceException('USERPROFILE is not set; cannot locate Desktop');
        }
        dirPath = desktop;
      } else {
        final dir = await getExternalStorageDirectory() ??
            await getApplicationDocumentsDirectory();
        dirPath = dir.path;
      }
      final file = File('$dirPath${Platform.pathSeparator}$name');
      await file.writeAsString(content);
      return file.path;
    } catch (e) {
      if (e is BatServiceException) rethrow;
      throw BatServiceException('Could not export "$name"', e);
    }
  }

  // ── ASAR Operations ───────────────────────
  static String extractAsarBat() => header() + '''
echo Extracting app.asar...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar extract app.asar app.asar.extracted
echo Done! Extracted to: %EXTRACTED%
pause''';

  static String zipHttpBat() => header() + '''
echo Zipping HTTP folder to Desktop...
powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%HTTP%' -DestinationPath '%DESKTOP%\\anythingllm-http.zip' -Force"
echo Done! Saved to: %DESKTOP%\\anythingllm-http.zip
pause''';

  static String zipFullBat() => header() + '''
echo Extracting and zipping everything...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar extract app.asar app.asar.extracted
powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%EXTRACTED%' -DestinationPath '%DESKTOP%\\anythingllm-full.zip' -Force"
echo Done! Saved to: %DESKTOP%\\anythingllm-full.zip
pause''';

  static String zipStorageBat() => header() + '''
echo Zipping storage to Desktop...
powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path '%STORAGE%' -DestinationPath '%DESKTOP%\\anythingllm-storage.zip' -Force"
echo Done! Saved to: %DESKTOP%\\anythingllm-storage.zip
pause''';

  static String zipCustomPathBat(String path) => header() + '''
echo Zipping to Desktop...
powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path '${_ps(path)}' -DestinationPath '%DESKTOP%\\anythingllm-custom.zip' -Force"
echo Done! Saved to: %DESKTOP%\\anythingllm-custom.zip
pause''';

  static String repackAsarBat() => header() + '''
echo Repacking app.asar...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar pack app.asar.extracted app.asar
echo Done! ASAR repacked. Restart AnythingLLM.
pause''';

  static String findFileBat(String filename) => header() + '''
echo Searching for $filename...
if not exist "%DESKTOP%\\found-files" mkdir "%DESKTOP%\\found-files"
for /r "%ANYTHINGLLM%" %%f in (*$filename*) do (
  echo Found: %%f
  copy "%%f" "%DESKTOP%\\found-files\\"
)
for /r "%STORAGE%" %%f in (*$filename*) do (
  echo Found: %%f
  copy "%%f" "%DESKTOP%\\found-files\\"
)
echo Done! Check Desktop\\found-files
pause''';

  static String installFilesBat(String srcFolder) => header() + '''
echo Installing files from $srcFolder...
xcopy /E /Y "$srcFolder\\*" "%HTTP%\\"
echo Repacking ASAR...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar pack app.asar.extracted app.asar
echo Done! Restart AnythingLLM.
pause''';

  // ── Splash ────────────────────────────────
  static String installSplashBat(String srcFolder) => header() + '''
echo Installing Graystone splash screen...
if exist "$srcFolder\\splash.html" (
  if exist "%HTTP%\\splash.html" copy "%HTTP%\\splash.html" "%HTTP%\\splash.html.backup"
  copy "$srcFolder\\splash.html" "%HTTP%\\splash.html"
  echo Installed splash.html
)
if exist "$srcFolder\\splash.js" (
  if exist "%HTTP%\\splash.js" copy "%HTTP%\\splash.js" "%HTTP%\\splash.js.backup"
  copy "$srcFolder\\splash.js" "%HTTP%\\splash.js"
  echo Installed splash.js
)
echo Repacking ASAR...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar pack app.asar.extracted app.asar
echo Done! Restart AnythingLLM.
pause''';

  static String restoreSplashBat() => header() + '''
echo Restoring original splash...
if exist "%HTTP%\\splash.html.backup" copy "%HTTP%\\splash.html.backup" "%HTTP%\\splash.html"
if exist "%HTTP%\\splash.js.backup" copy "%HTTP%\\splash.js.backup" "%HTTP%\\splash.js"
echo Repacking ASAR...
cd /d "%ANYTHINGLLM%"
npx --yes @electron/asar pack app.asar.extracted app.asar
echo Done! Original splash restored.
pause''';

  // ── Languages ─────────────────────────────
  static String downloadLangBat(String name, String url, String filename) => header() + '''
echo Downloading $name...
if not exist "%USERPROFILE%\\Graystone_Languages" mkdir "%USERPROFILE%\\Graystone_Languages"
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '${_ps(url)}' -OutFile '%USERPROFILE%\\Graystone_Languages\\${_ps(filename)}' -UseBasicParsing"
echo Downloaded: $filename
echo Saved to: %USERPROFILE%\\Graystone_Languages\\
pause''';

  static String downloadAllLangsBat(List<Map<String, String>> langs) {
    var bat = header() + '''
echo Downloading all languages...
if not exist "%USERPROFILE%\\Graystone_Languages" mkdir "%USERPROFILE%\\Graystone_Languages"
echo.
''';
    for (final lang in langs) {
      bat += '''echo Downloading ${lang['name']}...
powershell -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '${_ps(lang['url'] ?? '')}' -OutFile '%USERPROFILE%\\Graystone_Languages\\${_ps(lang['file'] ?? '')}' -UseBasicParsing"
echo Done: ${lang['file']}
echo.
''';
    }
    bat += 'echo All done!\npause';
    return bat;
  }

  static String checkLangsBat() => header() + '''
echo Checking installed languages...
echo.
python --version 2>&1
node --version 2>&1
rustc --version 2>&1
go version 2>&1
java -version 2>&1
flutter --version 2>&1
julia --version 2>&1
ruby --version 2>&1
git --version 2>&1
cmake --version 2>&1
zig version 2>&1
dart --version 2>&1
echo.
echo Check complete.
pause''';

  // ── File Ops ──────────────────────────────
  static String findFilesBat(String folder, String pattern) => header() + '''
echo Searching for $pattern in $folder...
if not exist "%DESKTOP%\\found-files" mkdir "%DESKTOP%\\found-files"
for /r "$folder" %%f in ($pattern) do (
  echo Found: %%f
  copy "%%f" "%DESKTOP%\\found-files\\"
)
echo Done! Check Desktop\\found-files
pause''';

  static String zipFilesBat(String folder, String pattern) => header() + '''
echo Zipping $pattern from $folder...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '${_ps(folder)}' -Filter '${_ps(pattern)}' -Recurse | Compress-Archive -DestinationPath '%DESKTOP%\\matched-files.zip' -Force"
echo Done! Saved to Desktop\\matched-files.zip
pause''';

  static String copyFilesBat(String folder, String pattern) => header() + '''
echo Copying $pattern from $folder...
if not exist "%DESKTOP%\\copied-files" mkdir "%DESKTOP%\\copied-files"
for /r "$folder" %%f in ($pattern) do copy "%%f" "%DESKTOP%\\copied-files\\"
echo Done! Check Desktop\\copied-files
pause''';

  static String replaceTextBat(String folder, String pattern, String find, String replace) => header() + '''
echo Replacing "$find" with "$replace" in $pattern files...
powershell -ExecutionPolicy Bypass -Command "Get-ChildItem -Path '${_ps(folder)}' -Filter '${_ps(pattern)}' -Recurse | ForEach-Object { (Get-Content -Raw \$_.FullName).Replace('${_ps(find)}','${_ps(replace)}') | Set-Content \$_.FullName }"
echo Done! Text replaced.
pause''';
}
