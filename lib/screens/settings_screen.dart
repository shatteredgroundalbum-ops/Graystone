import 'package:flutter/material.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _darkMode = true;
  bool _runBatInBackground = false;
  bool _confirmBeforeDelete = true;
  bool _autoBackupBeforeReplace = true;

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'Settings',
      subtitle: 'Configure Graystone preferences',
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GCardTitle('Appearance'),
            _Toggle('Dark Mode', 'Graystone dark theme', _darkMode,
              (v) => setState(() => _darkMode = v)),
          ])),

          GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GCardTitle('File Operations'),
            _Toggle('Confirm Before Delete', 'Ask before deleting matched files',
              _confirmBeforeDelete, (v) => setState(() => _confirmBeforeDelete = v)),
            _Toggle('Auto Backup Before Replace', 'Creates .bak files before replacing text',
              _autoBackupBeforeReplace, (v) => setState(() => _autoBackupBeforeReplace = v)),
            _Toggle('Run BAT in Background', 'Run operations silently (no CMD window)',
              _runBatInBackground, (v) => setState(() => _runBatInBackground = v)),
          ])),

          GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GCardTitle('AnythingLLM Paths'),
            const Text('These are the default paths used by ASAR Tools and Splash Manager.',
              style: TextStyle(color: kMuted, fontSize: 11)),
            const SizedBox(height: 12),
            ...BatService.anythingLlmPaths.entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(children: [
                SizedBox(width: 80,
                  child: Text(e.key,
                    style: const TextStyle(color: kMuted, fontSize: 11))),
                Expanded(child: GPathBox(e.value)),
              ]),
            )),
          ])),

          GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GCardTitle('Output Folders'),
            const GPathBox(r'Output:    %USERPROFILE%\Graystone_Output\'),
            const GPathBox(r'Languages: %USERPROFILE%\Graystone_Languages\'),
            const GPathBox(r'Downloads: %USERPROFILE%\Graystone_Downloads\'),
            const SizedBox(height: 8),
            Row(children: [
              GBtn(label: '📂 Open Output', onTap: () async {
                await BatService.runBat(
                  '@echo off\nstart "" "%USERPROFILE%\\Graystone_Output"\n',
                  'open-output.bat');
              }, color: kPanel2, textColor: kAccent2),
              const SizedBox(width: 8),
              GBtn(label: '📂 Open Languages', onTap: () async {
                await BatService.runBat(
                  '@echo off\nstart "" "%USERPROFILE%\\Graystone_Languages"\n',
                  'open-langs.bat');
              }, color: kPanel2, textColor: kAccent2),
            ]),
          ])),

          GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const GCardTitle('About'),
            const Text('Graystone — AI Dev File Manager',
              style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 4),
            const Text('Version 1.0.0', style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 4),
            const Text('Built with Flutter for Windows',
              style: TextStyle(color: kMuted, fontSize: 12)),
            const SizedBox(height: 12),
            GBtn(label: '🔄 Check for Updates',
              onTap: () => Navigator.pushNamed(context, '/updater')),
          ])),
        ]),
      ),
    );
  }

  Widget _Toggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(color: kText, fontWeight: FontWeight.w600,
            fontSize: 13)),
          Text(subtitle, style: const TextStyle(color: kMuted, fontSize: 11)),
        ])),
        Switch(
          value: value, onChanged: onChanged,
          activeThumbColor: kAccent,
          activeTrackColor: kAccent.withValues(alpha: 0.3),
          inactiveTrackColor: kBorder,
          inactiveThumbColor: kMuted,
        ),
      ]),
    );
  }
}
