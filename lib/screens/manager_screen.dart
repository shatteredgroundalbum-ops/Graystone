import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../services/bat_service.dart';

// Palette matching graystone-manager.html
const _bg = Color(0xFF0F1117);
const _topbar = Color(0xFF1A1F2E);
const _border = Color(0xFF2D3548);
const _sidebar = Color(0xFF13171F);
const _sidebarActive = Color(0xFF1E2535);
const _card = Color(0xFF1A1F2E);
const _accent = Color(0xFF7C3AED);
const _text = Color(0xFFE2E8F0);
const _muted = Color(0xFF64748B);
const _sub = Color(0xFF94A3B8);
const _faint = Color(0xFF475569);

enum _Tone { success, error, info }

class ManagerScreen extends StatefulWidget {
  const ManagerScreen({super.key});
  @override
  State<ManagerScreen> createState() => _ManagerScreenState();
}

class _ManagerScreenState extends State<ManagerScreen> {
  String _panel = 'dashboard';

  // Upload staging
  final List<PlatformFile> _staged = [];

  // Per-panel status messages
  final Map<String, (String, _Tone)> _status = {};

  // Custom download path
  final _customPathCtrl = TextEditingController();
  bool _showCustomPath = false;

  // Find
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _customPathCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _setStatus(String panel, String msg, _Tone tone) =>
      setState(() => _status[panel] = (msg, tone));

  String get _desktop => BatService.desktop;

