import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/common.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const _repo = 'https://github.com/shatteredgroundalbum-ops/Graystone';

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Center(
            child: Column(
              children: [
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset('assets/icon.png',
                      width: 88, height: 88, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                          Icons.bubble_chart, size: 88, color: kPrimary)),
                ),
                const SizedBox(height: 12),
                const Text('Graystone',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.w800)),
                const Text('v1.0.0', style: TextStyle(color: kMuted)),
                const SizedBox(height: 8),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    'A cross-platform client for AnythingLLM and any '
                    'OpenAI-compatible LLM server. Runs on Windows, Android '
                    'and the web.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: kMuted, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.code),
                  title: const Text('Source code'),
                  subtitle: const Text('GitHub repository'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open(_repo),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.menu_book_outlined),
                  title: const Text('AnythingLLM API docs'),
                  trailing: const Icon(Icons.open_in_new, size: 18),
                  onTap: () => _open('https://docs.anythingllm.com'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
