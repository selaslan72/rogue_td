import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Tesla zincir saldırısı için geçici yıldırım yayı.
/// from → to dünya koordinatlarında zikzak şimşek çizer, 0.15s'de solar.
class LightningArc extends PositionComponent {
  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double duration;
  final List<Offset> _points;
  double _elapsed = 0;

  LightningArc({
    required this.from,
    required this.to,
    required this.color,
    this.duration = 0.15,
    int seed = 0,
  })  : _points = _buildPath(from, to, seed),
        super(priority: 8);

  static List<Offset> _buildPath(Vector2 from, Vector2 to, int seed) {
    const segments = 7;
    final rng = math.Random(seed);
    final dir = to - from;
    final len = dir.length;
    if (len < 1) return [Offset(from.x, from.y), Offset(to.x, to.y)];
    final perp = Vector2(-dir.y / len, dir.x / len);
    final pts = <Offset>[Offset(from.x, from.y)];
    for (int i = 1; i < segments; i++) {
      final t = i / segments;
      final mid = from + dir * t;
      final j = (rng.nextDouble() - 0.5) * len * 0.28;
      pts.add(Offset(mid.x + perp.x * j, mid.y + perp.y * j));
    }
    pts.add(Offset(to.x, to.y));
    return pts;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _elapsed += dt;
    if (_elapsed >= duration) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1.0 - _elapsed / duration).clamp(0.0, 1.0);
    final path = Path();
    if (_points.isNotEmpty) {
      path.moveTo(_points[0].dx, _points[0].dy);
      for (int i = 1; i < _points.length; i++) {
        path.lineTo(_points[i].dx, _points[i].dy);
      }
    }
    // Glow
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: alpha * 0.35)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5.5
        ..strokeCap = StrokeCap.round,
    );
    // Core
    canvas.drawPath(
      path,
      Paint()
        ..color = color.withValues(alpha: alpha)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round,
    );
    // Bright white center
    canvas.drawPath(
      path,
      Paint()
        ..color = Colors.white.withValues(alpha: alpha * 0.6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7
        ..strokeCap = StrokeCap.round,
    );
  }
}
