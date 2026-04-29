import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';

/// Dekoratif + dövülebilir ağaç. Path ve düşmanın altında render olur.
/// Towerlar enemy yokken menzilindeki en yakın ağacı vurur; hp 0'da yıkılır.
class TreeComponent extends PositionComponent implements Damageable {
  final double sizeScale;
  final int clusterId;
  final void Function(TreeComponent tree)? onDestroyed;

  double _hp;
  double get hp => _hp;
  double _hitFlash = 0;

  TreeComponent({
    required Vector2 worldPosition,
    this.sizeScale = 1.0,
    this.clusterId = -1,
    this.onDestroyed,
    double maxHp = 24,
  })  : _hp = maxHp,
        super(
          position: worldPosition,
          size: Vector2(24, 32) * sizeScale,
          anchor: Anchor.bottomCenter,
          priority: -5,
        );

  @override
  bool get isAlive => _hp > 0;

  @override
  Vector2 get worldPosition => position;

  @override
  void takeDamage(double amount) {
    if (_hp <= 0) return;
    _hp -= amount;
    _hitFlash = 1.0;
    if (_hp <= 0 && isMounted) {
      onDestroyed?.call(this);
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (_hitFlash > 0) _hitFlash -= dt * 4;
  }

  static final _trunkPaint = Paint()..color = const Color(0xFF6B3410);
  static final _trunkShadowPaint = Paint()..color = const Color(0xFF4A2208);
  static final _leafDarkPaint = Paint()..color = const Color(0xFF1F4A1F);
  static final _leafPaint = Paint()..color = const Color(0xFF2F6B2F);
  static final _leafLightPaint = Paint()..color = const Color(0xFF4A8A3A);
  static final _flashPaint = Paint()..color = const Color(0x88FFFFFF);

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

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

    if (_hitFlash > 0) {
      canvas.drawCircle(
        Offset(cx, canopyBottomY - h * 0.25),
        w * 0.55,
        Paint()..color = _flashPaint.color.withValues(alpha: 0.5 * _hitFlash.clamp(0, 1)),
      );
    }
  }
}
