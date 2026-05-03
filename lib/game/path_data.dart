import 'dart:math';
import 'package:flame/components.dart';

/// Bir harita: yol waypoint'leri, tower slot pozisyonları, dekor ağaçları + kayalar.
class GameMap {
  final String name;
  final List<Vector2> waypoints;
  final List<Vector2> towerSlots;
  final List<(double, double, double)> treePositions; // (x, y, scale)
  final List<(double, double, double)> rockPositions; // (x, y, scale)

  const GameMap({
    required this.name,
    required this.waypoints,
    required this.towerSlots,
    required this.treePositions,
    this.rockPositions = const [],
  });
}

/// Sabit yol tanımları. MVP — 3 elden çizilmiş harita.
/// Koordinatlar dünya birimi (480×800 referans).
///
/// Tüm engeller (slot, kaya, ağaç) **aynı 48px grid hücresinde** yaşar:
/// bir hücrede ya boş slot, ya kaya, ya ağaç olur — üst üste binmez.
class PathData {
  PathData._();

  static const double pathWidth = 40;
  static const double slotRadius = 24;
  static const double slotSide = 48;
  static const double forestStep = slotSide; // 48 — aynı grid boyutu
  static const double mapW = 480;
  static const double mapH = 800;

  // ─── Grid helpers ─────────────────────────────────────────────────────────

  /// Bir dünya pozisyonunun ait olduğu hücre indeksi.
  static (int, int) _cellKey(double x, double y) {
    final i = ((x - forestStep / 2) / forestStep).round();
    final j = ((y - forestStep / 2) / forestStep).round();
    return (i, j);
  }

  /// Hücre indeksinin merkez dünya koordinatı.
  static (double, double) _cellCenter(int i, int j) =>
      (i * forestStep + forestStep / 2, j * forestStep + forestStep / 2);

  /// Bir hücrenin merkezinin yola çok yakın olup olmadığı.
  static bool _isPathCell(
    double cx,
    double cy,
    List<Vector2> waypoints, {
    double clearance = 48,
  }) {
    for (int i = 0; i < waypoints.length - 1; i++) {
      final a = waypoints[i];
      final b = waypoints[i + 1];
      if (_distToSegment(cx, cy, a.x, a.y, b.x, b.y) < clearance) return true;
    }
    return false;
  }

  static double _distToSegment(
    double px,
    double py,
    double ax,
    double ay,
    double bx,
    double by,
  ) {
    final dx = bx - ax;
    final dy = by - ay;
    final len2 = dx * dx + dy * dy;
    if (len2 == 0) {
      final ex = px - ax, ey = py - ay;
      return sqrt(ex * ex + ey * ey);
    }
    double t = ((px - ax) * dx + (py - ay) * dy) / len2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
    final cx = ax + t * dx;
    final cy = ay + t * dy;
    final ex = px - cx, ey = py - cy;
    return sqrt(ex * ex + ey * ey);
  }