  // ── Upload ────────────────────────────────
  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      setState(() => _staged.addAll(result.files));
    }
  }

  Future<void> _copyStagedToInstall() async {
    if (_staged.isEmpty) {
      _setStatus('upload', 'No files staged. Add files first.', _Tone.error);
      return;
    }
    try {
      final dir = Directory('$_desktop\\anythingllm-install');
      await dir.create(recursive: true);
      var copied = 0;
      for (final f in _staged) {
        if (f.path == null) continue;
        await File(f.path!).copy('${dir.path}\\${f.name}');
        copied++;
      }
      _setStatus('upload',
          'Copied $copied file(s) to Desktop\\anythingllm-install', _Tone.success);
    } catch (e) {
      _setStatus('upload', 'Copy failed: $e', _Tone.error);
    }
  }

  // ── Download ──────────────────────────────
  Future<void> _downloadBat(String type) async {
    if (type == 'custom') {
      setState(() => _showCustomPath = true);
      return;
    }
    String bat;
    String fname;
    switch (type) {
      case 'http':
        bat = BatService.zipHttpBat();
        fname = 'download-anythingllm-http.bat';
        break;
      case 'full':
        bat = BatService.zipFullBat();
        fname = 'download-anythingllm-full.bat';
        break;
      case 'storage':
        bat = BatService.zipStorageBat();
        fname = 'download-anythingllm-storage.bat';
        break;
      case 'custom-run':
        final cp = _customPathCtrl.text.trim();
        if (cp.isEmpty) {
          _setStatus('download', 'Enter a path first', _Tone.error);
          return;
        }
        bat = BatService.header() +
            '\necho Zipping to Desktop...\n'
                'powershell -ExecutionPolicy Bypass -Command "Compress-Archive -Path \'$cp\' -DestinationPath \'%DESKTOP%\\anythingllm-custom.zip\' -Force"\n'
                'echo Done! Saved to: %DESKTOP%\\anythingllm-custom.zip\npause';
        fname = 'download-anythingllm-custom.bat';
        break;
      default:
        return;
    }
    await BatService.runBat(bat, fname);
    _setStatus('download',
        'BAT generated and running. The zip will appear on your Desktop.',
        _Tone.success);
  }

  // ── Find ──────────────────────────────────
  Future<void> _generateFindBat() async {
    final name = _searchCtrl.text.trim();
    if (name.isEmpty) {
      _setStatus('find', 'Enter a filename first', _Tone.error);
      return;
    }
    await BatService.runBat(BatService.findFileBat(name), 'find-$name.bat');
    _setStatus('find',
        'BAT running — matching files will appear in Desktop\\found-files',
        _Tone.success);
  }

  // ── Extract ───────────────────────────────
  Future<void> _generateExtractBat(String type) async {
    final bat = type == 'http' ? BatService.zipHttpBat() : BatService.zipFullBat();
    await BatService.runBat(bat, 'extract-asar-$type.bat');
    _setStatus('extract',
        'BAT running — extract + zip will appear on your Desktop.', _Tone.success);
  }

  // ── Install ───────────────────────────────
  Future<void> _generateInstallBat() async {
    await BatService.runBat(
        BatService.installFilesBat(r'%DESKTOP%\anythingllm-install'),
        'install-into-anythingllm.bat');
    _setStatus('install',
        'BAT running. Put files in Desktop\\anythingllm-install first, then re-run if needed.',
        _Tone.success);
  }

  // ── Splash ────────────────────────────────
  Future<void> _downloadSplashBat() async {
    const bat = '''@echo off
for /f "tokens=*" %%i in ('powershell -Command "[Environment]::GetFolderPath(\\"Desktop\\")"') do set DESKTOP=%%i
echo Setting up Graystone splash screen...
echo Place splash.html and splash.js in:
echo %DESKTOP%\\anythingllm-install\\
echo Then run install-into-anythingllm.bat
pause''';
    await BatService.runBat(bat, 'setup-splash.bat');
    _setStatus('splash',
        'Instructions BAT running. Put splash.html/splash.js in Desktop\\anythingllm-install, then run the install BAT.',
        _Tone.info);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(children: [
        _topBar(),
        Expanded(
          child: Row(children: [
            _sidebarNav(),
            Expanded(
              child: Container(
                color: _bg,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: _panelContent(),
                ),
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  // ── Top bar ───────────────────────────────
  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      decoration: const BoxDecoration(
        color: _topbar,
        border: Border(bottom: BorderSide(color: _border)),
      ),
      child: Row(children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 16, color: _muted),
          onPressed: () => Navigator.maybePop(context),
          tooltip: 'Back',
        ),
        Container(
          width: 32,
          height: 32,
          decoration:
              BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(8)),
          child: const Center(
            child: Text('G',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18)),
          ),
        ),
        const SizedBox(width: 14),
        const Text('GRAYSTONE',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2)),
        const SizedBox(width: 12),
        const Text('FILE MANAGER',
            style: TextStyle(
                color: _accent, fontWeight: FontWeight.w600, fontSize: 11, letterSpacing: 1)),
      ]),
    );
  }

  // ── Sidebar ───────────────────────────────
  Widget _sidebarNav() {
    return Container(
      width: 220,
      decoration: const BoxDecoration(
        color: _sidebar,
        border: Border(right: BorderSide(color: _border)),
      ),
      child: ListView(padding: const EdgeInsets.symmetric(vertical: 16), children: [
        _sectionLabel('Main'),
        _navItem('dashboard', Icons.dashboard_outlined, 'Dashboard'),
        _navItem('upload', Icons.upload_outlined, 'Upload Files'),
        _navItem('download', Icons.download_outlined, 'Download Files'),
        _navItem('find', Icons.search, 'Find Files'),
        _sectionLabel('AnythingLLM'),
        _navItem('extract', Icons.inventory_2_outlined, 'Extract ASAR'),
        _navItem('install', Icons.system_update_alt, 'Install Files'),
        _navItem('splash', Icons.info_outline, 'Splash Screen'),
      ]),
    );
  }

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 6),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                color: _faint, fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 2)),
      );

  Widget _navItem(String id, IconData icon, String label) {
    final active = _panel == id;
    return InkWell(
      onTap: () => setState(() => _panel = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: active ? _sidebarActive : Colors.transparent,
          border: Border(
            left: BorderSide(
                color: active ? _accent : Colors.transparent, width: 3),
          ),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: active ? Colors.white : _sub),
          const SizedBox(width: 10),
          Text(label,
              style: TextStyle(
                  color: active ? Colors.white : _sub,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ]),
      ),
    );
  }

  // ── Panels ────────────────────────────────
  Widget _panelContent() {
    switch (_panel) {
      case 'upload':
        return _uploadPanel();
      case 'download':
        return _downloadPanel();
      case 'find':
        return _findPanel();
      case 'extract':
        return _extractPanel();
      case 'install':
        return _installPanel();
      case 'splash':
        return _splashPanel();
      default:
        return _dashboardPanel();
    }
  }

  Widget _heading(String title, String subtitle) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: const TextStyle(
                color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 24),
      ]);

  Widget _dashboardPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Graystone File Manager',
          'Manage AnythingLLM files — upload, download, find, and install.'),
      _ActionGrid(cards: [
        _ActionCardData(Icons.upload_outlined, 'Upload Files',
            'Upload any file into AnythingLLM', () => setState(() => _panel = 'upload')),
        _ActionCardData(Icons.download_outlined, 'Download Files',
            'Download files from AnythingLLM', () => setState(() => _panel = 'download')),
        _ActionCardData(Icons.search, 'Find Files', 'Search for any file by name',
            () => setState(() => _panel = 'find')),
        _ActionCardData(Icons.inventory_2_outlined, 'Extract ASAR',
            'Extract app.asar to Desktop', () => setState(() => _panel = 'extract')),
        _ActionCardData(Icons.system_update_alt, 'Install Files',
            'Push files back into AnythingLLM', () => setState(() => _panel = 'install')),
        _ActionCardData(Icons.info_outline, 'Splash Screen',
            'Download the Graystone splash files', () => setState(() => _panel = 'splash')),
      ]),
      const SizedBox(height: 8),
      _Card(title: 'AnythingLLM Paths', children: const [
        _PathLabel('Install Path:'),
        _PathBox(r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\'),
        _PathLabel('Data Path:'),
        _PathBox(r'%APPDATA%\Roaming\anythingllm-desktop\storage\'),
        _PathLabel('ASAR File:'),
        _PathBox(r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar'),
      ]),
    ]);
  }

  Widget _uploadPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Upload Files',
          'Select files to stage for installation into AnythingLLM.'),
      _Card(title: 'Select Files', children: [
        _DropZone(onTap: _pickFiles),
        if (_staged.isNotEmpty) ...[
          const SizedBox(height: 16),
          ..._staged.asMap().entries.map((e) => _FileRow(
                name: e.value.name,
                size: _fmtSize(e.value.size),
                onRemove: () => setState(() => _staged.removeAt(e.key)),
              )),
        ],
        const SizedBox(height: 12),
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Btn('Copy to Install Folder', _accent, _copyStagedToInstall),
          _Btn('Clear', _sidebarActive, () => setState(_staged.clear),
              textColor: _sub),
        ]),
        _statusFor('upload'),
      ]),
    ]);
  }

  Widget _downloadPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Download Files',
          'Generate a BAT to zip and download any folder from AnythingLLM to your Desktop.'),
      _Card(title: 'Choose What to Download', children: [
        _ActionGrid(cards: [
          _ActionCardData(Icons.add_circle_outline, 'HTTP Folder',
              'Contains splash.html and splash.js', () => _downloadBat('http')),
          _ActionCardData(Icons.inventory_2_outlined, 'Full ASAR Extract',
              'Everything inside app.asar', () => _downloadBat('full')),
          _ActionCardData(Icons.storage, 'Storage Folder', 'App data and settings',
              () => _downloadBat('storage')),
          _ActionCardData(Icons.search, 'Custom Path', 'Enter any folder path',
              () => _downloadBat('custom')),
        ]),
        if (_showCustomPath) ...[
          const SizedBox(height: 16),
          _Input(controller: _customPathCtrl, hint: r'Enter full folder path e.g. C:\Users\Name\...'),
          const SizedBox(height: 10),
          _Btn('Generate Download BAT', _accent, () => _downloadBat('custom-run')),
        ],
        _statusFor('download'),
      ]),
    ]);
  }

  Widget _findPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Find Files',
          'Search for any file inside AnythingLLM and generate a BAT to extract it.'),
      _Card(title: 'Search', children: [
        Row(children: [
          Expanded(
              child: _Input(
                  controller: _searchCtrl,
                  hint: 'Type filename e.g. splash.js, index.js, main.css...')),
          const SizedBox(width: 10),
          _Btn('Find It', _accent, _generateFindBat),
        ]),
        const SizedBox(height: 10),
        const Text(
            'This generates a BAT that searches your entire AnythingLLM installation and copies matching files to your Desktop.',
            style: TextStyle(color: _muted, fontSize: 12)),
        _statusFor('find'),
      ]),
    ]);
  }

  Widget _extractPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Extract ASAR',
          'Extract the app.asar file and zip it to your Desktop.'),
      _Card(title: 'Extract Options', children: [
        Wrap(spacing: 10, runSpacing: 10, children: [
          _Btn('Extract HTTP Folder', _accent, () => _generateExtractBat('http')),
          _Btn('Extract Everything', _sidebarActive,
              () => _generateExtractBat('all'),
              textColor: _sub),
        ]),
        const SizedBox(height: 12),
        const Text(
            'Runs a BAT — the zip will appear on your Desktop.',
            style: TextStyle(color: _muted, fontSize: 12)),
        _statusFor('extract'),
      ]),
    ]);
  }

  Widget _installPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Install Files',
          'Generate a BAT that installs your replacement files back into AnythingLLM.'),
      _Card(title: 'How It Works', children: [
        ...[
          'Put your replacement files in a folder on your Desktop called anythingllm-install',
          'Click Generate Install BAT below',
          'Double-click the BAT file',
          'It copies your files in and repacks the ASAR automatically',
          'Restart AnythingLLM',
        ].asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('${e.key + 1}.  ',
                    style: const TextStyle(color: _accent, fontSize: 13, fontWeight: FontWeight.w700)),
                Expanded(
                    child: Text(e.value,
                        style: const TextStyle(color: _sub, fontSize: 13, height: 1.6))),
              ]),
            )),
        const SizedBox(height: 16),
        _Btn('Generate Install BAT', _accent, _generateInstallBat),
        _statusFor('install'),
      ]),
    ]);
  }

  Widget _splashPanel() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _heading('Splash Screen',
          'Download the Graystone splash files ready to install.'),
      _Card(title: 'What You Get', children: [
        const Text(
            'The Graystone splash screen with the G logo, "Build. Code. Vibe." tagline, animated loading bar, and cycling status messages.',
            style: TextStyle(color: _sub, fontSize: 13, height: 1.8)),
        const SizedBox(height: 16),
        _Btn('Download Install BAT', _accent, _downloadSplashBat),
        _statusFor('splash'),
      ]),
    ]);
  }

  Widget _statusFor(String panel) {
    final s = _status[panel];
    if (s == null) return const SizedBox.shrink();
    final (msg, tone) = s;
    late Color bg, fg, border;
    switch (tone) {
      case _Tone.success:
        bg = const Color(0xFF064E3B);
        fg = const Color(0xFF34D399);
        border = const Color(0xFF065F46);
        break;
      case _Tone.error:
        bg = const Color(0xFF7F1D1D);
        fg = const Color(0xFFFCA5A5);
        border = const Color(0xFF991B1B);
        break;
      case _Tone.info:
        bg = const Color(0xFF1E3A5F);
        fg = const Color(0xFF93C5FD);
        border = const Color(0xFF1E40AF);
        break;
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: border),
        ),
        child: Text(msg,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _fmtSize(int bytes) => bytes > 1024 * 1024
      ? '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB'
      : '${(bytes / 1024).toStringAsFixed(1)} KB';
}

