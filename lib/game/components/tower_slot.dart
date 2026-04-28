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

  static final _centerPaint = Paint()..color = const Color(0x55FFFFFF);

  static const double side = 48;
  static const double cornerRadius = 4;

  TowerSlot({required Vector2 worldPosition, required this.onTap})
    : super(
        position: worldPosition,
        size: Vector2.all(side),
        anchor: Anchor.center,
      );

  @override
  void render(Canvas canvas) {
    if (isOccupied) return;
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(2),
      const Radius.circular(cornerRadius),
    );
    if (isHighlighted) {
      canvas.drawRRect(rrect, _highlightPaint);
    }
    canvas.drawRRect(rrect, _emptyPaint);

    final center = Offset(size.x / 2, size.y / 2);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 8, height: 8),
        const Radius.circular(2),
      ),
      _centerPaint,
    );
  }

  @override
  bool onTapDown(TapDownEvent event) {
    if (isOccupied) return false;
    onTap(this);
    return true;
  }
}
