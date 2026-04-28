import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Hafif, kendini silen particle efekti — hit flash, ölüm patlaması.
class ParticleEffect extends PositionComponent {
  final Color color;
  final double duration;
  final double maxRadius;
  double _elapsed = 0;

  ParticleEffect({
    required Vector2 worldPosition,
    required this.color,
    this.duration = 0.35,
    this.maxRadius = 14,
  }) : super(
          position: worldPosition,
          anchor: Anchor.center,
          priority: 9,
        );

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = (_elapsed / duration).clamp(0.0, 1.0);
    final r = 3 + maxRadius * t;
    final paint = Paint()
      ..color = color.withValues(alpha: 1 - t)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, r, paint);

    // 6 küçük çizgi — patlama parıltısı
    final ringPaint = Paint()
      ..color = color.withValues(alpha: (1 - t) * 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    for (int i = 0; i < 6; i++) {
      final a = (i / 6) * 2 * pi;
      final p1 = Offset(cos(a) * r * 0.5, sin(a) * r * 0.5);
      final p2 = Offset(cos(a) * r * 1.2, sin(a) * r * 1.2);
      canvas.drawLine(p1, p2, ringPaint);
    }
  }
}
