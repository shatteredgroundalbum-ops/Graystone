import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

const _currentVersion = '1.0.0';

// ▼▼▼ SET THIS to your GitHub "owner/repo" (e.g. 'shatteredground/graystone').
// Everything below derives from it. Until you set it, the GitHub "Check for
// Updates" button won't find anything — but the manual File/URL update still works.
const _repoSlug = 'shatteredgroundalbum-ops/Graystone';
// Name of the installer you attach to each GitHub Release (matches MAKE-RELEASE.bat).
const _updateAssetName = 'Graystone-Installer.zip';

const _updateUrl = 'https://api.github.com/repos/$_repoSlug/releases/latest';
const _releasesUrl = 'https://github.com/$_repoSlug/releases';

class UpdaterScreen extends StatefulWidget {
  const UpdaterScreen({super.key});
  @override State<UpdaterScreen> createState() => _UpdaterScreenState();
}

class _UpdaterScreenState extends State<UpdaterScreen> with LogMixin {
  String _status = 'idle';
  String _latestVersion = '';
  String _releaseNotes = '';
  String _downloadUrl = '';

  final TextEditingController _urlCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    log = 'Updater ready.\nCurrent version: v$_currentVersion\n';
  }

  @override
  void dispose() {
    _urlCtrl.dispose();
    super.dispose();
  }

  void _appendLog(String msg) => appendLog(msg);

  // ── Manual update: pick an installer/update file from this PC ──────────────
  Future<void> _installFromFile() async {
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['exe', 'msix', 'bat', 'zip'],
        dialogTitle: 'Select a Graystone installer or update file',
      );
    } catch (e) {
      _appendLog('✗ Could not open file picker: $e\n');
      return;
    }
    final path = result?.files.single.path;
    if (path == null) {
      _appendLog('Install from file cancelled.');
      return;
    }
    _appendLog('▶ Selected file: $path');
    final ext = path.split('.').last.toLowerCase();
    try {
      if (ext == 'zip') {
        final bat = '''@echo off
set "ZIP=$path"
set "DEST=%TEMP%\\graystone-update"
if exist "%DEST%" rmdir /s /q "%DEST%"
mkdir "%DEST%"
echo Extracting update...
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%ZIP%' -DestinationPath '%DEST%' -Force"
if exist "%DEST%\\install.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\\install.ps1"
) else if exist "%DEST%\\app\\graystone.exe" (
  echo Could not find install.ps1; copy app folder manually.
) else (
  echo This zip does not contain a Graystone installer.
)
pause''';
        await BatService.runBat(bat, 'graystone-update-from-zip.bat');
        _appendLog('✓ Extracting + installing from zip. Follow the window.\n');
      } else {
        // .exe / .msix / .bat — just launch it; it installs/updates itself.
        await Process.start('cmd', ['/c', 'start', '', path],
            runInShell: true, mode: ProcessStartMode.detached);
        _appendLog('✓ Launched $path — follow its prompts.\n');
      }
    } catch (e) {
      _appendLog('✗ Could not run the selected file: $e\n');
    }
  }

  // ── Manual update: paste a download link (.exe/.msix/.zip) ─────────────────
  Future<void> _updateFromUrl() async {
    final url = _urlCtrl.text.trim();
    if (url.isEmpty) {
      _appendLog('✗ Paste a download link first.\n');
      return;
    }
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      _appendLog('✗ That does not look like a URL (must start with http).\n');
      return;
    }
    var name = url.split('?').first.split('/').last;
    if (name.isEmpty || !name.contains('.')) name = 'Graystone-Update.exe';
    final bat = _downloadInstallBat(url, name);
    await runLogged(() async {
      await BatService.runBat(bat, 'graystone-update-from-url.bat');
      _appendLog('▶ Downloading + installing "$name" from URL. Follow the window.\n');
    }, onError: 'Could not start update from URL');
  }

  Future<void> _checkForUpdates() async {
    setState(() => _status = 'checking');
    _appendLog('▶ Checking for updates...');

    try {
      final response = await http.get(
        Uri.parse(_updateUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final latest = (data['tag_name'] as String).replaceFirst('v', '');
        final notes = data['body'] as String? ?? 'No release notes.';
        final assets = data['assets'] as List? ?? [];
        String dlUrl = _releasesUrl;
        for (final asset in assets) {
          final name = (asset['name'] as String?) ?? '';
          if (name.endsWith('.exe') || name.endsWith('.msix') || name.endsWith('.zip')) {
            dlUrl = asset['browser_download_url'] as String;
            break;
          }
        }

        setState(() {
          _latestVersion = latest;
          _releaseNotes = notes;
          _downloadUrl = dlUrl;
          _status = _isNewer(latest, _currentVersion) ? 'update-available' : 'up-to-date';
        });

        if (_status == 'update-available') {
          _appendLog('✓ Update available: v$latest\n');
        } else {
          _appendLog('✓ You are up to date (v$_currentVersion)\n');
        }
      } else {
        setState(() => _status = 'error');
        _appendLog('✗ Could not reach update server (${response.statusCode})');
        _appendLog('  Set up your GitHub releases page to enable updates.\n');
      }
    } catch (e) {
      setState(() => _status = 'error');
      _appendLog('✗ Update check failed: $e');
      _appendLog('  Make sure you have internet access.\n');
    }
  }

  bool _isNewer(String latest, String current) {
    int part(List<String> parts, int i) =>
        i < parts.length ? (int.tryParse(parts[i]) ?? 0) : 0;
    final l = latest.split('.');
    final c = current.split('.');
    for (int i = 0; i < 3; i++) {
      if (part(l, i) > part(c, i)) return true;
      if (part(l, i) < part(c, i)) return false;
    }
    return false;
  }

  Future<void> _downloadUpdate() async {
    final uri = Uri.parse(_downloadUrl.isNotEmpty ? _downloadUrl : _releasesUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        _appendLog('▶ Opened download page in browser.\n');
      } else {
        _appendLog('✗ Could not open the download page. Visit $_releasesUrl manually.\n');
      }
    } catch (e) {
      _appendLog('✗ Could not open the download page: $e\n');
    }
  }

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'Updater',
      subtitle: 'Check for and install Graystone updates',
      child: Row(children: [

        // LEFT
        Container(
          width: 340,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: kBorder))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Current Version'),
                Row(children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: kAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.apps, color: kAccent, size: 22)),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
                    Text('Graystone', style: TextStyle(color: kText,
                      fontWeight: FontWeight.w700, fontSize: 16)),
                    Text('v$_currentVersion', style: TextStyle(color: kMuted, fontSize: 12)),
                  ]),
                ]),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Update Status'),
                _StatusWidget(status: _status, latestVersion: _latestVersion),
                const SizedBox(height: 12),
                GBtn(label: _status == 'checking' ? 'Checking...' : '🔄 Check for Updates',
                  onTap: _status == 'checking' ? () {} : _checkForUpdates,
                  fullWidth: true),
                if (_status == 'update-available') ...[
                  const SizedBox(height: 8),
                  GBtn(label: '⬇ Download v$_latestVersion',
                    onTap: _downloadUpdate, fullWidth: true,
                    color: const Color(0xFF065F46), textColor: kSuccess),
                ],
              ])),

              if (_releaseNotes.isNotEmpty)
                GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const GCardTitle('Release Notes'),
                  Text(_releaseNotes,
                    style: const TextStyle(color: kText, fontSize: 12, height: 1.6)),
                ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Install Update From File'),
                const Text('Pick an installer or update file already on this PC '
                  '(.exe, .msix, .zip, or .bat) and run it:',
                  style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                GBtn(label: '📂 Choose File & Install',
                  onTap: _installFromFile,
                  fullWidth: true, color: const Color(0xFF3B1F6B), textColor: kAccent),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Update From Link'),
                const Text('Paste a direct download link to a new build '
                  '(.exe, .msix, or .zip). It downloads to your Desktop and installs:',
                  style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                GInput(label: 'Download URL', controller: _urlCtrl,
                  hint: 'https://.../Graystone-Setup.exe'),
                GBtn(label: '⬇ Download & Install',
                  onTap: _updateFromUrl,
                  fullWidth: true, color: const Color(0xFF1E3A5F), textColor: kAccent2),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Releases Page (optional)'),
                const Text('If you publish builds on GitHub, open the\nreleases page:',
                  style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                GBtn(label: '🌐 Open Releases Page',
                  onTap: () => launchUrl(Uri.parse(_releasesUrl),
                    mode: LaunchMode.externalApplication),
                  fullWidth: true, color: kPanel2, textColor: kAccent2),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Self-Update BAT'),
                const Text('Generate a BAT that downloads and installs the latest version:',
                  style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                GBtn(label: '📥 Generate Update BAT',
                  onTap: _generateUpdateBat,
                  fullWidth: true, color: const Color(0xFF1E3A5F), textColor: kAccent2),
              ])),
            ]),
          ),
        ),

        // RIGHT — log
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GLogPanel(title: 'Update Log', log: log, onClear: clearLog),
          ),
        ),
      ]),
    );
  }

  // Builds a BAT that downloads `name` from `url` to the Desktop and installs it
  // (extracting + running install.ps1 for a .zip, or launching .exe/.msix).
  String _downloadInstallBat(String url, String name) {
    final isZip = name.toLowerCase().endsWith('.zip');
    final runStep = isZip
        ? '''set "DEST=%TEMP%\\graystone-update"
if exist "%DEST%" rmdir /s /q "%DEST%"
mkdir "%DEST%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Expand-Archive -Path '%DESKTOP%\\$name' -DestinationPath '%DEST%' -Force"
if exist "%DEST%\\install.ps1" powershell -NoProfile -ExecutionPolicy Bypass -File "%DEST%\\install.ps1"'''
        : 'start "" "%DESKTOP%\\$name"';
    return '''@echo off
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath(\\"Desktop\\")"') do set DESKTOP=%%i
echo Downloading update from:
echo $url
powershell -NoProfile -ExecutionPolicy Bypass -Command "Invoke-WebRequest -Uri '$url' -OutFile '%DESKTOP%\\$name' -UseBasicParsing"
if errorlevel 1 ( echo Download failed. Check the link. & pause & exit /b 1 )
echo Download complete: %DESKTOP%\\$name
$runStep
pause''';
  }

  Future<void> _generateUpdateBat() async {
    final url = 'https://github.com/$_repoSlug/releases/latest/download/$_updateAssetName';
    final bat = _downloadInstallBat(url, _updateAssetName);
    await runLogged(() async {
      await BatService.runBat(bat, 'update-graystone.bat');
      _appendLog('✓ Generated update-graystone.bat (pulls latest from GitHub)\n');
    }, onError: 'Could not run update-graystone.bat');
  }
}

