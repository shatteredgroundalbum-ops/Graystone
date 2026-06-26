import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

class AsarToolsScreen extends StatefulWidget {
  const AsarToolsScreen({super.key});
  @override State<AsarToolsScreen> createState() => _AsarToolsScreenState();
}

class _AsarToolsScreenState extends State<AsarToolsScreen>
    with LogMixin, DirectoryPickerMixin {
  final _installSrcCtrl  = TextEditingController();
  final _findFileCtrl    = TextEditingController(text: 'splash.js');

  @override
  void initState() {
    super.initState();
    log = 'ASAR Tools ready.\nClick any operation to run it.\n';
  }

  Future<void> _runOp(String bat, String fname, String label) async {
    appendLog('▶ $label');
    await BatService.runBat(bat, fname);
    appendLog('✓ Running in terminal...\n');
  }

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'ASAR Tools',
      subtitle: 'Extract, repack, and install files into AnythingLLM',
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
                const GCardTitle('AnythingLLM Paths'),
                const GPathBox(r'Install: %LOCALAPPDATA%\Programs\AnythingLLM\resources\'),
                const GPathBox(r'ASAR: ...\resources\app.asar'),
                const GPathBox(r'Extracted: ...\resources\app.asar.extracted\'),
                const GPathBox(r'HTTP: ...\app.asar.extracted\http\'),
                const GPathBox(r'Storage: %APPDATA%\anythingllm-desktop\storage\'),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Extract & Zip'),
                _OpBtn('📦 Extract ASAR → Zip HTTP to Desktop',   kAccent,
                  () => _runOp(BatService.zipHttpBat(),  'zip-http.bat',  'Zip HTTP to Desktop')),
                _OpBtn('📦 Extract ASAR → Zip Everything to Desktop', const Color(0xFF0369A1),
                  () => _runOp(BatService.zipFullBat(),  'zip-full.bat',  'Zip Full Extract to Desktop')),
                _OpBtn('🗜 Zip Storage → Desktop', const Color(0xFF0369A1),
                  () => _runOp(BatService.zipStorageBat(), 'zip-storage.bat', 'Zip Storage to Desktop')),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('ASAR Operations'),
                _OpBtn('📦 Extract app.asar Only', kAccent,
                  () => _runOp(BatService.extractAsarBat(), 'extract-asar.bat', 'Extract ASAR')),
                _OpBtn('🔄 Repack ASAR from Extracted', const Color(0xFF065F46),
                  () => _runOp(BatService.repackAsarBat(), 'repack-asar.bat', 'Repack ASAR')),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Find File'),
                GInput(label: 'Filename to search for', hint: 'splash.js', controller: _findFileCtrl),
                _OpBtn('🔍 Find File in AnythingLLM', const Color(0xFF78350F), () {
                  final fn = _findFileCtrl.text.trim();
                  if (fn.isEmpty) return;
                  _runOp(BatService.findFileBat(fn), 'find-$fn.bat', 'Find $fn');
                }),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Install Files into AnythingLLM'),
                const Text(
                  'Put your replacement files in a folder, select it, then click Install.',
                  style: TextStyle(color: kMuted, fontSize: 11), maxLines: 3),
                const SizedBox(height: 10),
                GInput(label: 'Source Folder', hint: r'C:\Users\...\my-files',
                  controller: _installSrcCtrl, onBrowse: () => pickDirectoryInto(_installSrcCtrl)),
                _OpBtn('⬆ Install Files + Repack ASAR', const Color(0xFF7F1D1D), () {
                  final src = _installSrcCtrl.text.trim();
                  if (src.isEmpty) { appendLog('⚠ Select a source folder first.'); return; }
                  _runOp(BatService.installFilesBat(src), 'install-repack.bat', 'Install + Repack');
                }),
              ])),
            ]),
          ),
        ),

        // RIGHT — LOG
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GLogPanel(title: 'ASAR Log', log: log, onClear: clearLog),
          ),
        ),
      ]),
    );
  }

  Widget _OpBtn(String label, Color color, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GBtn(label: label, onTap: onTap, color: color, fullWidth: true),
    );
  }
}
