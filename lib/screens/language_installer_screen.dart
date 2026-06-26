import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

const _langs = [
  {'name': 'Python 3.12',    'ver': '3.12.0',  'url': 'https://www.python.org/ftp/python/3.12.0/python-3.12.0-amd64.exe',   'file': 'python-3.12.0-amd64.exe',   'type': 'EXE'},
  {'name': 'Node.js v20',    'ver': '20.11.0', 'url': 'https://nodejs.org/dist/v20.11.0/node-v20.11.0-x64.msi',             'file': 'node-v20.11.0-x64.msi',     'type': 'MSI'},
  {'name': 'Rust',           'ver': 'latest',  'url': 'https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe', 'file': 'rustup-init.exe', 'type': 'EXE'},
  {'name': 'Go 1.22',        'ver': '1.22.0',  'url': 'https://go.dev/dl/go1.22.0.windows-amd64.msi',                        'file': 'go1.22.0.windows-amd64.msi','type': 'MSI'},
  {'name': 'Java JDK 21',    'ver': '21',      'url': 'https://download.java.net/java/GA/jdk21/fd2272bbf8e04c3dbaee13770090416c/35/GPL/openjdk-21_windows-x64_bin.zip', 'file': 'openjdk-21.zip', 'type': 'ZIP'},
  {'name': 'Flutter 3.19',   'ver': '3.19.0',  'url': 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.19.0-stable.zip', 'file': 'flutter_3.19.0.zip', 'type': 'ZIP'},
  {'name': 'Julia 1.10',     'ver': '1.10.0',  'url': 'https://julialang-s3.julialang.org/bin/winnt/x64/1.10/julia-1.10.0-win64.exe', 'file': 'julia-1.10.0-win64.exe', 'type': 'EXE'},
  {'name': 'Ruby 3.2',       'ver': '3.2.0',   'url': 'https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-3.2.0-1/rubyinstaller-3.2.0-1-x64.exe', 'file': 'rubyinstaller-3.2.0-x64.exe', 'type': 'EXE'},
  {'name': 'Kotlin 1.9',     'ver': '1.9.0',   'url': 'https://github.com/JetBrains/kotlin/releases/download/v1.9.0/kotlin-compiler-1.9.0.zip', 'file': 'kotlin-compiler-1.9.0.zip', 'type': 'ZIP'},
  {'name': 'Scala 3.4',      'ver': '3.4.0',   'url': 'https://github.com/scala/scala3/releases/download/3.4.0/scala3-3.4.0.zip', 'file': 'scala3-3.4.0.zip', 'type': 'ZIP'},
  {'name': 'CMake 3.29',     'ver': '3.29.0',  'url': 'https://github.com/Kitware/CMake/releases/download/v3.29.0/cmake-3.29.0-windows-x86_64.msi', 'file': 'cmake-3.29.0.msi', 'type': 'MSI'},
  {'name': 'Git 2.44',       'ver': '2.44.0',  'url': 'https://github.com/git-for-windows/git/releases/download/v2.44.0.windows.1/Git-2.44.0-64-bit.exe', 'file': 'Git-2.44.0-64-bit.exe', 'type': 'EXE'},
  {'name': 'Zig 0.12',       'ver': '0.12.0',  'url': 'https://ziglang.org/download/0.12.0/zig-windows-x86_64-0.12.0.zip', 'file': 'zig-0.12.0.zip', 'type': 'ZIP'},
  {'name': 'Lua 5.1',        'ver': '5.1.5',   'url': 'https://sourceforge.net/projects/luabinaries/files/5.1.5/Tools%20Executables/lua-5.1.5_Win64_bin.zip', 'file': 'lua-5.1.5.zip', 'type': 'ZIP'},
  {'name': 'Haskell GHC',    'ver': '9.6',     'url': 'https://downloads.haskell.org/ghcup/x86_64-mingw64-ghcup.exe', 'file': 'ghcup.exe', 'type': 'EXE'},
  {'name': 'Elixir 1.16',    'ver': '1.16',    'url': 'https://github.com/elixir-lang/elixir/releases/download/v1.16.0/elixir-otp-26.zip', 'file': 'elixir-1.16.0.zip', 'type': 'ZIP'},
  {'name': 'Perl 5.38',      'ver': '5.38',    'url': 'https://strawberryperl.com/download/5.38.2.2/strawberry-perl-5.38.2.2-64bit-portable.zip', 'file': 'strawberry-perl-5.38.zip', 'type': 'ZIP'},
  {'name': 'CUDA 12.4',      'ver': '12.4',    'url': 'https://developer.download.nvidia.com/compute/cuda/12.4.0/local_installers/cuda_12.4.0_551.61_windows.exe', 'file': 'cuda_12.4.0.exe', 'type': 'EXE'},
];

class LanguageInstallerScreen extends StatefulWidget {
  const LanguageInstallerScreen({super.key});
  @override State<LanguageInstallerScreen> createState() => _LanguageInstallerScreenState();
}

class _LanguageInstallerScreenState extends State<LanguageInstallerScreen> {
  int? _selected;
  String _log = 'Language installer ready.\nSelect a language and click Download.\n';
  final Map<int, String> _statuses = {};

  void _appendLog(String msg) => setState(() => _log += '$msg\n');

  Future<void> _downloadSelected() async {
    if (_selected == null) {
      _appendLog('⚠ Select a language first.');
      return;
    }
    final lang = _langs[_selected!];
    _appendLog('▶ Downloading ${lang['name']}...');
    final bat = BatService.downloadLangBat(lang['name']!, lang['url']!, lang['file']!);
    await BatService.runBat(bat, 'download-${lang['name']!.replaceAll(' ', '-').toLowerCase()}.bat');
    setState(() => _statuses[_selected!] = 'Downloading...');
    _appendLog('✓ Download started in terminal\n');
  }

  Future<void> _downloadAll() async {
    _appendLog('▶ Generating download-all-languages.bat...');
    final bat = BatService.downloadAllLangsBat(
      _langs.map((l) => {'name': l['name']!, 'url': l['url']!, 'file': l['file']!}).toList());
    await BatService.runBat(bat, 'download-all-languages.bat');
    _appendLog('✓ All-languages downloader launched in terminal\n');
  }

  Future<void> _checkInstalled() async {
    _appendLog('▶ Checking installed languages...');
    await BatService.runBat(BatService.checkLangsBat(), 'check-languages.bat');
    _appendLog('✓ Check running in terminal\n');
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'EXE': return kAccent;
      case 'MSI': return const Color(0xFF0369A1);
      case 'ZIP': return const Color(0xFF065F46);
      default:    return kMuted;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'Language Installer',
      subtitle: 'Download and install 18+ programming languages',
      child: Row(children: [

        // LEFT — table
        Expanded(
          flex: 3,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Available Languages',
                  style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                GBtn(label: '⬇ Download Selected', onTap: _downloadSelected),
                const SizedBox(width: 8),
                GBtn(label: '⬇ Download All', onTap: _downloadAll,
                  color: const Color(0xFF065F46)),
                const SizedBox(width: 8),
                GBtn(label: '✓ Check Installed', onTap: _checkInstalled,
                  color: kPanel2, textColor: kAccent2),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: kPanel, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: kBorder)),
                  child: ListView.builder(
                    itemCount: _langs.length,
                    itemBuilder: (ctx, i) {
                      final lang = _langs[i];
                      final sel = _selected == i;
                      return InkWell(
                        onTap: () => setState(() => _selected = i),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: sel ? const Color(0xFF1A0F35) : Colors.transparent,
                            border: Border(bottom: BorderSide(color: kBorder))),
                          child: Row(children: [
                            SizedBox(width: 200,
                              child: Text(lang['name']!,
                                style: TextStyle(
                                  color: sel ? Colors.white : kText,
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                                  fontSize: 13))),
                            SizedBox(width: 80,
                              child: Text(lang['ver']!,
                                style: const TextStyle(color: kMuted, fontSize: 12))),
                            GBadge(lang['type']!,
                              color: _typeColor(lang['type']!).withValues(alpha: 0.2),
                              textColor: _typeColor(lang['type']!)),
                            const Spacer(),
                            if (_statuses[i] != null)
                              GBadge(_statuses[i]!,
                                color: const Color(0xFF064E3B),
                                textColor: kSuccess),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Downloads saved to: ~/Graystone_Languages/',
                style: const TextStyle(color: kMuted, fontSize: 11)),
            ]),
          ),
        ),

        // RIGHT — log
        Container(
          width: 340,
          decoration: const BoxDecoration(
            border: Border(left: BorderSide(color: kBorder))),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Install Log',
                  style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
                const Spacer(),
                GBtn(label: 'Clear', onTap: () => setState(() => _log = ''),
                  color: kPanel2, textColor: kMuted),
              ]),
              const SizedBox(height: 12),
              Expanded(child: GLogBox(_log)),
              const SizedBox(height: 12),
              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Languages Folder'),
                const GPathBox(r'%USERPROFILE%\Graystone_Languages\'),
                GBtn(label: '📂 Open Folder', fullWidth: true,
                  color: kPanel2, textColor: kAccent2,
                  onTap: () async {
                    await BatService.runBat(
                      '@echo off\nstart "" "%USERPROFILE%\\Graystone_Languages"\n',
                      'open-langs.bat');
                  }),
              ])),
            ]),
          ),
        ),
      ]),
    );
  }
}