// ── Reusable widgets ────────────────────────
class _Card extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Card({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title.toUpperCase(),
            style: const TextStyle(
                color: _sub, fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1)),
        const SizedBox(height: 12),
        ...children,
      ]),
    );
  }
}

class _Btn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  final Color textColor;
  const _Btn(this.label, this.color, this.onTap, {this.textColor = Colors.white});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          child: Text(label,
              style: TextStyle(
                  color: textColor, fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}

class _Input extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  const _Input({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: _text, fontSize: 13),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _faint, fontSize: 13),
        isDense: true,
        filled: true,
        fillColor: _sidebar,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: _accent),
        ),
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  final VoidCallback onTap;
  const _DropZone({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: _sidebar,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _border, width: 2, style: BorderStyle.solid),
        ),
        child: Column(children: const [
          Icon(Icons.upload_file, size: 40, color: _faint),
          SizedBox(height: 12),
          Text('Click to choose files', style: TextStyle(color: _muted, fontSize: 14)),
          SizedBox(height: 4),
          Text('Any file type accepted', style: TextStyle(color: _faint, fontSize: 12)),
        ]),
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  final String name;
  final String size;
  final VoidCallback onRemove;
  const _FileRow({required this.name, required this.size, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _sidebar,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _border),
      ),
      child: Row(children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
              color: _sidebarActive, borderRadius: BorderRadius.circular(6)),
          child: const Icon(Icons.insert_drive_file_outlined, size: 16, color: _accent),
        ),
        const SizedBox(width: 12),
        Expanded(
            child: Text(name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: _text, fontSize: 13, fontWeight: FontWeight.w500))),
        const SizedBox(width: 10),
        Text(size, style: const TextStyle(color: _faint, fontSize: 11)),
        const SizedBox(width: 8),
        InkWell(
          onTap: onRemove,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
                color: const Color(0xFFDC2626), borderRadius: BorderRadius.circular(6)),
            child: const Text('✕',
                style: TextStyle(color: Colors.white, fontSize: 11)),
          ),
        ),
      ]),
    );
  }
}

