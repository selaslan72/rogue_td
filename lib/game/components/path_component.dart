import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Yolu çizen bileşen. Waypoint listesini segment segment renderlar.
/// Düşmanlar bu listeyi [TdGame] üzerinden alıp takip eder.
class PathComponent extends PositionComponent {
  final List<Vector2> waypoints;
  final double pathWidth;
  final Paint _pathPaint;
  final Paint _borderPaint;

  PathComponent({
    required this.waypoints,
    this.pathWidth = 40,
  })  : _pathPaint = Paint()
          ..color = const Color(0xFF2A3A2A)
          ..strokeWidth = pathWidth
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
        _borderPaint = Paint()
          ..color = const Color(0xFF4A6A4A)
          ..strokeWidth = pathWidth + 4
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
        super(priority: -10); // arkaplan

  @override
  void render(Canvas canvas) {
    if (waypoints.length < 2) return;

    final path = Path()..moveTo(waypoints.first.x, waypoints.first.y);
    for (var i = 1; i < waypoints.length; i++) {
      path.lineTo(waypoints[i].x, waypoints[i].y);
    }

    canvas.drawPath(path, _borderPaint);
    canvas.drawPath(path, _pathPaint);
  }
}