  /// Çakışmasız grid yerleşimi: slot > kaya > ağaç önceliği.
  ///
  /// 1) Her slot en yakın hücreye snap'lenir, dedupe edilir.
  /// 2) Her kaya en yakın hücreye snap'lenir; slot hücresine düşerse
  ///    veya yola çok yakınsa atılır.
  /// 3) Kalan tüm hücreler (yola yakın olmayan) ağaç olur.
  static GameMap _assemble({
    required String name,
    required List<Vector2> waypoints,
    required List<Vector2> rawSlots,
    required List<(double, double, double)> rawRocks,
    double pathClearance = 48,
  }) {
    // 1) Slotlar
    final slotCells = <(int, int)>{};
    final snappedSlots = <Vector2>[];
    for (final s in rawSlots) {
      final k = _cellKey(s.x, s.y);
      if (slotCells.add(k)) {
        final c = _cellCenter(k.$1, k.$2);
        snappedSlots.add(Vector2(c.$1, c.$2));
      }
    }

    // 2) Kayalar — slot olmayan, yola yakın olmayan hücrelere
    final rockCells = <(int, int)>{};
    final snappedRocks = <(double, double, double)>[];
    for (final r in rawRocks) {
      final k = _cellKey(r.$1, r.$2);
      if (slotCells.contains(k)) continue;
      if (rockCells.contains(k)) continue;
      final c = _cellCenter(k.$1, k.$2);
      if (_isPathCell(c.$1, c.$2, waypoints, clearance: pathClearance)) {
        continue;
      }
      rockCells.add(k);
      snappedRocks.add((c.$1, c.$2, r.$3));
    }

    // 3) Ağaçlar — slot/kaya/yol dışındaki tüm hücreler
    final trees = <(double, double, double)>[];
    final cellsX = (mapW / forestStep).floor();
    final cellsY = (mapH / forestStep).floor();
    for (int j = 0; j < cellsY; j++) {
      for (int i = 0; i < cellsX; i++) {
        final key = (i, j);
        if (slotCells.contains(key)) continue;
        if (rockCells.contains(key)) continue;
        final c = _cellCenter(i, j);
        if (_isPathCell(c.$1, c.$2, waypoints, clearance: pathClearance)) {
          continue;
        }
        trees.add((c.$1, c.$2, 1.0));
      }
    }

    return GameMap(
      name: name,
      waypoints: waypoints,
      towerSlots: snappedSlots,
      treePositions: trees,
      rockPositions: snappedRocks,
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 1 — SNAKE (S-yolu, soldan sağa)
  // ─────────────────────────────────────────────────────────────────────────
  static final snake = _assemble(
    name: 'Snake',
    waypoints: <Vector2>[
      Vector2(0, 200),
      Vector2(120, 200),
      Vector2(120, 360),
      Vector2(360, 360),
      Vector2(360, 540),
      Vector2(120, 540),
      Vector2(120, 700),
      Vector2(480, 700),
    ],
    rawSlots: <Vector2>[
      Vector2(60, 130),
      Vector2(200, 130),
      Vector2(200, 290),
      Vector2(60, 290),
      Vector2(290, 290),
      Vector2(420, 290),
      Vector2(420, 450),
      Vector2(290, 470),
      Vector2(60, 470),
      Vector2(290, 630),
      Vector2(420, 630),
      Vector2(60, 630),
    ],
    rawRocks: const <(double, double, double)>[
      (90, 100, 1.1),
      (255, 88, 0.95),
      (380, 100, 0.95),
      (455, 155, 0.85),
      (200, 410, 1.0),
      (62, 410, 0.9),
      (380, 580, 1.15),
      (245, 620, 0.9),
      (90, 770, 0.9),
      (390, 770, 1.05),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 2 — ZIGZAG (yukardan aşağı, 3 zigzag)
  // ─────────────────────────────────────────────────────────────────────────
  static final zigzag = _assemble(
    name: 'Zigzag',
    waypoints: <Vector2>[
      Vector2(60, 0),
      Vector2(60, 180),
      Vector2(420, 180),
      Vector2(420, 360),
      Vector2(60, 360),
      Vector2(60, 540),
      Vector2(420, 540),
      Vector2(420, 750),
    ],
    rawSlots: <Vector2>[
      Vector2(180, 90),
      Vector2(300, 90),
      Vector2(180, 270),
      Vector2(300, 270),
      Vector2(180, 450),
      Vector2(300, 450),
      Vector2(180, 630),
      Vector2(300, 630),
      Vector2(160, 700),
      Vector2(280, 700),
    ],
    rawRocks: const <(double, double, double)>[
      (130, 50, 1.0),
      (370, 50, 1.15),
      (240, 135, 0.9),
      (350, 280, 0.9),
      (120, 285, 0.95),
      (130, 460, 1.0),
      (365, 455, 1.0),
      (235, 585, 0.9),
      (380, 660, 0.95),
      (110, 660, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 3 — U-LOOP (sol üst → aşağı → sağa → yukarı → sağ üst)
  // ─────────────────────────────────────────────────────────────────────────
  static final uLoop = _assemble(
    name: 'U-Loop',
    waypoints: <Vector2>[
      Vector2(80, 0),
      Vector2(80, 720),
      Vector2(400, 720),
      Vector2(400, 0),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 100),
      Vector2(160, 240),
      Vector2(160, 380),
      Vector2(160, 520),
      Vector2(160, 650),
      Vector2(320, 100),
      Vector2(320, 240),
      Vector2(320, 380),
      Vector2(320, 520),
      Vector2(320, 650),
      Vector2(20, 770),
      Vector2(460, 770),
    ],
    rawRocks: const <(double, double, double)>[
      (160, 60, 1.0),
      (340, 60, 1.1),
      (245, 145, 0.9),
      (240, 255, 1.0),
      (240, 350, 1.15),
      (160, 470, 0.9),
      (340, 470, 1.0),
      (240, 590, 0.95),
      (240, 770, 0.95),
    ],
  );

  static final List<GameMap> all = [snake, zigzag, uLoop];

  static final _rng = Random();
  static GameMap random() => all[_rng.nextInt(all.length)];
}