class _PathLabel extends StatelessWidget {
  final String text;
  const _PathLabel(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: _muted, fontSize: 12)),
      );
}

class _PathBox extends StatelessWidget {
  final String path;
  const _PathBox(this.path);
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _sidebar,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Text(path,
            style: const TextStyle(
                color: _accent, fontSize: 12, fontFamily: 'monospace')),
      );
}

class _ActionCardData {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  _ActionCardData(this.icon, this.title, this.subtitle, this.onTap);
}

class _ActionGrid extends StatelessWidget {
  final List<_ActionCardData> cards;
  const _ActionGrid({required this.cards});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      const minWidth = 200.0;
      const gap = 12.0;
      final cols = (constraints.maxWidth / (minWidth + gap)).floor().clamp(1, 6);
      final cardWidth = (constraints.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: cards
            .map((c) => SizedBox(width: cardWidth, child: _ActionCard(data: c)))
            .toList(),
      );
    });
  }
}

class _ActionCard extends StatefulWidget {
  final _ActionCardData data;
  const _ActionCard({required this.data});
  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.data.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? const Color(0xFF1A1535) : _sidebar,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _hover ? _accent : _border),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(widget.data.icon, size: 24, color: _accent),
            const SizedBox(height: 10),
            Text(widget.data.title,
                style: const TextStyle(
                    color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(widget.data.subtitle,
                style: const TextStyle(color: _muted, fontSize: 11)),
          ]),
        ),
      ),
    );
  }
}
