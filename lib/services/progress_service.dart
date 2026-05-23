import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/game_season.dart';

/// Kalıcı ilerleme: bölüm yıldızları + toplam fragment.
/// `shared_preferences` üzerinde saklanır — hem mobil hem web'de çalışır.
class ProgressService {
  ProgressService._();
  static final instance = ProgressService._();

  static const _legacyStarsKey = 'level_stars_v1';
  static const _seasonStarsKey = 'level_stars_by_season_v2';
  static const _fragmentsKey = 'total_fragments_v1';

  Map<String, int> _stars = {};
  int _totalFragments = 0;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_seasonStarsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _stars = decoded.map((k, v) => MapEntry(k, v as int));
      } catch (_) {
        _stars = {};
      }
    } else {
      _stars = await _migrateLegacySpringStars(prefs);
    }
    _totalFragments = prefs.getInt(_fragmentsKey) ?? 0;
    _loaded = true;
  }

  int starsFor(int levelId, {GameSeason season = GameSeason.spring}) =>
      _stars[_progressKey(season, levelId)] ?? 0;

  int totalStarsFor(GameSeason season) {
    final prefix = '${season.id}:';
    return _stars.entries
        .where((entry) => entry.key.startsWith(prefix))
        .fold(0, (sum, entry) => sum + entry.value);
  }

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get totalFragments => _totalFragments;

  bool isUnlocked(int starsRequired, {GameSeason season = GameSeason.spring}) =>
      totalStarsFor(season) >= starsRequired;

  /// Verilen bölüm için yıldızı kaydet (sadece daha yüksekse).
  Future<void> setStars(
    int levelId,
    int stars, {
    GameSeason season = GameSeason.spring,
  }) async {
    await load();
    final key = _progressKey(season, levelId);
    final current = _stars[key] ?? 0;
    if (stars <= current) return;
    _stars[key] = stars;
    final prefs = await SharedPreferences.getInstance();
    await _saveStars(prefs);
  }

  Future<void> addFragments(int amount) async {
    if (amount <= 0) return;
    await load();
    _totalFragments += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_fragmentsKey, _totalFragments);
  }

  Future<void> reset() async {
    _stars.clear();
    _totalFragments = 0;
    _loaded = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_legacyStarsKey);
    await prefs.remove(_seasonStarsKey);
    await prefs.remove(_fragmentsKey);
  }

  Future<Map<String, int>> _migrateLegacySpringStars(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_legacyStarsKey);
    if (raw == null) return {};
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final migrated = decoded.map(
        (k, v) =>
            MapEntry(_progressKey(GameSeason.spring, int.parse(k)), v as int),
      );
      await prefs.setString(_seasonStarsKey, jsonEncode(migrated));
      return migrated;
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveStars(SharedPreferences prefs) async {
    await prefs.setString(_seasonStarsKey, jsonEncode(_stars));
  }

  static String _progressKey(GameSeason season, int levelId) =>
      '${season.id}:$levelId';

  @visibleForTesting
  Future<void> reloadForTesting() async {
    _loaded = false;
    _stars.clear();
    _totalFragments = 0;
    await load();
  }
}
