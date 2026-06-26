import 'package:flutter/material.dart';

import '../models/connection.dart';
import '../services/llm_client.dart';
import '../services/store.dart';
import '../widgets/common.dart';
import 'connection_edit_screen.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final AppStore _store = AppStore.instance;

  // In-memory chat history per connection id (kept for the session).
  final Map<String, List<ChatTurn>> _threads = {};

  List<LlmOption> _options = const [];
  bool _loadingOptions = false;
  String? _optionsError;
  bool _sending = false;
  String? _loadedFor; // signature of the connection we last fetched options for

  // Identity of everything that affects which options a server returns; when
  // any of these change (e.g. the connection is edited) the cache is stale.
  String _signatureOf(Connection c) =>
      '${c.id}|${c.type}|${c.baseUrl}|${c.apiKey}';

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStore);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeLoadOptions());
  }

  @override
  void dispose() {
    _store.removeListener(_onStore);
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onStore() {
    setState(() {});
    _maybeLoadOptions();
  }

  Connection? get _conn => _store.selected;

  List<ChatTurn> get _thread =>
      _threads.putIfAbsent(_conn?.id ?? '_', () => []);

  Future<void> _maybeLoadOptions() async {
    final c = _conn;
    if (c == null) return;
    if (_loadedFor == _signatureOf(c) && _optionsError == null) return;
    setState(() {
      _loadingOptions = true;
      _optionsError = null;
      _options = const [];
    });
    try {
      final opts = await LlmClient.of(c).listOptions();
      if (!mounted) return;
      setState(() {
        _options = opts;
        _loadedFor = _signatureOf(c);
        if (c.option == null ||
            !opts.any((o) => o.id == c.option)) {
          c.option = opts.isNotEmpty ? opts.first.id : null;
          _store.touch();
        }
      });
    } on LlmException catch (e) {
      if (mounted) setState(() => _optionsError = e.message);
    } finally {
      if (mounted) setState(() => _loadingOptions = false);
    }
  }

  Future<void> _send() async {
    final c = _conn;
    final text = _input.text.trim();
    if (c == null || text.isEmpty || _sending) return;
    if (c.option == null) {
      _toast('Pick a ${_optionWord(c)} first.');
      return;
    }
    setState(() {
      _thread.add(ChatTurn('user', text));
      _input.clear();
      _sending = true;
    });
    _scrollToEnd();
    try {
      final reply = await LlmClient.of(c).send(_thread, c.option!);
      if (!mounted) return;
      setState(() => _thread.add(ChatTurn('assistant', reply)));
    } on LlmException catch (e) {
      if (!mounted) return;
      setState(() =>
          _thread.add(ChatTurn('assistant', '⚠️ ${e.message}')));
    } finally {
      if (mounted) setState(() => _sending = false);
      _scrollToEnd();
    }
  }

  String _optionWord(Connection c) =>
      c.type == BackendType.anythingLlm ? 'workspace' : 'model';

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(_scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut);
      }
    });
  }

  void _toast(String m) => ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(m)));

  @override
  Widget build(BuildContext context) {
    final c = _conn;
    return Scaffold(
      appBar: AppBar(
        title: Text(c?.name ?? 'Graystone'),
        bottom: c == null ? null : _optionBar(c),
      ),
      body: c == null ? _noConnection() : _chatBody(c),
    );
  }

  PreferredSizeWidget _optionBar(Connection c) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(52),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        child: Row(
          children: [
            Icon(
              c.type == BackendType.anythingLlm
                  ? Icons.workspaces_outline
                  : Icons.smart_toy_outlined,
              size: 18,
              color: kAccent,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _loadingOptions
                  ? const LinearProgressIndicator()
                  : _optionsError != null
                      ? Row(children: [
                          const Icon(Icons.error_outline,
                              color: kError, size: 18),
                          const SizedBox(width: 6),
                          Expanded(
                              child: Text(_optionsError!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(color: kError))),
                          TextButton(
                              onPressed: () {
                                _loadedFor = null;
                                _maybeLoadOptions();
                              },
                              child: const Text('Retry')),
                        ])
                      : DropdownButton<String>(
                          isExpanded: true,
                          value: c.option,
                          hint: Text('Select a ${_optionWord(c)}'),
                          underline: const SizedBox.shrink(),
                          items: [
                            for (final o in _options)
                              DropdownMenuItem(
                                  value: o.id, child: Text(o.label)),
                          ],
                          onChanged: (v) {
                            setState(() => c.option = v);
                            _store.touch();
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noConnection() {
    return GMessage(
      icon: Icons.chat_bubble_outline,
      title: 'No connection selected',
      subtitle: 'Add a server connection, then come back here to chat. '
          'Works with AnythingLLM and any OpenAI-compatible server.',
      action: ElevatedButton.icon(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => const ConnectionEditScreen())),
        icon: const Icon(Icons.add),
        label: const Text('Add connection'),
      ),
    );
  }

  Widget _chatBody(Connection c) {
    return Column(
      children: [
        Expanded(
          child: _thread.isEmpty
              ? GMessage(
                  icon: Icons.forum_outlined,
                  title: 'Start chatting',
                  subtitle: 'Messages go to "${c.name}".',
                )
              : ListView.builder(
                  controller: _scroll,
                  padding: const EdgeInsets.all(12),
                  itemCount: _thread.length,
                  itemBuilder: (context, i) => _bubble(_thread[i]),
                ),
        ),
        if (_sending) const LinearProgressIndicator(),
        _composer(),
      ],
    );
  }

  Widget _bubble(ChatTurn t) {
    final isUser = t.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width *
                (isWide(context) ? 0.6 : 0.82)),
        decoration: BoxDecoration(
          color: isUser ? kPrimary : kSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isUser ? kPrimary : kBorder),
        ),
        child: SelectableText(
          t.content,
          style: TextStyle(
              color: isUser ? Colors.white : kText, height: 1.35),
        ),
      ),
    );
  }

  Widget _composer() {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _input,
                minLines: 1,
                maxLines: 5,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _send(),
                decoration: const InputDecoration(
                    hintText: 'Type a message…'),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 48,
              width: 48,
              child: ElevatedButton(
                onPressed: _sending ? null : _send,
                style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    shape: const CircleBorder()),
                child: const Icon(Icons.send, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
