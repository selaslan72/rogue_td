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
      // Üst sıra
      (40, 70, 1.0), (140, 70, 0.95), (240, 70, 1.05), (340, 70, 0.95), (440, 70, 1.0),
      // Üst orta
      (140, 170, 0.85), (340, 170, 0.85),
      // Sol kenar
      (22, 220, 0.95), (22, 300, 0.9), (22, 380, 1.0), (22, 460, 0.9), (22, 540, 0.95), (22, 660, 0.85),
      // Sağ kenar
      (460, 220, 0.95), (460, 300, 0.9), (460, 380, 1.0), (460, 460, 0.9), (460, 540, 0.95), (460, 670, 1.0),
      // İç boşluklar
      (260, 250, 0.85), (340, 470, 0.9), (200, 600, 0.8), (260, 620, 0.85), (340, 620, 0.85),
      // Alt sıra
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
      // Sol kenar
      (20, 60, 1.0), (20, 150, 0.85), (20, 240, 0.95), (20, 330, 0.9), (20, 420, 1.0),
      (20, 510, 0.85), (20, 600, 0.95), (20, 690, 0.9), (20, 770, 1.0),
      // Sağ kenar
      (460, 60, 0.9), (460, 150, 0.95), (460, 240, 1.0), (460, 330, 0.95), (460, 420, 0.9),
      (460, 510, 0.95), (460, 600, 1.0), (460, 690, 0.95),
      // Orta dikey kolon
      (240, 30, 0.9), (240, 100, 0.8), (240, 220, 0.85), (240, 290, 0.85),
      (240, 400, 0.9), (240, 470, 0.85), (240, 580, 0.85), (240, 650, 0.85), (240, 760, 0.9),
      // Boşluk doldurucular
      (110, 400, 0.85), (370, 220, 0.85), (370, 580, 0.85), (350, 720, 0.85),
    ],
    rockPositions: <(double, double, double)>[
      (130, 50, 1.0), (370, 50, 1.15),
      (350, 280, 0.9), (130, 460, 1.0),
      (380, 660, 0.95), (110, 660, 1.1),
    ],
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Harita 3 — U-LOOP (sol üst → aşağı → sağa → yukarı → sağ üst)
  // Y simetrisi: yol 0..720 (alt boşluk minimal)
  // ─────────────────────────────────────────────────────────────────────────
  static final uLoop = GameMap(
    name: 'U-Loop',
    waypoints: <Vector2>[
      Vector2(80, 0),
      Vector2(80, 720),
      Vector2(400, 720),
      Vector2(400, 0),
    ],
    towerSlots: <Vector2>[
      // İç dikey kolonlar (yolun arasında)
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
      // Alt — yatay yolun altı
      Vector2(20, 770),
      Vector2(460, 770),
    ],
    treePositions: <(double, double, double)>[
      // Sol kenar (yoğun)
      (30, 40, 1.0), (30, 130, 0.9), (30, 220, 0.95), (30, 310, 1.0), (30, 400, 0.9),
      (30, 490, 0.95), (30, 580, 0.85), (30, 670, 0.9),
      // Sağ kenar (yoğun)
      (450, 40, 1.0), (450, 130, 0.9), (450, 220, 0.95), (450, 310, 1.0), (450, 400, 0.9),
      (450, 490, 0.95), (450, 580, 0.85), (450, 670, 0.9),
      // Orta dikey (yolların arası)
      (240, 30, 0.9), (240, 130, 0.85), (240, 220, 0.9), (240, 320, 0.85),
      (240, 420, 0.9), (240, 520, 0.85), (240, 620, 0.9),
      // Alt sıra (yolun altı)
      (60, 770, 0.95), (140, 770, 0.9), (240, 770, 1.0), (340, 770, 0.9), (420, 770, 0.95),
    ],
    rockPositions: <(double, double, double)>[
      (160, 60, 1.0), (340, 60, 1.1),
      (240, 350, 1.15),
      (160, 470, 0.9), (340, 470, 1.0),
      (240, 770, 0.95),
    ],
  );

  static final List<GameMap> all = [snake, zigzag, uLoop];

  static final _rng = Random();
  static GameMap random() => all[_rng.nextInt(all.length)];
}
