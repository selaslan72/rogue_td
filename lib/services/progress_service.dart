import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı ilerleme: bölüm yıldızları + toplam fragment.
/// `shared_preferences` üzerinde saklanır — hem mobil hem web'de çalışır.
class ProgressService {
  ProgressService._();
  static final instance = ProgressService._();

  static const _starsKey = 'level_stars_v1';
  static const _fragmentsKey = 'total_fragments_v1';

  Map<int, int> _stars = {};
  int _totalFragments = 0;
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_starsKey);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _stars = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      } catch (_) {
        _stars = {};
      }
    }
    _totalFragments = prefs.getInt(_fragmentsKey) ?? 0;
    _loaded = true;
  }

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get totalFragments => _totalFragments;

  bool isUnlocked(int starsRequired) => totalStars >= starsRequired;

  /// Verilen bölüm için yıldızı kaydet (sadece daha yüksekse).
  Future<void> setStars(int levelId, int stars) async {
    await load();
    final current = _stars[levelId] ?? 0;
    if (stars <= current) return;
    _stars[levelId] = stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _starsKey,
      jsonEncode(_stars.map((k, v) => MapEntry(k.toString(), v))),
    );
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
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_starsKey);
    await prefs.remove(_fragmentsKey);
  }
}
