import 'package:flutter/material.dart';

import '../models/connection.dart';
import '../services/llm_client.dart';
import '../services/store.dart';
import '../widgets/common.dart';

/// Add or edit a single connection. Pass null to create a new one.
class ConnectionEditScreen extends StatefulWidget {
  final Connection? existing;
  const ConnectionEditScreen({super.key, this.existing});

  @override
  State<ConnectionEditScreen> createState() => _ConnectionEditScreenState();
}

class _ConnectionEditScreenState extends State<ConnectionEditScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _key;
  late BackendType _type;
  bool _obscure = true;
  bool _testing = false;
  String? _testMsg;
  Color _testColor = kMuted;

  bool get _isNew => widget.existing == null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _url = TextEditingController(text: e?.baseUrl ?? '');
    _key = TextEditingController(text: e?.apiKey ?? '');
    _type = e?.type ?? BackendType.anythingLlm;
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _key.dispose();
    super.dispose();
  }

  Connection _build() => Connection(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim().isEmpty ? 'Connection' : _name.text.trim(),
        baseUrl: _url.text.trim(),
        apiKey: _key.text.trim(),
        type: _type,
        option: widget.existing?.option,
      );

  Future<void> _test() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    setState(() {
      _testing = true;
      _testMsg = null;
    });
    try {
      await LlmClient.of(_build()).test();
      setState(() {
        _testMsg = 'Connected successfully.';
        _testColor = kSuccess;
      });
    } on LlmException catch (e) {
      setState(() {
        _testMsg = e.message;
        _testColor = kError;
      });
    } finally {
      if (mounted) setState(() => _testing = false);
    }
  }

  Future<void> _save() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    await AppStore.instance.upsert(_build());
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isNew ? 'New connection' : 'Edit connection')),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _form,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(
                      labelText: 'Name', hintText: 'My AnythingLLM server'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<BackendType>(
                  initialValue: _type,
                  decoration: const InputDecoration(labelText: 'Backend type'),
                  items: [
                    for (final t in BackendType.values)
                      DropdownMenuItem(value: t, child: Text(t.label)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? _type),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  decoration: InputDecoration(
                      labelText: 'Server URL', hintText: _type.hint),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return 'Required';
                    final u = Uri.tryParse(s);
                    if (u == null || !(u.isScheme('http') || u.isScheme('https'))) {
                      return 'Must start with http:// or https://';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _key,
                  obscureText: _obscure,
                  decoration: InputDecoration(
                    labelText: _type == BackendType.openai
                        ? 'API key (optional for local servers)'
                        : 'API key',
                    suffixIcon: IconButton(
                      icon: Icon(_obscure
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  validator: (v) {
                    if (_type == BackendType.anythingLlm &&
                        (v ?? '').trim().isEmpty) {
                      return 'AnythingLLM requires an API key';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    OutlinedButton.icon(
                      onPressed: _testing ? null : _test,
                      icon: _testing
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.wifi_tethering),
                      label: const Text('Test'),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Save'),
                    ),
                  ],
                ),
                if (_testMsg != null) ...[
                  const SizedBox(height: 16),
                  Text(_testMsg!, style: TextStyle(color: _testColor)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
