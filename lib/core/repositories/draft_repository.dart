import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/draft.dart';

/// Handles persisting Drafts to local device storage.
class DraftRepository {
  static const _storageKey = 'cadence_drafts';

  static Future<List<Draft>> loadAll() async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getStringList(_storageKey) ?? [];
  final drafts = <Draft>[];
  for (final s in raw) {
    try {
      drafts.add(Draft.fromJson(jsonDecode(s) as Map<String, dynamic>));
    } catch (_) {
      // Skip corrupt/old-schema entries rather than crashing the whole thing.
    }
  }
  drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
  return drafts;
}

  static Future<void> _saveAll(List<Draft> drafts) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = drafts.map((d) => jsonEncode(d.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  /// Inserts a new draft, or overwrites the existing one with matching id.
  static Future<void> upsert(Draft draft) async {
    final drafts = await loadAll();
    final index = drafts.indexWhere((d) => d.id == draft.id);
    if (index >= 0) {
      drafts[index] = draft;
    } else {
      drafts.add(draft);
    }
    await _saveAll(drafts);
  }

  static Future<void> delete(String id) async {
    final drafts = await loadAll();
    drafts.removeWhere((d) => d.id == id);
    await _saveAll(drafts);
  }
}