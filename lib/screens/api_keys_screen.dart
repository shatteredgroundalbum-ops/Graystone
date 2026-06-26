import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/common.dart';
import '../services/bat_service.dart';

const _providers = [
  {'name': 'Together AI',   'prefix': 'tgp_v1_',   'fmt': 'tgp_v1_...',   'color': 0xFF7C3AED, 'env': 'TOGETHER_AI_API_KEY'},
  {'name': 'OpenRouter',    'prefix': 'sk-or-v1-',  'fmt': 'sk-or-v1-...', 'color': 0xFF0369A1, 'env': 'OPENROUTER_API_KEY'},
  {'name': 'Gemini',        'prefix': 'AQ.',         'fmt': 'AQ....',       'color': 0xFF065F46, 'env': 'GEMINI_API_KEY'},
  {'name': 'RunPod',        'prefix': 'rpa_',        'fmt': 'rpa_...',      'color': 0xFF92400E, 'env': 'RUNPOD_API_KEY'},
  {'name': 'ElevenLabs',   'prefix': '',            'fmt': '40-char hex',  'color': 0xFF7F1D1D, 'env': 'ELEVENLABS_API_KEY'},
  {'name': 'Beautiful.ai', 'prefix': '',            'fmt': 'base64==',     'color': 0xFF1E3A5F, 'env': 'BEAUTIFUL_AI_API_KEY'},
  {'name': 'Hugging Face', 'prefix': 'hf_',         'fmt': 'hf_...',       'color': 0xFF374151, 'env': 'HUGGINGFACE_API_KEY'},
  {'name': 'OpenAI',        'prefix': 'sk-',         'fmt': 'sk-...',       'color': 0xFF065F46, 'env': 'OPENAI_API_KEY'},
  {'name': 'GPT4All',       'prefix': 'nk-',         'fmt': 'nk-...',       'color': 0xFF374151, 'env': 'GPT4ALL_API_KEY'},
];

class ApiKeysScreen extends StatefulWidget {
  const ApiKeysScreen({super.key});
  @override State<ApiKeysScreen> createState() => _ApiKeysScreenState();
}

class _ApiKeysScreenState extends State<ApiKeysScreen> {
  final _keyCtrl = TextEditingController();
  bool _obscure = true;
  String? _detectedProvider;
  String? _detectedEnvKey;
  Map<String, String> _savedKeys = {};

