import 'package:flutter/material.dart';

import '../models/connection.dart';
import '../services/store.dart';
import '../widgets/common.dart';
import 'connection_edit_screen.dart';

class ConnectionsScreen extends StatelessWidget {
  const ConnectionsScreen({super.key});

  void _edit(BuildContext context, [Connection? c]) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ConnectionEditScreen(existing: c),
    ));
  }

  Future<void> _confirmDelete(BuildContext context, Connection c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete connection?'),
        content: Text('Remove "${c.name}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: kError))),
        ],
      ),
    );
    if (ok == true) await AppStore.instance.remove(c.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Connections')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (store.connections.isEmpty) {
            return GMessage(
              icon: Icons.dns_outlined,
              title: 'No connections yet',
              subtitle:
                  'Add an AnythingLLM server or any OpenAI-compatible LLM '
                  'server to start chatting.',
              action: ElevatedButton.icon(
                onPressed: () => _edit(context),
                icon: const Icon(Icons.add),
                label: const Text('Add connection'),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 88),
            itemCount: store.connections.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final c = store.connections[i];
              final selected = c.id == store.selectedId;
              return Container(
                decoration: BoxDecoration(
                  color: kSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: selected ? kPrimary : kBorder,
                      width: selected ? 2 : 1),
                ),
                child: ListTile(
                  onTap: () => store.select(c.id),
                  leading: CircleAvatar(
                    backgroundColor: kSurface2,
                    child: Icon(
                      c.type == BackendType.anythingLlm
                          ? Icons.workspaces_outline
                          : Icons.smart_toy_outlined,
                      color: kAccent,
                    ),
                  ),
                  title: Text(c.name,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text('${c.type.label} · ${c.baseUrl}',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (selected)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.check_circle,
                              color: kSuccess, size: 20),
                        ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => _edit(context, c),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _confirmDelete(context, c),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
