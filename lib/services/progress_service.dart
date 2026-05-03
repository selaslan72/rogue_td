import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Kalıcı bölüm ilerlemesi: bölüm id → kazanılan en yüksek yıldız (0..3).
/// shared_preferences üzerinde JSON map olarak saklanır.
class ProgressService {
  ProgressService._();
  static final instance = ProgressService._();

  static const _key = 'level_stars_v1';

  Map<int, int> _stars = {};
  bool _loaded = false;

  Future<void> load() async {
    if (_loaded) return;
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw != null) {
      try {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _stars = decoded.map((k, v) => MapEntry(int.parse(k), v as int));
      } catch (_) {
        _stars = {};
      }
    }
    _loaded = true;
  }

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  bool isUnlocked(int starsRequired) => totalStars >= starsRequired;

  /// Verilen bölüm için yıldızı kaydet (sadece daha yüksekse).
  Future<void> setStars(int levelId, int stars) async {
    await load();
    final current = _stars[levelId] ?? 0;
    if (stars <= current) return;
    _stars[levelId] = stars;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(_stars.map((k, v) => MapEntry(k.toString(), v))),
    );
  }

  Future<void> reset() async {
    _stars.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
