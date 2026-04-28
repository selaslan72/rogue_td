import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dekoratif ağaç. Path ve düşmanın altında, arkaplan üstünde render olur.
/// Stil: kahverengi gövde + 2 katmanlı yeşil tepelik.
class TreeComponent extends PositionComponent {
  final double sizeScale;

  TreeComponent({
    required Vector2 worldPosition,
    this.sizeScale = 1.0,
  }) : super(
          position: worldPosition,
          size: Vector2(24, 32) * sizeScale,
          anchor: Anchor.bottomCenter,
          priority: -5, // path (-10) üstü, enemy (5) altı
        );

  static final _trunkPaint = Paint()..color = const Color(0xFF6B3410);
  static final _trunkShadowPaint = Paint()..color = const Color(0xFF4A2208);
  static final _leafDarkPaint = Paint()..color = const Color(0xFF1F4A1F);
  static final _leafPaint = Paint()..color = const Color(0xFF2F6B2F);
  static final _leafLightPaint = Paint()..color = const Color(0xFF4A8A3A);

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    // Gövde
    final trunkW = w * 0.25;
    final trunkH = h * 0.35;
    final trunkRect = Rect.fromLTWH(
      (w - trunkW) / 2,
      h - trunkH,
      trunkW,
      trunkH,
    );
    canvas.drawRect(trunkRect, _trunkPaint);
    canvas.drawRect(
      Rect.fromLTWH(trunkRect.left, trunkRect.top, trunkW * 0.3, trunkH),
      _trunkShadowPaint,
    );

    // Tepelik — 3 üst üste daire (büyük → küçük)
    final cx = w / 2;
    final canopyBottomY = h - trunkH + 4;

    canvas.drawCircle(
      Offset(cx, canopyBottomY - h * 0.15),
      w * 0.55,
      _leafDarkPaint,
    );
    canvas.drawCircle(
      Offset(cx, canopyBottomY - h * 0.30),
      w * 0.48,
      _leafPaint,
    );
    canvas.drawCircle(
      Offset(cx - w * 0.12, canopyBottomY - h * 0.42),
      w * 0.28,
      _leafLightPaint,
    );
  }
}
