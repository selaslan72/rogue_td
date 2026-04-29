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
class PathData {
  PathData._();

  static const double pathWidth = 40;
  static const double slotRadius = 24;
  static const double slotSide = 48;

  // ─── Forest generator ─────────────────────────────────────────────────────

  /// Slot ölçüsünü baz alan hizalı ağaç grid'i. Path ve slotlardan uzak durur.
  static List<(double, double, double)> _forest({
    required List<Vector2> waypoints,
    required List<Vector2> slots,
    int seed = 1,
    double mapW = 480,
    double mapH = 800,
    double step = slotSide,
    double pathClearance = 36,
    double slotClearance = slotSide,
  }) {
    final result = <(double, double, double)>[];
    final xOffset = 24.0 + (seed % 2) * (step / 2);
    final yOffset = 40.0 + (seed % 3) * 8.0;
    for (double y = yOffset; y < mapH; y += step) {
      for (double x = xOffset; x < mapW; x += step) {
        final tx = x.clamp(16.0, mapW - 16.0);
        final ty = y.clamp(28.0, mapH - 4.0);

        bool blocked = false;
        for (int i = 0; i < waypoints.length - 1; i++) {
          final a = waypoints[i];
          final b = waypoints[i + 1];
          if (_distToSegment(tx, ty, a.x, a.y, b.x, b.y) < pathClearance) {
            blocked = true;
            break;
          }
        }
        if (blocked) continue;
        for (final s in slots) {
          final dx = s.x - tx;
          final dy = s.y - ty;
          if (dx * dx + dy * dy < slotClearance * slotClearance) {
            blocked = true;
            break;
          }
        }
        if (blocked) continue;

        result.add((tx, ty, 1.0));
      }
    }
    return result;
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

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 1 — SNAKE (S-yolu, soldan sağa)
  // ─────────────────────────────────────────────────────────────────────────
  static final snake = _buildSnake();
  static GameMap _buildSnake() {
    final waypoints = <Vector2>[
      Vector2(0, 200),
      Vector2(120, 200),
      Vector2(120, 360),
      Vector2(360, 360),
      Vector2(360, 540),
      Vector2(120, 540),
      Vector2(120, 700),
      Vector2(480, 700),
    ];
    final slots = <Vector2>[
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
    ];
    return GameMap(
      name: 'Snake',
      waypoints: waypoints,
      towerSlots: slots,
      treePositions: _forest(waypoints: waypoints, slots: slots, seed: 11),
      rockPositions: const <(double, double, double)>[
        (90, 100, 1.1),
        (380, 100, 0.95),
        (200, 410, 1.0),
        (380, 580, 1.15),
        (90, 770, 0.9),
        (390, 770, 1.05),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 2 — ZIGZAG (yukardan aşağı, 3 zigzag)
  // ─────────────────────────────────────────────────────────────────────────
  static final zigzag = _buildZigzag();
  static GameMap _buildZigzag() {
    final waypoints = <Vector2>[
      Vector2(60, 0),
      Vector2(60, 180),
      Vector2(420, 180),
      Vector2(420, 360),
      Vector2(60, 360),
      Vector2(60, 540),
      Vector2(420, 540),
      Vector2(420, 800),
    ];
    final slots = <Vector2>[
      Vector2(180, 90),
      Vector2(300, 90),
      Vector2(180, 270),
      Vector2(300, 270),
      Vector2(180, 450),
      Vector2(300, 450),
      Vector2(180, 630),
      Vector2(300, 630),
      Vector2(160, 720),
      Vector2(280, 720),
      Vector2(160, 130),
      Vector2(330, 470),
    ];
    return GameMap(
      name: 'Zigzag',
      waypoints: waypoints,
      towerSlots: slots,
      treePositions: _forest(waypoints: waypoints, slots: slots, seed: 22),
      rockPositions: const <(double, double, double)>[
        (130, 50, 1.0),
        (370, 50, 1.15),
        (350, 280, 0.9),
        (130, 460, 1.0),
        (380, 660, 0.95),
        (110, 660, 1.1),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 3 — U-LOOP (sol üst → aşağı → sağa → yukarı → sağ üst)
  // ─────────────────────────────────────────────────────────────────────────
  static final uLoop = _buildULoop();
  static GameMap _buildULoop() {
    final waypoints = <Vector2>[
      Vector2(80, 0),
      Vector2(80, 720),
      Vector2(400, 720),
      Vector2(400, 0),
    ];
    final slots = <Vector2>[
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
    ];
    return GameMap(
      name: 'U-Loop',
      waypoints: waypoints,
      towerSlots: slots,
      treePositions: _forest(waypoints: waypoints, slots: slots, seed: 33),
      rockPositions: const <(double, double, double)>[
        (160, 60, 1.0),
        (340, 60, 1.1),
        (240, 350, 1.15),
        (160, 470, 0.9),
        (340, 470, 1.0),
        (240, 770, 0.95),
      ],
    );
  }

  static final List<GameMap> all = [snake, zigzag, uLoop];

  static final _rng = Random();
  static GameMap random() => all[_rng.nextInt(all.length)];
}
