import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/connection.dart';

/// App-wide persisted state: configured connections and the selected one.
class AppStore extends ChangeNotifier {
  AppStore._();
  static final AppStore instance = AppStore._();

  static const _kConnections = 'connections';
  static const _kSelected = 'selectedConnectionId';

  SharedPreferences? _prefs;
  final List<Connection> _connections = [];
  String? _selectedId;

  List<Connection> get connections => List.unmodifiable(_connections);
  String? get selectedId => _selectedId;

  Connection? get selected {
    if (_selectedId == null) return null;
    for (final c in _connections) {
      if (c.id == _selectedId) return c;
    }
    return null;
  }

  Future<void> load() async {
    final prefs = _prefs = await SharedPreferences.getInstance();
    _connections.clear();
    final raw = prefs.getString(_kConnections);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        for (final e in list) {
          _connections.add(Connection.fromJson(e as Map<String, dynamic>));
        }
      } catch (_) {
        // Corrupt store; start fresh rather than crash.
      }
    }
    _selectedId = prefs.getString(_kSelected);
    if (selected == null && _connections.isNotEmpty) {
      _selectedId = _connections.first.id;
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setString(
      _kConnections,
      jsonEncode(_connections.map((c) => c.toJson()).toList()),
    );
    if (_selectedId != null) {
      await prefs.setString(_kSelected, _selectedId!);
    } else {
      await prefs.remove(_kSelected);
    }
  }

  Future<void> upsert(Connection c) async {
    final i = _connections.indexWhere((e) => e.id == c.id);
    if (i >= 0) {
      _connections[i] = c;
    } else {
      _connections.add(c);
    }
    _selectedId ??= c.id;
    await _persist();
    notifyListeners();
  }

  Future<void> remove(String id) async {
    _connections.removeWhere((e) => e.id == id);
    if (_selectedId == id) {
      _selectedId = _connections.isNotEmpty ? _connections.first.id : null;
    }
    await _persist();
    notifyListeners();
  }

  Future<void> select(String id) async {
    if (_selectedId == id) return;
    _selectedId = id;
    await _persist();
    notifyListeners();
  }

  /// Persist a changed field on an existing connection (e.g. selected option).
  Future<void> touch() async {
    await _persist();
    notifyListeners();
  }
}
