import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

class FileManagerScreen extends StatefulWidget {
  const FileManagerScreen({super.key});
  @override State<FileManagerScreen> createState() => _FileManagerScreenState();
}

class _FileManagerScreenState extends State<FileManagerScreen>
    with LogMixin, DirectoryPickerMixin {
  final _folderCtrl   = TextEditingController();
  final _patternCtrl  = TextEditingController(text: '*.js');
  final _findCtrl     = TextEditingController();
  final _replaceCtrl  = TextEditingController();
  String _task        = 'Find files';
  List<PlatformFile> _attached = [];

  @override
  void initState() {
    super.initState();
    log = 'File Manager ready.\nSelect a task and click Run.\n';
  }

  final _tasks = [
    'Find files', 'Replace text in files', 'Copy files',
    'Move files', 'Create ZIP package', 'Extract ZIP files',
  ];

  final _quickPaths = {
    'AnythingLLM Install':  r'%LOCALAPPDATA%\Programs\AnythingLLM\resources',
    'AnythingLLM Storage':  r'%APPDATA%\anythingllm-desktop\storage',
    'HTTP Folder':          r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar.extracted\http',
    'ASAR Extracted':       r'%LOCALAPPDATA%\Programs\AnythingLLM\resources\app.asar.extracted',
  };

  Future<void> _attachFiles() async {
    try {
      final result = await FilePicker.platform.pickFiles(allowMultiple: true, withData: false);
      if (result != null && mounted) setState(() => _attached.addAll(result.files));
    } catch (e) {
      appendLog('✖ Could not attach files: $e');
    }
  }

  Future<void> _runTask() async {
    final folder  = _folderCtrl.text.trim();
    final pattern = _patternCtrl.text.trim().isEmpty ? '*' : _patternCtrl.text.trim();
    final find    = _findCtrl.text.trim();
    final replace = _replaceCtrl.text.trim();

    appendLog('▶ Task: $_task');
    if (folder.isNotEmpty) appendLog('  Path: $folder');
    appendLog('  Pattern: $pattern\n');

    String bat = '';
    String fname = 'task.bat';

    switch (_task) {
      case 'Find files':
        bat = BatService.findFilesBat(folder, pattern);
        fname = 'find-files.bat';
        break;
      case 'Create ZIP package':
        bat = BatService.zipFilesBat(folder, pattern);
        fname = 'zip-files.bat';
        break;
      case 'Copy files':
        bat = BatService.copyFilesBat(folder, pattern);
        fname = 'copy-files.bat';
        break;
      case 'Replace text in files':
        bat = BatService.replaceTextBat(folder, pattern, find, replace);
        fname = 'replace-text.bat';
        break;
      default:
        bat = BatService.header() + '\necho $_task\npause';
    }

    await runLogged(() async {
      await BatService.runBat(bat, fname);
      appendLog('✓ Generated $fname and launched in terminal\n');
    }, onError: 'Could not run $fname');
  }

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'File Manager',
      subtitle: 'Find, copy, move, zip, replace files',
      child: Row(children: [
        // LEFT
        Container(
          width: 300,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: kBorder))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Quick Paths'),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: kPanel2,
                  style: const TextStyle(color: kText, fontSize: 12),
                  hint: const Text('Select a path', style: TextStyle(color: kMuted)),
                  items: _quickPaths.entries.map((e) =>
                    DropdownMenuItem(value: e.value,
                      child: Text(e.key, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _folderCtrl.text = v); },
                ),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Task Setup'),
                const SizedBox(height: 4),
                DropdownButtonFormField<String>(
                  initialValue: _task,
                  decoration: const InputDecoration(labelText: 'Task Type', isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
                  dropdownColor: kPanel2,
                  style: const TextStyle(color: kText, fontSize: 12),
                  items: _tasks.map((t) =>
                    DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(fontSize: 12)))).toList(),
                  onChanged: (v) { if (v != null) setState(() => _task = v); },
                ),
                const SizedBox(height: 12),
                GInput(label: 'Folder Path', hint: r'C:\Users\...', controller: _folderCtrl, onBrowse: () => pickDirectoryInto(_folderCtrl)),
                GInput(label: 'File Pattern', hint: '*.js', controller: _patternCtrl),
                if (_task == 'Replace text in files') ...[
                  GInput(label: 'Find Text', controller: _findCtrl),
                  GInput(label: 'Replace With', controller: _replaceCtrl),
                ],
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Attached Files'),
                GBtn(label: '+ Attach Files', onTap: _attachFiles,
                  fullWidth: true, color: kPanel2, textColor: kText, icon: Icons.attach_file),
                const SizedBox(height: 8),
                ..._attached.map((f) => Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: kPanel2, borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: kBorder)),
                  child: Row(children: [
                    const Icon(Icons.insert_drive_file, size: 14, color: kMuted),
                    const SizedBox(width: 8),
                    Expanded(child: Text(f.name,
                      style: const TextStyle(fontSize: 11, color: kText),
                      overflow: TextOverflow.ellipsis)),
                  ]),
                )),
                if (_attached.isNotEmpty)
                  GBtn(label: 'Clear', onTap: () => setState(() => _attached = []),
                    color: const Color(0xFF7F1D1D), textColor: const Color(0xFFFCA5A5)),
              ])),

              GBtn(label: '▶ Run Task', onTap: _runTask, fullWidth: true),
              const SizedBox(height: 8),
            ]),
          ),
        ),

        // RIGHT — LOG
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GLogPanel(title: 'Operation Log', log: log, onClear: clearLog),
          ),
        ),
      ]),
    );
  }
}