  @override
  void initState() {
    super.initState();
    _loadKeys();
    _keyCtrl.addListener(_onKeyChanged);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color bg) {
    if (mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(msg), backgroundColor: bg));
    }
  }

  Future<void> _loadKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((k) => k.startsWith('graystone_key_'));
      setState(() {
        _savedKeys = {for (final k in keys)
          k.replaceFirst('graystone_key_', ''): prefs.getString(k) ?? ''};
      });
    } catch (e) {
      _snack('Could not load saved keys: $e', const Color(0xFF7F1D1D));
    }
  }

  Future<void> _saveKey() async {
    final key = _keyCtrl.text.trim();
    if (key.isEmpty) return;
    final envKey = _detectedEnvKey ?? 'CUSTOM_API_KEY';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('graystone_key_$envKey', key);
      setState(() { _savedKeys[envKey] = key; });
      _keyCtrl.clear();
      _detectedProvider = null;
      _detectedEnvKey = null;
    } catch (e) {
      _snack('Could not save key: $e', const Color(0xFF7F1D1D));
    }
  }

  Future<void> _deleteKey(String envKey) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('graystone_key_$envKey');
      setState(() => _savedKeys.remove(envKey));
    } catch (e) {
      _snack('Could not delete key: $e', const Color(0xFF7F1D1D));
    }
  }

  // SECURITY: never hardcode real API keys in source. Fill these in at runtime
  // (e.g. from a local .env / secure storage) instead of committing secrets.
  static const Map<String, String> _presetKeys = {
    'TOGETHER_AI_API_KEY':  '',
    'OPENROUTER_API_KEY':   '',
    'GEMINI_API_KEY':       '',
    'RUNPOD_API_KEY':       '',
    'ELEVENLABS_API_KEY':   '',
    'BEAUTIFUL_AI_API_KEY': '',
    'GPT4ALL_API_KEY':      '',
  };

  Future<void> _loadPresetKeys() async {
    final presets = {
      for (final e in _presetKeys.entries)
        if (e.value.isNotEmpty) e.key: e.value,
    };
    if (presets.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No preset keys configured.'),
            backgroundColor: Color(0xFF78350F)));
      }
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final e in presets.entries) {
        await prefs.setString('graystone_key_${e.key}', e.value);
      }
      setState(() => _savedKeys.addAll(presets));
      _snack('All API keys loaded!', const Color(0xFF065F46));
    } catch (e) {
      _snack('Could not load preset keys: $e', const Color(0xFF7F1D1D));
    }
  }

  void _onKeyChanged() {
    final key = _keyCtrl.text.trim();
    String? found;
    String? envKey;
    for (final p in _providers) {
      final prefix = p['prefix'] as String;
      if (prefix.isNotEmpty && key.startsWith(prefix)) {
        found = p['name'] as String;
        envKey = p['env'] as String;
        break;
      }
    }
    if (found == null && key.length == 40 &&
        RegExp(r'^[0-9a-fA-F]+$').hasMatch(key)) {
      found = 'ElevenLabs';
      envKey = 'ELEVENLABS_API_KEY';
    }
    if (found == null && key.endsWith('=') && key.length > 20) {
      found = 'Beautiful.ai';
      envKey = 'BEAUTIFUL_AI_API_KEY';
    }
    setState(() { _detectedProvider = found; _detectedEnvKey = envKey; });
  }

  String _mask(String key) =>
    key.length > 8 ? '${key.substring(0,4)}...${key.substring(key.length-4)}' : '****';

  @override
  Widget build(BuildContext context) {
    return GScreen(
      title: 'API Key Manager',
      subtitle: 'Paste any key — auto-detected and saved securely',
      child: Row(children: [

        // LEFT — input
        Container(
          width: 340,
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: kBorder))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Paste API Key'),
                TextField(
                  controller: _keyCtrl,
                  obscureText: _obscure,
                  style: const TextStyle(color: kText, fontSize: 12,
                    fontFamily: 'Consolas'),
                  decoration: const InputDecoration(
                    hintText: 'Paste any API key here...',
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10)),
                ),
                const SizedBox(height: 10),
                if (_detectedProvider != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF065F46))),
                    child: Row(children: [
                      const Icon(Icons.check_circle, color: kSuccess, size: 14),
                      const SizedBox(width: 6),
                      Text('Detected: $_detectedProvider',
                        style: const TextStyle(color: kSuccess, fontSize: 12,
                          fontWeight: FontWeight.w600)),
                    ]),
                  )
                else if (_keyCtrl.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF78350F),
                      borderRadius: BorderRadius.circular(8)),
                    child: const Row(children: [
                      Icon(Icons.help_outline, color: kWarning, size: 14),
                      SizedBox(width: 6),
                      Text('Unknown provider — will save as CUSTOM',
                        style: TextStyle(color: kWarning, fontSize: 11)),
                    ]),
                  )
                else
                  const Text('Paste a key above to auto-detect provider.',
                    style: TextStyle(color: kMuted, fontSize: 11)),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: GBtn(label: '💾 Save Key', onTap: _saveKey, fullWidth: true)),
                  const SizedBox(width: 8),
                  GBtn(label: _obscure ? '👁' : '🙈', onTap: () => setState(() => _obscure = !_obscure),
                    color: kPanel2, textColor: kAccent2),
                ]),
              ])),

              GCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const GCardTitle('Supported Providers'),
                ..._providers.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: Color(p['color'] as int), shape: BoxShape.circle)),
                    const SizedBox(width: 10),
                    SizedBox(width: 110,
                      child: Text(p['name'] as String,
                        style: const TextStyle(color: kText, fontSize: 12,
                          fontWeight: FontWeight.w600))),
                    Text(p['fmt'] as String,
                      style: const TextStyle(color: kMuted, fontSize: 10,
                        fontFamily: 'Consolas')),
                  ]),
                )),
              ])),

              GBtn(label: '⚡ Load All Your Keys', onTap: _loadPresetKeys,
                fullWidth: true, color: const Color(0xFF78350F), textColor: kWarning),
            ]),
          ),
        ),

        // RIGHT — saved keys
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Text('Saved Keys',
                  style: TextStyle(color: kText, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(width: 8),
                GBadge('${_savedKeys.length} keys',
                  color: kBorder, textColor: kMuted),
                const Spacer(),
                GBtn(label: '📋 Export .env', onTap: _exportEnv,
                  color: kPanel2, textColor: kAccent2),
                const SizedBox(width: 8),
                GBtn(label: '🗑 Clear All', onTap: _clearAll,
                  color: const Color(0xFF7F1D1D), textColor: const Color(0xFFFCA5A5)),
              ]),
              const SizedBox(height: 12),
              Expanded(
                child: _savedKeys.isEmpty
                  ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
                      Icon(Icons.vpn_key_off, color: kMuted, size: 40),
                      SizedBox(height: 12),
                      Text('No keys saved yet.\nPaste a key on the left to get started.',
                        style: TextStyle(color: kMuted, fontSize: 13),
                        textAlign: TextAlign.center),
                    ]))
                  : ListView(children: _savedKeys.entries.map((e) =>
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: kPanel, borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: kBorder)),
                      child: Row(children: [
                        const Icon(Icons.key, color: kAccent, size: 16),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(e.key, style: const TextStyle(color: kText,
                            fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 2),
                          Text(_mask(e.value),
                            style: const TextStyle(color: kMuted, fontSize: 11,
                              fontFamily: 'Consolas')),
                        ])),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: kDanger, size: 18),
                          onPressed: () => _deleteKey(e.key),
                        ),
                      ]),
                    )).toList(),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  Future<void> _exportEnv() async {
    if (_savedKeys.isEmpty) return;
    final content = _savedKeys.entries.map((e) => '${e.key}=${e.value}').join('\n');
    try {
      await BatService.saveBatToDesktop('.env', content);
      _snack('.env saved to Desktop.', const Color(0xFF065F46));
    } catch (e) {
      _snack('Could not export .env: $e', const Color(0xFF7F1D1D));
    }
  }

  Future<void> _clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      for (final k in _savedKeys.keys) await prefs.remove('graystone_key_$k');
      setState(() => _savedKeys = {});
    } catch (e) {
      _snack('Could not clear keys: $e', const Color(0xFF7F1D1D));
    }
  }
}
