import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

class SplashScreenManager extends StatefulWidget {
  const SplashScreenManager({super.key});
  @override State<SplashScreenManager> createState() => _SplashScreenManagerState();
}

class _SplashScreenManagerState extends State<SplashScreenManager>
    with LogMixin, DirectoryPickerMixin {
  final _srcCtrl = TextEditingController();
  int _msgIndex = 0;

  final _messages = [
    'Initializing your workspace...',
    'Loading AI providers...',
    'Connecting to language engines...',
    'Preparing your tools...',
    'Warming up the code editor...',
    'Syncing skills and plugins...',
    'Almost ready...',
  ];

  @override
  void initState() {
    super.initState();
    log = 'Splash Screen Manager ready.\n';
    Future.doWhile(() async {
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return false;
      setState(() => _msgIndex = (_msgIndex + 1) % _messages.length);
      return true;
    });
  }

  Future<void> _installSplash() async {
    final src = _srcCtrl.text.trim();
    if (src.isEmpty) { appendLog('⚠ Select folder with splash files first.'); return; }
    appendLog('▶ Installing Graystone splash...');
    await BatService.runBat(BatService.installSplashBat(src), 'install-splash.bat');
    appendLog('✓ Running installer in terminal\n');
  }

  Future<void> _restoreSplash() async {
    appendLog('▶ Restoring original splash...');
    await BatService.runBat(BatService.restoreSplashBat(), 'restore-splash.bat');
    appendLog('✓ Restore running in terminal\n');
  }

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'Splash Screen Manager',
      subtitle: 'Install the Graystone splash screen into AnythingLLM',
      child: Row(children: [

        // LEFT
        Container(
          width: 320,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: kBorder))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('How It Works'),
                ...[
                  '1. Extract ASAR first (ASAR Tools tab)',
                  '2. Download splash files below',
                  '3. Put them in a folder',
                  '4. Select that folder below',
                  '5. Click Install Splash Screen',
                  '6. Restart AnythingLLM',
                ].map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(s, style: const TextStyle(color: kText, fontSize: 12)),
                )),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Download Splash Files'),
                const Text(
                  'Download these from Claude and place them in a folder:',
                  style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 10),
                GBadge('splash.html', color: kBorder, textColor: kAccent2),
                const SizedBox(height: 6),
                GBadge('splash.js', color: kBorder, textColor: kAccent2),
                const SizedBox(height: 12),
                const Text(
                  'Request them from Claude in the main Graystone chat.',
                  style: TextStyle(color: kMuted, fontSize: 11)),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Install Splash'),
                GInput(
                  label: 'Folder with splash.html and splash.js',
                  hint: r'C:\Users\...\splash-files',
                  controller: _srcCtrl,
                  onBrowse: () => pickDirectoryInto(_srcCtrl),
                ),
                GBtn(label: '🎨 Install Splash Screen',
                  onTap: _installSplash, fullWidth: true),
                const SizedBox(height: 8),
                GBtn(label: '↩ Restore Original Splash',
                  onTap: _restoreSplash, fullWidth: true,
                  color: const Color(0xFF78350F), textColor: kWarning),
              ])),
            ]),
          ),
        ),

        // RIGHT — Preview + Log
        Expanded(
          child: Column(children: [
            // Splash preview
            Expanded(
              flex: 2,
              child: Stack(fit: StackFit.expand, children: [
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFDCE6F5), Color(0xFFEAF0FB), Color(0xFFF0EAFF)],
                    ),
                  ),
                ),
                // G Logo placeholder
                Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 100, height: 100,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFD0DFF0), Color(0xFF6A8FB0)],
                        begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Center(
                      child: Text('G', style: TextStyle(
                        fontSize: 56, fontWeight: FontWeight.w900,
                        color: Colors.white))),
                  ),
                  const SizedBox(height: 16),
                  const Text('GRAYSTONE', style: TextStyle(
                    fontSize: 36, fontWeight: FontWeight.w900,
                    color: Color(0xFF1A2A4A), letterSpacing: 8)),
                  const SizedBox(height: 6),
                  const Text('BUILD. CODE. VIBE.', style: TextStyle(
                    fontSize: 13, color: Color(0xFF5B8FC9),
                    letterSpacing: 4, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 32),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(_messages[_msgIndex],
                      key: ValueKey(_msgIndex),
                      style: const TextStyle(fontSize: 12, color: Color(0xFF4A6A9A))),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 180, height: 3,
                    decoration: BoxDecoration(
                      color: const Color(0x33648CB4),
                      borderRadius: BorderRadius.circular(2)),
                    child: LayoutBuilder(builder: (ctx, constraints) {
                      return Align(
                        alignment: Alignment.centerLeft,
                        child: TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: const Duration(seconds: 3),
                          builder: (ctx, value, _) => Container(
                            width: constraints.maxWidth * value,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF7C3AED), Color(0xFF5B8FC9)]),
                              borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  const Text('v1.0.0', style: TextStyle(fontSize: 12,
                    color: Color(0xFF5B8FC9), fontWeight: FontWeight.w600)),
                ]),
              ]),
            ),

            // Log
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GLogPanel(title: 'Splash Log', log: log, onClear: clearLog,
                  titleSize: 14, gap: 8),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
