import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// Boş tower slotu. Tıklanınca [TdGame] üzerinden seçim akışını tetikler.
/// Tower yerleştirildikten sonra `isOccupied = true` olur ve görseli kaybolur.
class TowerSlot extends PositionComponent with TapCallbacks {
  final void Function(TowerSlot slot) onTap;
  bool isOccupied = false;
  bool isHighlighted = false;

  static final _emptyPaint = Paint()
    ..color = const Color(0x33FFFFFF)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  static final _highlightPaint = Paint()
    ..color = const Color(0x66FBBF24)
    ..style = PaintingStyle.fill;

  static const double radius = 24;

  TowerSlot({
    required Vector2 worldPosition,
    required this.onTap,
  }) : super(
          position: worldPosition,
          size: Vector2.all(radius * 2),
          anchor: Anchor.center,
        );

  @override
  void render(Canvas canvas) {
    if (isOccupied) return;
    final center = Offset(size.x / 2, size.y / 2);
    if (isHighlighted) {
      canvas.drawCircle(center, radius, _highlightPaint);
    }
    canvas.drawCircle(center, radius, _emptyPaint);
    // İç dot
    canvas.drawCircle(
      center,
      4,
      Paint()..color = const Color(0x55FFFFFF),
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (isOccupied) return false;
    onTap(this);
    return true;
  }
}
