import 'dart:math';
import 'package:flame/components.dart';

enum MapTheme { spring, winter }

/// Bir harita: yol waypoint'leri, tower slot pozisyonları, dekor ağaçları + kayalar.
class GameMap {
  final String name;
  final MapTheme theme;
  final List<Vector2> waypoints;
  final List<Vector2> towerSlots;
  final List<(double, double, double)> treePositions; // (x, y, scale)
  final List<(double, double, double)> rockPositions; // (x, y, scale)

  const GameMap({
    required this.name,
    this.theme = MapTheme.spring,
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
  static const double _targetCastleHalfW = 40;
  static const double _targetCastleTopClearance = 47;
  static const double _targetCastleBottomClearance = 45;

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

  static List<Vector2> _withVisibleCastles(List<Vector2> waypoints) {
    final adjusted = List<Vector2>.of(waypoints);
    final entry = adjusted.first;
    adjusted[0] = Vector2(
      entry.x.clamp(_targetCastleHalfW, mapW - _targetCastleHalfW),
      entry.y.clamp(
        _targetCastleTopClearance,
        mapH - _targetCastleBottomClearance,
      ),
    );
    final target = adjusted.last;
    adjusted[adjusted.length - 1] = Vector2(
      target.x.clamp(_targetCastleHalfW, mapW - _targetCastleHalfW),
      target.y.clamp(
        _targetCastleTopClearance,
        mapH - _targetCastleBottomClearance,
      ),
    );
    return adjusted;
  }

  /// Çakışmasız grid yerleşimi: slot > kaya > ağaç önceliği.
  ///
  /// 1) Her slot en yakın hücreye snap'lenir, dedupe edilir.
  /// 2) Her kaya en yakın hücreye snap'lenir; slot hücresine düşerse
  ///    veya yola çok yakınsa atılır.
  /// 3) Kalan tüm hücreler (yola yakın olmayan) ağaç olur.
  static GameMap _assemble({
    required String name,
    MapTheme theme = MapTheme.spring,
    required List<Vector2> waypoints,
    required List<Vector2> rawSlots,
    required List<(double, double, double)> rawRocks,
    double pathClearance = 48,
    double slotClearance = 44,
  }) {
    final visibleWaypoints = _withVisibleCastles(waypoints);

    // 1) Slotlar
    final slotCells = <(int, int)>{};
    final snappedSlots = <Vector2>[];
    for (final s in rawSlots) {
      final k = _cellKey(s.x, s.y);
      final c = _cellCenter(k.$1, k.$2);
      if (_isPathCell(c.$1, c.$2, visibleWaypoints, clearance: slotClearance)) {
        continue;
      }
      if (slotCells.add(k)) {
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
      if (_isPathCell(c.$1, c.$2, visibleWaypoints, clearance: pathClearance)) {
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
        if (_isPathCell(
          c.$1,
          c.$2,
          visibleWaypoints,
          clearance: pathClearance,
        )) {
          continue;
        }
        trees.add((c.$1, c.$2, 1.0));
      }
    }

    return GameMap(
      name: name,
      theme: theme,
      waypoints: visibleWaypoints,
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
  static final zigzag = GameMap(
    name: 'Zigzag',
    waypoints: <Vector2>[
      Vector2(60, 47),
      Vector2(60, 180),
      Vector2(420, 180),
      Vector2(420, 360),
      Vector2(60, 360),
      Vector2(60, 540),
      Vector2(420, 540),
      Vector2(420, 750),
    ],
    towerSlots: <Vector2>[
      Vector2(150, 95),
      Vector2(265, 95),
      Vector2(355, 105),
      Vector2(155, 270),
      Vector2(285, 270),
      Vector2(365, 285),
      Vector2(125, 450),
      Vector2(250, 450),
      Vector2(360, 455),
      Vector2(135, 650),
      Vector2(265, 650),
      Vector2(335, 705),
    ],
    treePositions: const <(double, double, double)>[
      (250, 58, 0.95),
      (440, 90, 1.0),
      (470, 150, 0.9),
      (105, 285, 1.0),
      (220, 300, 0.92),
      (470, 305, 1.0),
      (20, 415, 1.0),
      (85, 455, 0.95),
      (215, 485, 0.9),
      (470, 485, 1.0),
      (85, 635, 0.95),
      (210, 610, 0.9),
      (390, 635, 0.96),
      (28, 710, 1.0),
      (90, 730, 0.96),
      (210, 735, 0.9),
      (390, 690, 0.96),
    ],
    rockPositions: const <(double, double, double)>[
      (105, 95, 0.9),
      (215, 130, 0.86),
      (315, 135, 0.9),
      (470, 230, 0.9),
      (230, 235, 0.86),
      (330, 315, 0.9),
      (115, 315, 0.86),
      (295, 405, 0.9),
      (390, 405, 0.86),
      (165, 595, 0.9),
      (305, 595, 0.86),
      (455, 635, 0.9),
      (115, 720, 0.86),
      (290, 730, 0.9),
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

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 4 — CROSS (X-yolu, soldan girer, alt sağa çıkar; ortada çapraz)
  // ─────────────────────────────────────────────────────────────────────────
  static final cross = _assemble(
    name: 'Cross',
    waypoints: <Vector2>[
      Vector2(0, 120),
      Vector2(140, 120),
      Vector2(140, 280),
      Vector2(340, 280),
      Vector2(340, 120),
      Vector2(420, 120),
      Vector2(420, 460),
      Vector2(140, 460),
      Vector2(140, 620),
      Vector2(340, 620),
      Vector2(340, 760),
      Vector2(480, 760),
    ],
    rawSlots: <Vector2>[
      Vector2(60, 60),
      Vector2(220, 60),
      Vector2(380, 60),
      Vector2(220, 200),
      Vector2(60, 200),
      Vector2(220, 360),
      Vector2(60, 360),
      Vector2(380, 360),
      Vector2(220, 540),
      Vector2(60, 540),
      Vector2(380, 540),
      Vector2(220, 700),
      Vector2(60, 700),
    ],
    rawRocks: const <(double, double, double)>[
      (290, 50, 1.0),
      (60, 280, 0.95),
      (420, 230, 1.1),
      (290, 360, 0.9),
      (60, 460, 1.05),
      (420, 580, 0.95),
      (290, 700, 1.1),
      (170, 720, 0.9),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 5 — DOUBLE LOOP (iki halka, üst halka sola, alt halka sağa)
  // ─────────────────────────────────────────────────────────────────────────
  static final doubleLoop = _assemble(
    name: 'Double Loop',
    waypoints: <Vector2>[
      Vector2(60, 0),
      Vector2(60, 140),
      Vector2(420, 140),
      Vector2(420, 320),
      Vector2(60, 320),
      Vector2(60, 460),
      Vector2(420, 460),
      Vector2(420, 640),
      Vector2(60, 640),
      Vector2(60, 760),
      Vector2(480, 760),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 70),
      Vector2(280, 70),
      Vector2(380, 70),
      Vector2(160, 230),
      Vector2(280, 230),
      Vector2(380, 230),
      Vector2(160, 390),
      Vector2(280, 390),
      Vector2(380, 390),
      Vector2(160, 550),
      Vector2(280, 550),
      Vector2(380, 550),
      Vector2(220, 700),
      Vector2(340, 700),
    ],
    rawRocks: const <(double, double, double)>[
      (240, 60, 0.95),
      (130, 230, 1.0),
      (350, 230, 1.1),
      (240, 220, 0.9),
      (130, 390, 1.0),
      (350, 390, 0.95),
      (240, 380, 1.05),
      (130, 550, 1.1),
      (350, 550, 0.95),
      (240, 540, 0.9),
      (160, 760, 1.0),
      (340, 760, 1.0),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 6 — MAZE (yoğun zigzag, 7 dönüş)
  // ─────────────────────────────────────────────────────────────────────────
  static final maze = _assemble(
    name: 'Maze',
    waypoints: <Vector2>[
      Vector2(0, 60),
      Vector2(120, 60),
      Vector2(120, 200),
      Vector2(360, 200),
      Vector2(360, 80),
      Vector2(440, 80),
      Vector2(440, 360),
      Vector2(60, 360),
      Vector2(60, 500),
      Vector2(360, 500),
      Vector2(360, 640),
      Vector2(120, 640),
      Vector2(120, 760),
      Vector2(480, 760),
    ],
    rawSlots: <Vector2>[
      Vector2(60, 130),
      Vector2(240, 130),
      Vector2(240, 270),
      Vector2(60, 270),
      Vector2(360, 280),
      Vector2(160, 290),
      Vector2(240, 430),
      Vector2(360, 430),
      Vector2(160, 430),
      Vector2(240, 570),
      Vector2(60, 570),
      Vector2(440, 580),
      Vector2(240, 700),
      Vector2(420, 700),
      Vector2(60, 700),
    ],
    rawRocks: const <(double, double, double)>[
      (220, 30, 1.0),
      (380, 150, 0.9),
      (60, 200, 1.05),
      (320, 350, 0.95),
      (440, 460, 1.0),
      (60, 460, 1.1),
      (300, 580, 0.95),
      (180, 580, 0.9),
      (60, 760, 0.95),
      (300, 760, 1.05),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 7 — SWITCHBACK (uzun yatay dönüşler, erken clearing baskısı)
  // ─────────────────────────────────────────────────────────────────────────
  static final switchback = _assemble(
    name: 'Switchback',
    waypoints: <Vector2>[
      Vector2(0, 90),
      Vector2(420, 90),
      Vector2(420, 230),
      Vector2(80, 230),
      Vector2(80, 370),
      Vector2(420, 370),
      Vector2(420, 520),
      Vector2(80, 520),
      Vector2(80, 670),
      Vector2(480, 670),
    ],
    rawSlots: <Vector2>[
      Vector2(180, 40),
      Vector2(300, 40),
      Vector2(180, 160),
      Vector2(300, 160),
      Vector2(180, 300),
      Vector2(300, 300),
      Vector2(180, 450),
      Vector2(300, 450),
      Vector2(180, 600),
      Vector2(300, 600),
      Vector2(420, 740),
      Vector2(60, 740),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 40, 1.0),
      (420, 170, 0.95),
      (60, 170, 1.1),
      (240, 230, 0.9),
      (420, 305, 1.05),
      (60, 450, 0.95),
      (240, 520, 1.05),
      (420, 600, 0.9),
      (240, 740, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 8 — SPIRAL (merkeze yaklaşan rota, Tesla/Frost için iyi test)
  // ─────────────────────────────────────────────────────────────────────────
  static final spiral = _assemble(
    name: 'Spiral',
    waypoints: <Vector2>[
      Vector2(0, 120),
      Vector2(420, 120),
      Vector2(420, 680),
      Vector2(80, 680),
      Vector2(80, 260),
      Vector2(340, 260),
      Vector2(340, 560),
      Vector2(160, 560),
      Vector2(160, 400),
      Vector2(480, 400),
    ],
    rawSlots: <Vector2>[
      Vector2(180, 60),
      Vector2(300, 60),
      Vector2(360, 200),
      Vector2(440, 300),
      Vector2(360, 620),
      Vector2(240, 620),
      Vector2(120, 620),
      Vector2(120, 340),
      Vector2(240, 320),
      Vector2(280, 500),
      Vector2(220, 450),
      Vector2(420, 470),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 60, 1.0),
      (420, 60, 1.0),
      (240, 180, 1.1),
      (420, 760, 0.9),
      (60, 760, 1.05),
      (240, 700, 0.95),
      (240, 260, 0.95),
      (300, 400, 1.15),
      (60, 420, 0.9),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 9 — STAIRS (basamaklı diagonal okuma, kısa menzil cezalandırılır)
  // ─────────────────────────────────────────────────────────────────────────
  static final stairs = _assemble(
    name: 'Stairs',
    waypoints: <Vector2>[
      Vector2(40, 0),
      Vector2(40, 120),
      Vector2(160, 120),
      Vector2(160, 250),
      Vector2(280, 250),
      Vector2(280, 380),
      Vector2(400, 380),
      Vector2(400, 520),
      Vector2(280, 520),
      Vector2(280, 660),
      Vector2(480, 660),
    ],
    rawSlots: <Vector2>[
      Vector2(120, 60),
      Vector2(240, 60),
      Vector2(80, 200),
      Vector2(240, 180),
      Vector2(360, 190),
      Vector2(200, 330),
      Vector2(360, 310),
      Vector2(200, 470),
      Vector2(360, 470),
      Vector2(200, 600),
      Vector2(360, 600),
      Vector2(420, 730),
    ],
    rawRocks: const <(double, double, double)>[
      (300, 60, 1.0),
      (420, 120, 1.05),
      (80, 300, 0.95),
      (180, 400, 1.1),
      (420, 300, 0.9),
      (80, 560, 1.0),
      (180, 700, 0.95),
      (320, 740, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 10 — RING (dış tur, son bölümde uzun sağ çıkış)
  // ─────────────────────────────────────────────────────────────────────────
  static final ring = _assemble(
    name: 'Ring',
    waypoints: <Vector2>[
      Vector2(240, 0),
      Vector2(240, 120),
      Vector2(420, 120),
      Vector2(420, 680),
      Vector2(60, 680),
      Vector2(60, 120),
      Vector2(240, 120),
      Vector2(240, 420),
      Vector2(480, 420),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 60),
      Vector2(320, 60),
      Vector2(340, 200),
      Vector2(340, 340),
      Vector2(340, 560),
      Vector2(220, 620),
      Vector2(100, 560),
      Vector2(100, 340),
      Vector2(100, 200),
      Vector2(220, 210),
      Vector2(220, 350),
      Vector2(360, 460),
      Vector2(440, 520),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 60, 1.0),
      (60, 60, 1.0),
      (240, 250, 1.15),
      (240, 550, 0.95),
      (160, 420, 1.05),
      (320, 300, 0.95),
      (60, 760, 1.0),
      (420, 760, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 11 — GATE (orta kapı, iki uzun dikey baskı alanı)
  // ─────────────────────────────────────────────────────────────────────────
  static final gate = _assemble(
    name: 'Gate',
    waypoints: <Vector2>[
      Vector2(0, 170),
      Vector2(190, 170),
      Vector2(190, 60),
      Vector2(350, 60),
      Vector2(350, 340),
      Vector2(130, 340),
      Vector2(130, 590),
      Vector2(350, 590),
      Vector2(350, 740),
      Vector2(480, 740),
    ],
    rawSlots: <Vector2>[
      Vector2(80, 100),
      Vector2(260, 140),
      Vector2(420, 140),
      Vector2(270, 240),
      Vector2(420, 260),
      Vector2(70, 270),
      Vector2(240, 420),
      Vector2(420, 430),
      Vector2(70, 470),
      Vector2(240, 520),
      Vector2(420, 640),
      Vector2(240, 710),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 50, 1.0),
      (420, 50, 1.1),
      (240, 260, 0.9),
      (80, 390, 1.05),
      (420, 530, 0.95),
      (240, 620, 1.0),
      (70, 720, 0.95),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 12 — RIVER (uzun kıvrım, çok sayıda çapraz menzil testi)
  // ─────────────────────────────────────────────────────────────────────────
  static final river = _assemble(
    name: 'River',
    waypoints: <Vector2>[
      Vector2(0, 760),
      Vector2(120, 760),
      Vector2(120, 620),
      Vector2(360, 620),
      Vector2(360, 470),
      Vector2(120, 470),
      Vector2(120, 320),
      Vector2(360, 320),
      Vector2(360, 170),
      Vector2(120, 170),
      Vector2(120, 0),
    ],
    rawSlots: <Vector2>[
      Vector2(240, 720),
      Vector2(420, 720),
      Vector2(240, 550),
      Vector2(60, 550),
      Vector2(420, 550),
      Vector2(240, 400),
      Vector2(60, 400),
      Vector2(420, 400),
      Vector2(240, 250),
      Vector2(60, 250),
      Vector2(420, 250),
      Vector2(240, 90),
      Vector2(420, 90),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 690, 1.0),
      (420, 650, 1.1),
      (180, 560, 0.9),
      (300, 500, 1.05),
      (180, 400, 0.95),
      (300, 350, 1.0),
      (180, 250, 1.1),
      (300, 200, 0.9),
      (60, 70, 1.0),
    ],
  );

  static final canyon = _assemble(
    name: 'Canyon',
    waypoints: <Vector2>[
      Vector2(0, 300),
      Vector2(170, 300),
      Vector2(170, 90),
      Vector2(310, 90),
      Vector2(310, 710),
      Vector2(170, 710),
      Vector2(170, 500),
      Vector2(480, 500),
    ],
    rawSlots: <Vector2>[
      Vector2(70, 220),
      Vector2(70, 380),
      Vector2(240, 180),
      Vector2(390, 180),
      Vector2(240, 330),
      Vector2(390, 330),
      Vector2(240, 470),
      Vector2(390, 620),
      Vector2(240, 640),
      Vector2(70, 620),
      Vector2(390, 420),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 70, 1.0),
      (420, 70, 1.1),
      (230, 250, 0.9),
      (390, 250, 1.0),
      (70, 470, 1.05),
      (240, 760, 0.95),
      (420, 760, 1.0),
    ],
  );

  static final clover = _assemble(
    name: 'Clover',
    waypoints: <Vector2>[
      Vector2(240, 0),
      Vector2(240, 170),
      Vector2(80, 170),
      Vector2(80, 340),
      Vector2(240, 340),
      Vector2(400, 340),
      Vector2(400, 520),
      Vector2(240, 520),
      Vector2(240, 800),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 80),
      Vector2(320, 80),
      Vector2(160, 240),
      Vector2(320, 240),
      Vector2(160, 430),
      Vector2(320, 430),
      Vector2(80, 520),
      Vector2(400, 610),
      Vector2(160, 660),
      Vector2(320, 720),
      Vector2(60, 260),
      Vector2(420, 260),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 70, 1.0),
      (420, 70, 1.0),
      (240, 250, 1.1),
      (60, 430, 0.95),
      (420, 430, 0.95),
      (90, 700, 1.05),
      (390, 700, 1.05),
    ],
  );

  static final braid = _assemble(
    name: 'Braid',
    waypoints: <Vector2>[
      Vector2(0, 80),
      Vector2(210, 80),
      Vector2(210, 220),
      Vector2(70, 220),
      Vector2(70, 380),
      Vector2(410, 380),
      Vector2(410, 540),
      Vector2(270, 540),
      Vector2(270, 700),
      Vector2(480, 700),
    ],
    rawSlots: <Vector2>[
      Vector2(100, 150),
      Vector2(300, 150),
      Vector2(150, 300),
      Vector2(300, 300),
      Vector2(150, 460),
      Vector2(300, 460),
      Vector2(100, 600),
      Vector2(360, 620),
      Vector2(430, 300),
      Vector2(430, 460),
      Vector2(220, 760),
      Vector2(60, 760),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 70, 1.0),
      (60, 150, 1.1),
      (240, 250, 0.9),
      (370, 300, 1.0),
      (70, 500, 0.95),
      (180, 600, 1.05),
      (420, 760, 1.0),
    ],
  );

  static final hourglass = _assemble(
    name: 'Hourglass',
    waypoints: <Vector2>[
      Vector2(0, 120),
      Vector2(420, 120),
      Vector2(420, 280),
      Vector2(240, 400),
      Vector2(60, 520),
      Vector2(60, 680),
      Vector2(480, 680),
    ],
    rawSlots: <Vector2>[
      Vector2(120, 60),
      Vector2(280, 60),
      Vector2(360, 220),
      Vector2(260, 300),
      Vector2(160, 360),
      Vector2(320, 450),
      Vector2(120, 600),
      Vector2(260, 600),
      Vector2(400, 600),
      Vector2(160, 740),
      Vector2(320, 740),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 240, 1.0),
      (420, 360, 1.05),
      (240, 500, 1.1),
      (60, 760, 0.95),
      (420, 760, 0.95),
    ],
  );

  static final terrace = _assemble(
    name: 'Terrace',
    waypoints: <Vector2>[
      Vector2(480, 80),
      Vector2(90, 80),
      Vector2(90, 240),
      Vector2(390, 240),
      Vector2(390, 410),
      Vector2(90, 410),
      Vector2(90, 580),
      Vector2(390, 580),
      Vector2(390, 760),
      Vector2(0, 760),
    ],
    rawSlots: <Vector2>[
      Vector2(240, 150),
      Vector2(420, 150),
      Vector2(180, 320),
      Vector2(300, 320),
      Vector2(420, 320),
      Vector2(180, 500),
      Vector2(300, 500),
      Vector2(420, 500),
      Vector2(180, 670),
      Vector2(300, 670),
      Vector2(60, 670),
      Vector2(60, 150),
    ],
    rawRocks: const <(double, double, double)>[
      (180, 40, 1.0),
      (420, 40, 1.05),
      (60, 320, 0.9),
      (240, 410, 1.1),
      (60, 500, 1.0),
      (240, 760, 0.95),
      (420, 700, 1.0),
    ],
  );

  static final fork = _assemble(
    name: 'Fork',
    waypoints: <Vector2>[
      Vector2(0, 420),
      Vector2(160, 420),
      Vector2(160, 160),
      Vector2(320, 160),
      Vector2(320, 420),
      Vector2(160, 420),
      Vector2(160, 650),
      Vector2(420, 650),
      Vector2(420, 800),
    ],
    rawSlots: <Vector2>[
      Vector2(80, 340),
      Vector2(80, 500),
      Vector2(240, 80),
      Vector2(400, 80),
      Vector2(240, 260),
      Vector2(400, 300),
      Vector2(240, 500),
      Vector2(80, 600),
      Vector2(240, 720),
      Vector2(360, 560),
      Vector2(400, 720),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 80, 1.0),
      (160, 260, 0.95),
      (420, 420, 1.1),
      (60, 720, 1.05),
      (300, 620, 0.9),
      (420, 560, 1.0),
    ],
  );

  static final hook = _assemble(
    name: 'Hook',
    waypoints: <Vector2>[
      Vector2(60, 0),
      Vector2(60, 620),
      Vector2(420, 620),
      Vector2(420, 210),
      Vector2(220, 210),
      Vector2(220, 430),
      Vector2(480, 430),
    ],
    rawSlots: <Vector2>[
      Vector2(140, 100),
      Vector2(140, 240),
      Vector2(140, 380),
      Vector2(140, 540),
      Vector2(260, 540),
      Vector2(380, 540),
      Vector2(340, 120),
      Vector2(340, 300),
      Vector2(260, 330),
      Vector2(360, 430),
      Vector2(80, 720),
      Vector2(240, 720),
    ],
    rawRocks: const <(double, double, double)>[
      (240, 80, 1.0),
      (420, 80, 1.1),
      (140, 680, 0.95),
      (300, 620, 1.0),
      (80, 460, 0.9),
      (420, 760, 1.05),
    ],
  );

  static final island = _assemble(
    name: 'Island',
    waypoints: <Vector2>[
      Vector2(480, 300),
      Vector2(330, 300),
      Vector2(330, 120),
      Vector2(120, 120),
      Vector2(120, 680),
      Vector2(330, 680),
      Vector2(330, 500),
      Vector2(0, 500),
    ],
    rawSlots: <Vector2>[
      Vector2(420, 220),
      Vector2(240, 60),
      Vector2(60, 220),
      Vector2(240, 220),
      Vector2(240, 360),
      Vector2(60, 360),
      Vector2(240, 540),
      Vector2(60, 620),
      Vector2(240, 740),
      Vector2(420, 600),
      Vector2(420, 420),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 80, 1.0),
      (60, 60, 1.1),
      (240, 300, 0.95),
      (420, 360, 1.05),
      (60, 760, 0.9),
      (420, 760, 1.0),
    ],
  );

  static final ladder = _assemble(
    name: 'Ladder',
    waypoints: <Vector2>[
      Vector2(120, 0),
      Vector2(120, 120),
      Vector2(360, 120),
      Vector2(360, 260),
      Vector2(120, 260),
      Vector2(120, 400),
      Vector2(360, 400),
      Vector2(360, 540),
      Vector2(120, 540),
      Vector2(120, 700),
      Vector2(480, 700),
    ],
    rawSlots: <Vector2>[
      Vector2(240, 60),
      Vector2(60, 180),
      Vector2(240, 190),
      Vector2(420, 190),
      Vector2(60, 330),
      Vector2(240, 330),
      Vector2(420, 330),
      Vector2(60, 470),
      Vector2(240, 470),
      Vector2(420, 470),
      Vector2(240, 620),
      Vector2(420, 620),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 60, 1.0),
      (420, 60, 1.05),
      (300, 260, 0.9),
      (60, 620, 1.1),
      (240, 760, 0.95),
    ],
  );

  static final loopback = _assemble(
    name: 'Garden Run',
    waypoints: <Vector2>[
      Vector2(0, 140),
      Vector2(300, 140),
      Vector2(300, 280),
      Vector2(90, 280),
      Vector2(90, 430),
      Vector2(390, 430),
      Vector2(390, 590),
      Vector2(180, 590),
      Vector2(180, 720),
      Vector2(480, 720),
    ],
    rawSlots: <Vector2>[
      Vector2(120, 72),
      Vector2(408, 168),
      Vector2(216, 216),
      Vector2(408, 312),
      Vector2(24, 360),
      Vector2(216, 360),
      Vector2(456, 504),
      Vector2(72, 552),
      Vector2(288, 648),
      Vector2(408, 648),
      Vector2(72, 744),
    ],
    rawRocks: const <(double, double, double)>[
      (216, 24, 1.0),
      (408, 72, 0.95),
      (456, 264, 1.05),
      (24, 504, 1.1),
      (312, 504, 0.9),
      (312, 744, 1.0),
    ],
  );

  static final pinch = _assemble(
    name: 'Pinch',
    waypoints: <Vector2>[
      Vector2(240, 0),
      Vector2(240, 210),
      Vector2(80, 210),
      Vector2(80, 390),
      Vector2(240, 390),
      Vector2(400, 390),
      Vector2(400, 570),
      Vector2(240, 570),
      Vector2(240, 800),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 110),
      Vector2(320, 110),
      Vector2(160, 300),
      Vector2(320, 300),
      Vector2(160, 480),
      Vector2(320, 480),
      Vector2(80, 580),
      Vector2(400, 690),
      Vector2(160, 690),
      Vector2(320, 730),
      Vector2(440, 260),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 80, 1.0),
      (420, 80, 1.0),
      (240, 300, 1.1),
      (60, 470, 0.9),
      (420, 470, 1.05),
      (60, 730, 0.95),
    ],
  );

  static final rampart = _assemble(
    name: 'Rampart',
    waypoints: <Vector2>[
      Vector2(0, 620),
      Vector2(420, 620),
      Vector2(420, 450),
      Vector2(60, 450),
      Vector2(60, 280),
      Vector2(420, 280),
      Vector2(420, 110),
      Vector2(0, 110),
    ],
    rawSlots: <Vector2>[
      Vector2(180, 700),
      Vector2(320, 700),
      Vector2(180, 540),
      Vector2(320, 540),
      Vector2(180, 370),
      Vector2(320, 370),
      Vector2(180, 200),
      Vector2(320, 200),
      Vector2(60, 700),
      Vector2(420, 700),
      Vector2(60, 200),
      Vector2(420, 40),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 760, 1.1),
      (240, 620, 0.9),
      (420, 540, 1.0),
      (60, 370, 1.05),
      (240, 280, 0.95),
      (420, 200, 1.0),
    ],
  );

  static final saw = _assemble(
    name: 'Saw',
    waypoints: <Vector2>[
      Vector2(0, 80),
      Vector2(130, 220),
      Vector2(0, 360),
      Vector2(260, 360),
      Vector2(130, 500),
      Vector2(260, 640),
      Vector2(480, 640),
    ],
    rawSlots: <Vector2>[
      Vector2(160, 110),
      Vector2(300, 180),
      Vector2(90, 290),
      Vector2(220, 280),
      Vector2(360, 300),
      Vector2(90, 450),
      Vector2(220, 450),
      Vector2(360, 500),
      Vector2(160, 600),
      Vector2(360, 720),
      Vector2(60, 650),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 80, 1.0),
      (60, 200, 0.95),
      (420, 380, 1.1),
      (60, 540, 1.05),
      (240, 720, 0.95),
    ],
  );

  static final shelf = _assemble(
    name: 'Shelf',
    waypoints: <Vector2>[
      Vector2(480, 160),
      Vector2(300, 160),
      Vector2(300, 320),
      Vector2(120, 320),
      Vector2(120, 480),
      Vector2(300, 480),
      Vector2(300, 640),
      Vector2(0, 640),
    ],
    rawSlots: <Vector2>[
      Vector2(400, 80),
      Vector2(220, 80),
      Vector2(400, 250),
      Vector2(220, 250),
      Vector2(60, 250),
      Vector2(220, 400),
      Vector2(400, 400),
      Vector2(60, 560),
      Vector2(220, 560),
      Vector2(400, 560),
      Vector2(220, 720),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 80, 1.0),
      (420, 320, 1.05),
      (60, 400, 0.95),
      (420, 720, 1.1),
      (300, 760, 0.9),
    ],
  );

  static final summit = _assemble(
    name: 'Summit',
    waypoints: <Vector2>[
      Vector2(60, 800),
      Vector2(60, 650),
      Vector2(180, 560),
      Vector2(300, 470),
      Vector2(420, 380),
      Vector2(300, 290),
      Vector2(180, 200),
      Vector2(300, 110),
      Vector2(480, 110),
    ],
    rawSlots: <Vector2>[
      Vector2(150, 720),
      Vector2(270, 650),
      Vector2(90, 560),
      Vector2(240, 520),
      Vector2(390, 520),
      Vector2(180, 380),
      Vector2(330, 380),
      Vector2(90, 250),
      Vector2(240, 240),
      Vector2(390, 240),
      Vector2(180, 80),
      Vector2(390, 40),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 760, 1.0),
      (60, 470, 1.05),
      (420, 620, 0.95),
      (60, 120, 1.1),
      (300, 340, 0.9),
    ],
  );

  static final turnstile = _assemble(
    name: 'Turnstile',
    waypoints: <Vector2>[
      Vector2(240, 0),
      Vector2(240, 180),
      Vector2(60, 180),
      Vector2(60, 340),
      Vector2(420, 340),
      Vector2(420, 500),
      Vector2(60, 500),
      Vector2(60, 660),
      Vector2(240, 660),
      Vector2(240, 800),
    ],
    rawSlots: <Vector2>[
      Vector2(120, 90),
      Vector2(360, 90),
      Vector2(180, 260),
      Vector2(300, 260),
      Vector2(180, 420),
      Vector2(300, 420),
      Vector2(180, 580),
      Vector2(300, 580),
      Vector2(120, 730),
      Vector2(360, 730),
      Vector2(420, 220),
      Vector2(420, 620),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 60, 1.0),
      (420, 60, 1.0),
      (240, 340, 1.1),
      (240, 500, 0.9),
      (60, 760, 1.05),
      (420, 760, 0.95),
    ],
  );

  static final valley = _assemble(
    name: 'Valley',
    waypoints: <Vector2>[
      Vector2(0, 720),
      Vector2(160, 720),
      Vector2(160, 520),
      Vector2(320, 520),
      Vector2(320, 320),
      Vector2(160, 320),
      Vector2(160, 120),
      Vector2(480, 120),
    ],
    rawSlots: <Vector2>[
      Vector2(80, 640),
      Vector2(240, 640),
      Vector2(400, 640),
      Vector2(80, 440),
      Vector2(240, 440),
      Vector2(400, 440),
      Vector2(80, 240),
      Vector2(240, 240),
      Vector2(400, 240),
      Vector2(80, 60),
      Vector2(300, 60),
      Vector2(420, 60),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 760, 1.0),
      (420, 760, 1.05),
      (60, 520, 0.9),
      (420, 520, 1.1),
      (60, 320, 0.95),
      (300, 180, 1.0),
    ],
  );

  static final weave = _assemble(
    name: 'Weave',
    waypoints: <Vector2>[
      Vector2(480, 760),
      Vector2(360, 760),
      Vector2(360, 600),
      Vector2(120, 600),
      Vector2(120, 440),
      Vector2(360, 440),
      Vector2(360, 280),
      Vector2(120, 280),
      Vector2(120, 120),
      Vector2(480, 120),
    ],
    rawSlots: <Vector2>[
      Vector2(420, 680),
      Vector2(240, 680),
      Vector2(60, 680),
      Vector2(240, 520),
      Vector2(420, 520),
      Vector2(60, 520),
      Vector2(240, 360),
      Vector2(420, 360),
      Vector2(60, 360),
      Vector2(240, 200),
      Vector2(420, 200),
      Vector2(60, 60),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 760, 1.0),
      (420, 600, 0.95),
      (240, 600, 1.05),
      (420, 440, 1.1),
      (240, 280, 0.9),
      (60, 200, 1.0),
    ],
  );

  static final frostPass = _assemble(
    name: 'Frost Pass',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(0, 180),
      Vector2(140, 180),
      Vector2(140, 360),
      Vector2(340, 360),
      Vector2(340, 540),
      Vector2(140, 540),
      Vector2(140, 700),
      Vector2(480, 700),
    ],
    rawSlots: <Vector2>[
      Vector2(70, 100),
      Vector2(240, 100),
      Vector2(240, 270),
      Vector2(70, 300),
      Vector2(410, 300),
      Vector2(240, 450),
      Vector2(410, 450),
      Vector2(70, 620),
      Vector2(280, 620),
      Vector2(410, 620),
    ],
    rawRocks: const <(double, double, double)>[
      (420, 90, 1.0),
      (220, 210, 0.95),
      (420, 210, 1.05),
      (70, 450, 1.0),
      (260, 540, 0.9),
      (420, 760, 1.1),
    ],
  );

  static final snowSpiral = _assemble(
    name: 'Snow Spiral',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(480, 90),
      Vector2(90, 90),
      Vector2(90, 250),
      Vector2(390, 250),
      Vector2(390, 430),
      Vector2(140, 430),
      Vector2(140, 640),
      Vector2(480, 640),
    ],
    rawSlots: <Vector2>[
      Vector2(240, 170),
      Vector2(456, 170),
      Vector2(210, 330),
      Vector2(310, 330),
      Vector2(60, 360),
      Vector2(240, 520),
      Vector2(420, 520),
      Vector2(60, 560),
      Vector2(240, 720),
      Vector2(420, 720),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 40, 1.0),
      (420, 40, 0.95),
      (60, 310, 1.05),
      (420, 310, 0.9),
      (240, 590, 1.0),
      (60, 760, 1.05),
    ],
  );

  static final iceBridge = _assemble(
    name: 'Ice Bridge',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(240, 0),
      Vector2(240, 170),
      Vector2(60, 170),
      Vector2(60, 340),
      Vector2(420, 340),
      Vector2(420, 520),
      Vector2(60, 520),
      Vector2(60, 690),
      Vector2(480, 690),
    ],
    rawSlots: <Vector2>[
      Vector2(150, 80),
      Vector2(330, 80),
      Vector2(150, 250),
      Vector2(300, 250),
      Vector2(180, 430),
      Vector2(300, 430),
      Vector2(420, 430),
      Vector2(180, 600),
      Vector2(300, 600),
      Vector2(420, 600),
      Vector2(180, 750),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 70, 1.0),
      (420, 70, 1.0),
      (240, 340, 1.1),
      (240, 520, 0.95),
      (60, 760, 0.9),
    ],
  );

  static final pineRing = _assemble(
    name: 'Pine Ring',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(0, 100),
      Vector2(320, 100),
      Vector2(320, 230),
      Vector2(80, 230),
      Vector2(80, 390),
      Vector2(340, 390),
      Vector2(340, 620),
      Vector2(480, 620),
    ],
    rawSlots: <Vector2>[
      Vector2(180, 40),
      Vector2(320, 40),
      Vector2(360, 190),
      Vector2(360, 330),
      Vector2(360, 640),
      Vector2(220, 640),
      Vector2(120, 590),
      Vector2(170, 340),
      Vector2(250, 320),
      Vector2(250, 470),
      Vector2(420, 440),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 40, 1.0),
      (240, 160, 0.95),
      (420, 240, 1.05),
      (60, 450, 1.1),
      (240, 700, 0.9),
      (420, 760, 1.0),
    ],
  );

  static final glacierGate = _assemble(
    name: 'Glacier Gate',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(0, 740),
      Vector2(180, 740),
      Vector2(180, 580),
      Vector2(350, 580),
      Vector2(350, 330),
      Vector2(130, 330),
      Vector2(130, 80),
      Vector2(480, 80),
    ],
    rawSlots: <Vector2>[
      Vector2(80, 660),
      Vector2(270, 680),
      Vector2(430, 680),
      Vector2(90, 500),
      Vector2(260, 480),
      Vector2(430, 480),
      Vector2(250, 250),
      Vector2(430, 250),
      Vector2(70, 210),
      Vector2(260, 40),
      Vector2(420, 160),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 760, 1.0),
      (420, 760, 1.1),
      (80, 400, 0.95),
      (240, 360, 1.05),
      (420, 360, 0.9),
      (60, 40, 1.0),
    ],
  );

  static final whiteMaze = _assemble(
    name: 'White Maze',
    theme: MapTheme.winter,
    waypoints: <Vector2>[
      Vector2(480, 760),
      Vector2(360, 760),
      Vector2(360, 620),
      Vector2(120, 620),
      Vector2(120, 480),
      Vector2(420, 480),
      Vector2(420, 330),
      Vector2(60, 330),
      Vector2(60, 180),
      Vector2(300, 180),
      Vector2(300, 0),
    ],
    rawSlots: <Vector2>[
      Vector2(420, 690),
      Vector2(240, 690),
      Vector2(60, 690),
      Vector2(240, 550),
      Vector2(420, 560),
      Vector2(60, 420),
      Vector2(240, 400),
      Vector2(420, 240),
      Vector2(180, 250),
      Vector2(60, 90),
      Vector2(420, 90),
      Vector2(220, 90),
    ],
    rawRocks: const <(double, double, double)>[
      (60, 760, 1.0),
      (420, 620, 1.05),
      (240, 480, 0.95),
      (420, 400, 1.1),
      (180, 180, 0.9),
      (60, 250, 1.0),
    ],
  );

  static final List<GameMap> winterAll = [
    frostPass,
    snowSpiral,
    iceBridge,
    pineRing,
    glacierGate,
    whiteMaze,
    ...List.generate(24, (index) => _winterGeneratedMap(index + 7)),
  ];

  static GameMap _winterGeneratedMap(int id) {
    if (id == 8) {
      return _assemble(
        name: 'Winter Maze 8',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(0, 90),
          Vector2(180, 90),
          Vector2(180, 220),
          Vector2(80, 220),
          Vector2(80, 350),
          Vector2(300, 350),
          Vector2(300, 180),
          Vector2(410, 180),
          Vector2(410, 520),
          Vector2(180, 520),
          Vector2(180, 650),
          Vector2(300, 650),
          Vector2(300, 720),
          Vector2(480, 720),
        ],
        rawSlots: <Vector2>[
          Vector2(90, 40),
          Vector2(270, 70),
          Vector2(110, 150),
          Vector2(250, 260),
          Vector2(380, 300),
          Vector2(170, 420),
          Vector2(300, 460),
          Vector2(450, 610),
          Vector2(90, 610),
          Vector2(240, 585),
          Vector2(390, 710),
          Vector2(90, 735),
        ],
        rawRocks: const <(double, double, double)>[
          (300, 40, 1.0),
          (60, 150, 0.95),
          (250, 210, 1.05),
          (420, 300, 0.9),
          (90, 470, 1.1),
          (330, 590, 0.95),
          (420, 760, 1.0),
        ],
      );
    }
    if (id == 10) {
      return _assemble(
        name: 'Winter Maze 10',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(240, 0),
          Vector2(240, 95),
          Vector2(75, 95),
          Vector2(75, 245),
          Vector2(345, 245),
          Vector2(345, 405),
          Vector2(125, 405),
          Vector2(125, 560),
          Vector2(350, 560),
          Vector2(350, 700),
          Vector2(480, 700),
        ],
        rawSlots: <Vector2>[
          Vector2(130, 40),
          Vector2(345, 55),
          Vector2(160, 170),
          Vector2(270, 170),
          Vector2(430, 170),
          Vector2(250, 330),
          Vector2(430, 330),
          Vector2(60, 360),
          Vector2(245, 485),
          Vector2(430, 485),
          Vector2(70, 665),
          Vector2(250, 675),
        ],
        rawRocks: const <(double, double, double)>[
          (60, 50, 1.0),
          (420, 60, 0.95),
          (210, 245, 1.05),
          (60, 485, 0.9),
          (300, 560, 1.1),
          (420, 640, 0.95),
          (180, 750, 1.0),
        ],
      );
    }
    if (id == 16) {
      return _assemble(
        name: 'Winter Run 16',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(0, 135),
          Vector2(350, 135),
          Vector2(350, 260),
          Vector2(90, 260),
          Vector2(90, 415),
          Vector2(390, 415),
          Vector2(390, 560),
          Vector2(150, 560),
          Vector2(150, 705),
          Vector2(480, 705),
        ],
        rawSlots: <Vector2>[
          Vector2(130, 60),
          Vector2(260, 60),
          Vector2(430, 210),
          Vector2(230, 190),
          Vector2(210, 340),
          Vector2(430, 340),
          Vector2(60, 505),
          Vector2(260, 500),
          Vector2(430, 660),
          Vector2(280, 640),
          Vector2(70, 720),
        ],
        rawRocks: const <(double, double, double)>[
          (60, 50, 1.0),
          (430, 60, 1.05),
          (250, 260, 0.95),
          (60, 350, 1.1),
          (300, 415, 0.9),
          (430, 520, 1.0),
          (250, 740, 0.95),
        ],
      );
    }
    if (id == 20) {
      return _assemble(
        name: 'Winter Run 20',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(75, 0),
          Vector2(75, 155),
          Vector2(325, 155),
          Vector2(325, 310),
          Vector2(125, 310),
          Vector2(125, 470),
          Vector2(380, 470),
          Vector2(380, 620),
          Vector2(210, 620),
          Vector2(210, 735),
          Vector2(480, 735),
        ],
        rawSlots: <Vector2>[
          Vector2(170, 70),
          Vector2(300, 70),
          Vector2(200, 235),
          Vector2(430, 235),
          Vector2(55, 390),
          Vector2(250, 390),
          Vector2(430, 390),
          Vector2(250, 545),
          Vector2(430, 545),
          Vector2(90, 640),
          Vector2(330, 705),
        ],
        rawRocks: const <(double, double, double)>[
          (420, 60, 1.0),
          (60, 230, 0.95),
          (250, 310, 1.05),
          (60, 540, 1.1),
          (320, 620, 0.9),
          (430, 680, 1.0),
          (90, 760, 0.95),
        ],
      );
    }
    if (id == 22) {
      return _assemble(
        name: 'Winter Run 22',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(240, 0),
          Vector2(240, 120),
          Vector2(85, 120),
          Vector2(85, 285),
          Vector2(365, 285),
          Vector2(365, 440),
          Vector2(115, 440),
          Vector2(115, 600),
          Vector2(350, 600),
          Vector2(350, 725),
          Vector2(480, 725),
        ],
        rawSlots: <Vector2>[
          Vector2(135, 55),
          Vector2(350, 60),
          Vector2(180, 205),
          Vector2(310, 205),
          Vector2(430, 205),
          Vector2(235, 365),
          Vector2(430, 365),
          Vector2(60, 525),
          Vector2(255, 525),
          Vector2(430, 535),
          Vector2(250, 690),
          Vector2(70, 720),
        ],
        rawRocks: const <(double, double, double)>[
          (60, 60, 1.0),
          (420, 70, 0.95),
          (250, 285, 1.05),
          (60, 370, 1.1),
          (310, 440, 0.9),
          (420, 650, 1.0),
          (180, 760, 0.95),
        ],
      );
    }
    if (id == 26) {
      return _assemble(
        name: 'Winter Run 26',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(65, 0),
          Vector2(65, 125),
          Vector2(360, 125),
          Vector2(360, 285),
          Vector2(105, 285),
          Vector2(105, 445),
          Vector2(340, 445),
          Vector2(340, 590),
          Vector2(170, 590),
          Vector2(170, 720),
          Vector2(480, 720),
        ],
        rawSlots: <Vector2>[
          Vector2(155, 55),
          Vector2(300, 55),
          Vector2(210, 205),
          Vector2(430, 205),
          Vector2(55, 365),
          Vector2(235, 365),
          Vector2(430, 365),
          Vector2(235, 520),
          Vector2(430, 520),
          Vector2(75, 655),
          Vector2(310, 685),
        ],
        rawRocks: const <(double, double, double)>[
          (420, 60, 1.0),
          (60, 220, 0.95),
          (250, 285, 1.05),
          (60, 520, 1.1),
          (300, 590, 0.9),
          (430, 660, 1.0),
          (90, 760, 0.95),
        ],
      );
    }
    if (id == 28) {
      return _assemble(
        name: 'Winter Run 28',
        theme: MapTheme.winter,
        waypoints: <Vector2>[
          Vector2(240, 0),
          Vector2(240, 105),
          Vector2(380, 105),
          Vector2(380, 255),
          Vector2(95, 255),
          Vector2(95, 410),
          Vector2(355, 410),
          Vector2(355, 575),
          Vector2(135, 575),
          Vector2(135, 710),
          Vector2(480, 710),
        ],
        rawSlots: <Vector2>[
          Vector2(135, 55),
          Vector2(330, 185),
          Vector2(210, 180),
          Vector2(430, 185),
          Vector2(55, 335),
          Vector2(235, 335),
          Vector2(430, 335),
          Vector2(235, 495),
          Vector2(430, 500),
          Vector2(60, 650),
          Vector2(285, 650),
          Vector2(420, 760),
        ],
        rawRocks: const <(double, double, double)>[
          (60, 60, 1.0),
          (420, 60, 1.05),
          (260, 255, 0.95),
          (60, 485, 1.1),
          (280, 575, 0.9),
          (430, 645, 1.0),
          (190, 760, 0.95),
        ],
      );
    }

    final tier = ((id - 7) / 6).floor();
    final pattern = (id - 7) % 6;
    final shift = tier * 18.0;
    final low = 110.0 + shift;
    final mid = 300.0 + shift * 0.35;
    final high = 660.0 - shift * 0.25;

    switch (pattern) {
      case 0:
        return _assemble(
          name: 'Winter Shelf $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(0, low),
            Vector2(350, low),
            Vector2(350, mid),
            Vector2(90, mid),
            Vector2(90, high - 110),
            Vector2(350, high - 110),
            Vector2(350, high),
            Vector2(480, high),
          ],
          rawSlots: <Vector2>[
            Vector2(170, low - 65),
            Vector2(310, low - 65),
            Vector2(210, mid - 80),
            Vector2(420, mid - 40),
            Vector2(210, mid + 80),
            Vector2(60, mid + 80),
            Vector2(210, high - 190),
            Vector2(420, high - 190),
            Vector2(210, high - 40),
            Vector2(60, high - 40),
            Vector2(420, high - 40),
          ],
          rawRocks: const <(double, double, double)>[
            (60, 60, 1.0),
            (420, 60, 1.05),
            (240, 240, 0.95),
            (420, 430, 1.1),
            (60, 610, 0.9),
            (240, 760, 1.0),
          ],
        );
      case 1:
        return _assemble(
          name: 'Winter Hook $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(70, 0),
            Vector2(70, high - 70),
            Vector2(300, high - 70),
            Vector2(300, low + 120),
            Vector2(170, low + 120),
            Vector2(170, mid + 120),
            Vector2(480, mid + 120),
          ],
          rawSlots: <Vector2>[
            Vector2(150, 90),
            Vector2(150, 240),
            Vector2(150, 400),
            Vector2(150, 560),
            Vector2(240, high - 120),
            Vector2(420, high - 130),
            Vector2(380, low + 40),
            Vector2(380, mid),
            Vector2(260, mid + 40),
            Vector2(420, mid + 200),
            Vector2(80, 730),
          ],
          rawRocks: const <(double, double, double)>[
            (250, 80, 1.0),
            (420, 80, 1.1),
            (80, 460, 0.95),
            (300, 620, 1.0),
            (420, 760, 1.05),
          ],
        );
      case 2:
        return _assemble(
          name: 'Winter Steps $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(40, 0),
            Vector2(40, low + 40),
            Vector2(160, low + 40),
            Vector2(160, mid - 40),
            Vector2(300, mid - 40),
            Vector2(300, mid + 120),
            Vector2(350, mid + 120),
            Vector2(350, high),
            Vector2(480, high),
          ],
          rawSlots: <Vector2>[
            Vector2(130, 70),
            Vector2(250, 80),
            Vector2(80, low + 120),
            Vector2(250, low + 110),
            Vector2(370, low + 140),
            Vector2(220, mid + 40),
            Vector2(420, mid + 40),
            Vector2(220, mid + 210),
            Vector2(430, mid + 230),
            Vector2(220, high - 30),
            Vector2(420, high - 30),
          ],
          rawRocks: const <(double, double, double)>[
            (320, 60, 1.0),
            (420, 140, 1.05),
            (80, 300, 0.95),
            (180, 430, 1.1),
            (420, 300, 0.9),
            (80, 650, 1.0),
          ],
        );
      case 3:
        return _assemble(
          name: 'Winter Ring $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(240, 0),
            Vector2(240, low),
            Vector2(360, low),
            Vector2(360, high),
            Vector2(80, high),
            Vector2(80, mid - 40),
            Vector2(300, mid - 40),
            Vector2(300, mid + 140),
            Vector2(480, mid + 140),
          ],
          rawSlots: <Vector2>[
            Vector2(150, 60),
            Vector2(330, 60),
            Vector2(350, low + 90),
            Vector2(350, mid),
            Vector2(350, high - 80),
            Vector2(220, high - 40),
            Vector2(100, high - 90),
            Vector2(170, mid - 120),
            Vector2(220, mid + 40),
            Vector2(390, mid + 70),
            Vector2(390, mid + 210),
          ],
          rawRocks: const <(double, double, double)>[
            (420, 60, 1.0),
            (60, 60, 1.0),
            (240, 250, 1.15),
            (240, 560, 0.95),
            (160, 420, 1.05),
            (420, 760, 1.1),
          ],
        );
      case 4:
        return _assemble(
          name: 'Winter Gate $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(0, mid),
            Vector2(180, mid),
            Vector2(180, low),
            Vector2(350, low),
            Vector2(350, mid + 190),
            Vector2(130, mid + 190),
            Vector2(130, high),
            Vector2(480, high),
          ],
          rawSlots: <Vector2>[
            Vector2(80, mid - 80),
            Vector2(260, low + 80),
            Vector2(420, low + 80),
            Vector2(270, mid - 10),
            Vector2(420, mid + 40),
            Vector2(70, mid + 90),
            Vector2(240, mid + 260),
            Vector2(420, mid + 260),
            Vector2(70, high - 70),
            Vector2(240, high - 40),
            Vector2(420, high - 40),
          ],
          rawRocks: const <(double, double, double)>[
            (60, 50, 1.0),
            (420, 50, 1.1),
            (240, 260, 0.9),
            (80, 390, 1.05),
            (420, 530, 0.95),
            (70, 720, 0.95),
          ],
          pathClearance: id == 17 ? 34 : 44,
        );
      default:
        return _assemble(
          name: 'Winter Weave $id',
          theme: MapTheme.winter,
          waypoints: <Vector2>[
            Vector2(480, high),
            Vector2(360, high),
            Vector2(360, high - 140),
            Vector2(120, high - 140),
            Vector2(120, mid + 70),
            Vector2(360, mid + 70),
            Vector2(360, mid - 100),
            Vector2(120, mid - 100),
            Vector2(120, low),
            Vector2(480, low),
          ],
          rawSlots: <Vector2>[
            Vector2(420, high - 70),
            Vector2(240, high - 70),
            Vector2(60, high - 70),
            Vector2(240, mid + 150),
            Vector2(420, mid + 150),
            Vector2(60, mid + 150),
            Vector2(240, mid),
            Vector2(420, mid),
            Vector2(60, mid),
            Vector2(240, low + 80),
            Vector2(420, low + 80),
          ],
          rawRocks: const <(double, double, double)>[
            (60, 760, 1.0),
            (420, 600, 0.95),
            (240, 600, 1.05),
            (420, 440, 1.1),
            (240, 280, 0.9),
            (60, 200, 1.0),
          ],
        );
    }
  }

  static final List<GameMap> all = [
    snake,
    zigzag,
    uLoop,
    cross,
    doubleLoop,
    maze,
    switchback,
    spiral,
    stairs,
    ring,
    gate,
    river,
    canyon,
    clover,
    braid,
    hourglass,
    terrace,
    fork,
    hook,
    island,
    ladder,
    loopback,
    pinch,
    rampart,
    saw,
    shelf,
    summit,
    turnstile,
    valley,
    weave,
    ...winterAll,
  ];

  static final _rng = Random();
  static GameMap random() => all[_rng.nextInt(all.length)];
}
