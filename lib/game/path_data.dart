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

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 1 — SNAKE (S-yolu, soldan sağa)
  // ─────────────────────────────────────────────────────────────────────────
  static final snake = GameMap(
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
    towerSlots: <Vector2>[
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
    treePositions: <(double, double, double)>[
      (40, 70, 1.0), (140, 70, 0.95), (240, 70, 1.05), (340, 70, 0.95), (440, 70, 1.0),
      (22, 220, 0.95), (22, 380, 1.0), (22, 540, 0.95),
      (460, 220, 0.95), (460, 380, 1.0), (460, 540, 0.95), (460, 670, 1.0),
      (260, 250, 0.85), (340, 470, 0.9), (260, 620, 0.85),
      (40, 770, 1.0), (140, 770, 0.95), (240, 770, 1.05), (340, 770, 0.95), (440, 770, 1.0),
    ],
    rockPositions: <(double, double, double)>[
      (90, 100, 1.1), (380, 100, 0.95),
      (200, 410, 1.0), (380, 580, 1.15),
      (90, 770, 0.9), (390, 770, 1.05),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 2 — ZIGZAG (yukardan aşağı, 3 zigzag)
  // ─────────────────────────────────────────────────────────────────────────
  static final zigzag = GameMap(
    name: 'Zigzag',
    waypoints: <Vector2>[
      Vector2(60, 0),
      Vector2(60, 180),
      Vector2(420, 180),
      Vector2(420, 360),
      Vector2(60, 360),
      Vector2(60, 540),
      Vector2(420, 540),
      Vector2(420, 800),
    ],
    towerSlots: <Vector2>[
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
    ],
    treePositions: <(double, double, double)>[
      (20, 60, 1.0), (20, 240, 0.95), (20, 420, 1.0), (20, 600, 0.95), (20, 760, 1.0),
      (460, 90, 0.95), (460, 270, 1.0), (460, 450, 0.95), (460, 630, 1.0),
      (240, 30, 0.9), (240, 220, 0.85), (240, 400, 0.9), (240, 580, 0.85), (240, 760, 0.9),
      (370, 220, 0.85), (110, 400, 0.85), (370, 580, 0.85),
      (110, 130, 0.8), (350, 720, 0.85),
    ],
    rockPositions: <(double, double, double)>[
      (130, 50, 1.0), (370, 50, 1.15),
      (350, 280, 0.9), (130, 460, 1.0),
      (380, 660, 0.95), (110, 660, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 3 — U-LOOP (sol üst → aşağı → sağa → yukarı → sağ üst)
  // ─────────────────────────────────────────────────────────────────────────
  static final uLoop = GameMap(
    name: 'U-Loop',
    waypoints: <Vector2>[
      Vector2(80, 0),
      Vector2(80, 640),
      Vector2(400, 640),
      Vector2(400, 0),
    ],
    towerSlots: <Vector2>[
      Vector2(160, 100),
      Vector2(160, 240),
      Vector2(160, 380),
      Vector2(160, 520),
      Vector2(320, 100),
      Vector2(320, 240),
      Vector2(320, 380),
      Vector2(320, 520),
      Vector2(240, 600),
      Vector2(240, 700),
      Vector2(20, 700),
      Vector2(460, 700),
    ],
    treePositions: <(double, double, double)>[
      (30, 60, 1.0), (30, 200, 0.95), (30, 340, 1.0), (30, 480, 0.95), (30, 620, 0.9),
      (450, 60, 1.0), (450, 200, 0.95), (450, 340, 1.0), (450, 480, 0.95), (450, 620, 0.9),
      (240, 30, 0.9), (240, 160, 0.85), (240, 320, 0.9), (240, 480, 0.85),
      (100, 770, 0.95), (240, 770, 1.0), (380, 770, 0.95),
      (60, 670, 0.85), (420, 670, 0.85),
    ],
    rockPositions: <(double, double, double)>[
      (160, 60, 1.0), (340, 60, 1.1),
      (240, 420, 1.15),
      (160, 660, 0.9), (340, 660, 1.0),
      (60, 770, 0.95), (420, 770, 0.95),
    ],
  );

  static final List<GameMap> all = [snake, zigzag, uLoop];

  static final _rng = Random();
  static GameMap random() => all[_rng.nextInt(all.length)];
}
