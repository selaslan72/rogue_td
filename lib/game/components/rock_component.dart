import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';

/// Dövülebilir kaya. Path üstü, enemy altı (priority -5).
/// Kullanıcı tıklayınca "selected" olur — menzilindeki tower ateş eder.
/// HP 0'da yerine yeni TowerSlot açılır (td_game tarafında).
class RockComponent extends PositionComponent with TapCallbacks implements Damageable {
  final double sizeScale;
  final int seed;
  final int clusterId;
  final void Function(RockComponent rock)? onDestroyed;
  final void Function(RockComponent rock)? onTap;

  bool selected = false;
  double _hp;
  double _hitFlash = 0;

  RockComponent({
    required Vector2 worldPosition,
    this.sizeScale = 1.0,
    this.seed = 0,
    this.clusterId = -1,
    this.onDestroyed,
    this.onTap,
    double maxHp = 70,
  })  : _hp = maxHp,
        super(
          position: worldPosition,
          size: Vector2(28, 22) * sizeScale,
          anchor: Anchor.center,
          priority: -5,
        );

  @override
  bool onTapDown(TapDownEvent event) {
    onTap?.call(this);
    return true;
  }

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

    canvas.drawOval(
      Rect.fromCenter(center: Offset(cx, h - 2), width: w * 0.9, height: h * 0.25),
      _shadowPaint,
    );

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

    canvas.save();
    canvas.clipPath(body);
    canvas.drawRect(Rect.fromLTWH(0, cy + 2, w, h), _bodyDarkPaint);
    canvas.restore();

    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - w * 0.15, cy - h * 0.18),
          width: w * 0.35,
          height: h * 0.18),
      _highlightPaint,
    );

    if (selected) {
      canvas.drawPath(
        body,
        Paint()
          ..color = const Color(0xFFFBBF24)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }

    if (_hitFlash > 0) {
      canvas.drawPath(
        body,
        Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.55 * _hitFlash.clamp(0, 1)),
      );
    }
  }
}
