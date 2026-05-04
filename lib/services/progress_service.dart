import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;

/// Kalıcı ilerleme: bölüm yıldızları + toplam fragment.
/// sqflite üzerinde saklanır; tek instance, ilk I/O'da lazy-load.
class ProgressService {
  ProgressService._();
  static final instance = ProgressService._();

  static const _dbName = 'rogue_td.db';
  static const _dbVersion = 1;

  Database? _db;
  Map<int, int> _stars = {};
  int _totalFragments = 0;
  bool _loaded = false;

  Future<Database> _openDb() async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      p.join(dbPath, _dbName),
      version: _dbVersion,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE level_progress '
          '(level_id INTEGER PRIMARY KEY, stars INTEGER NOT NULL DEFAULT 0)',
        );
        await db.execute(
          'CREATE TABLE meta '
          '(key TEXT PRIMARY KEY, value TEXT NOT NULL)',
        );
      },
    );
    return _db!;
  }

  Future<void> load() async {
    if (_loaded) return;
    final db = await _openDb();
    final rows = await db.query('level_progress');
    _stars = {
      for (final r in rows) r['level_id'] as int: r['stars'] as int,
    };
    final meta = await db.query(
      'meta',
      where: 'key = ?',
      whereArgs: ['total_fragments'],
    );
    _totalFragments = meta.isEmpty
        ? 0
        : int.tryParse(meta.first['value'] as String) ?? 0;
    _loaded = true;
  }

  int starsFor(int levelId) => _stars[levelId] ?? 0;

  int get totalStars => _stars.values.fold(0, (a, b) => a + b);

  int get totalFragments => _totalFragments;

  bool isUnlocked(int starsRequired) => totalStars >= starsRequired;

  Future<void> setStars(int levelId, int stars) async {
    await load();
    final current = _stars[levelId] ?? 0;
    if (stars <= current) return;
    _stars[levelId] = stars;
    final db = await _openDb();
    await db.insert(
      'level_progress',
      {'level_id': levelId, 'stars': stars},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> addFragments(int amount) async {
    if (amount <= 0) return;
    await load();
    _totalFragments += amount;
    final db = await _openDb();
    await db.insert(
      'meta',
      {'key': 'total_fragments', 'value': _totalFragments.toString()},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> reset() async {
    final db = await _openDb();
    await db.delete('level_progress');
    await db.delete('meta');
    _stars.clear();
    _totalFragments = 0;
  }
}