// ignore: must_be_immutable
class _StatusWidget extends StatelessWidget {
  final String status;
  final String latestVersion;
  const _StatusWidget({required this.status, required this.latestVersion});

  @override
  Widget build(BuildContext context) {
    switch (status) {
      case 'checking':
        return Row(children: const [
          SizedBox(width: 16, height: 16,
            child: CircularProgressIndicator(strokeWidth: 2, color: kAccent2)),
          SizedBox(width: 10),
          Text('Checking for updates...', style: TextStyle(color: kAccent2, fontSize: 12)),
        ]);
      case 'up-to-date':
        return Row(children: const [
          Icon(Icons.check_circle, color: kSuccess, size: 18),
          SizedBox(width: 8),
          Text('You are up to date!', style: TextStyle(color: kSuccess, fontSize: 12,
            fontWeight: FontWeight.w600)),
        ]);
      case 'update-available':
        return Row(children: [
          const Icon(Icons.new_releases, color: kWarning, size: 18),
          const SizedBox(width: 8),
          Text('Update available: v$latestVersion',
            style: const TextStyle(color: kWarning, fontSize: 12,
              fontWeight: FontWeight.w600)),
        ]);
      case 'error':
        return Row(children: const [
          Icon(Icons.error_outline, color: kDanger, size: 18),
          SizedBox(width: 8),
          Text('Check failed — see log', style: TextStyle(color: kDanger, fontSize: 12)),
        ]);
      default:
        return const Text('Click "Check for Updates" to begin.',
          style: TextStyle(color: kMuted, fontSize: 12));
    }
  }
}

