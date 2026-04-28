import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Dekoratif kaya. Path üstü, enemy altı (priority -5), ağaçlarla aynı katman.
/// Stil: yuvarlağımsı taş + alt gölge + üst highlight.
class RockComponent extends PositionComponent {
  final double sizeScale;
  final int seed;

  RockComponent({
    required Vector2 worldPosition,
    this.sizeScale = 1.0,
    this.seed = 0,
  }) : super(
          position: worldPosition,
          size: Vector2(28, 22) * sizeScale,
          anchor: Anchor.center,
          priority: -5,
        );

  static final _shadowPaint = Paint()..color = const Color(0x66000000);
  static final _bodyPaint = Paint()..color = const Color(0xFF6B7280);
  static final _bodyDarkPaint = Paint()..color = const Color(0xFF4B5563);
  static final _highlightPaint = Paint()..color = const Color(0xFFB7BFCB);
  static final _outlinePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.2;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;
    final cy = h / 2;

    // Alt gölge — toprağa basıyormuş hissi
    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 2), width: w * 0.9, height: h * 0.25),
      _shadowPaint,
    );

    // Ana gövde — düzensiz oval (seed'e göre hafif varyasyon)
    final rng = math.Random(seed);
    final body = Path();
    const steps = 10;
    for (int i = 0; i <= steps; i++) {
      final a = i * 2 * math.pi / steps - math.pi / 2;
      final jitter = 0.85 + rng.nextDouble() * 0.25;
      final rx = (w / 2 - 2) * jitter;
      final ry = (h / 2 - 4) * jitter;
      final px = cx + math.cos(a) * rx;
      final py = cy + math.sin(a) * ry;
      if (i == 0) {
        body.moveTo(px, py);
      } else {
        body.lineTo(px, py);
      }
    }
    body.close();
    canvas.drawPath(body, _bodyPaint);
    canvas.drawPath(body, _outlinePaint);

    // Alt yarıyı koyulaştır
    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(
        Rect.fromLTWH(0, cy + 2, w, h), _bodyDarkPaint);
    canvas.restore();

    // Üst highlight
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.15, cy - h * 0.18),
          width: w * 0.35,
          height: h * 0.18),
      _highlightPaint,
    );
  }
}
