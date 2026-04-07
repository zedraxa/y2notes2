import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/entities/flash_card_deck.dart';
import '../domain/entities/study_stats.dart';

/// Persistence layer for flash cards and study statistics.
///
/// Serialises data to [SharedPreferences] as JSON, following the same pattern
/// used by [DocumentRepository] and [LibraryRepository].
class FlashCardRepository {
  FlashCardRepository(this._prefs);

  final SharedPreferences _prefs;

  static const String _decksKey = 'flashcard_decks';
  static const String _statsKey = 'flashcard_stats';

  // ── Decks ──────────────────────────────────────────────────────────────────

  Future<List<FlashCardDeck>> loadDecks() async {
    final raw = _prefs.getString(_decksKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((m) => FlashCardDeck.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveDecks(List<FlashCardDeck> decks) async {
    await _prefs.setString(
      _decksKey,
      jsonEncode(decks.map((d) => d.toJson()).toList()),
    );
  }

  // ── Study Stats ────────────────────────────────────────────────────────────

  Future<List<StudyStats>> loadStats() async {
    final raw = _prefs.getString(_statsKey);
    if (raw == null) return [];
    try {
      final list = (jsonDecode(raw) as List).cast<Map<String, dynamic>>();
      return list.map((m) => StudyStats.fromJson(m)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> saveStats(List<StudyStats> stats) async {
    await _prefs.setString(
      _statsKey,
      jsonEncode(stats.map((s) => s.toJson()).toList()),
    );
  }
}
