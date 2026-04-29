import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';
import 'particle_effect.dart';

enum ProjectileVisual { arrow, ball }

/// Tower'dan hedefe giden homing mermi.
/// Hedef ölürse son bilinen pozisyona uçar; çarpınca damage uygular,
/// splashRadius > 0 ise yakındaki Damageable'lara da hasar verir.
class ProjectileComponent extends PositionComponent {
  final Damageable target;
  final double damage;
  final Color color;
  final ProjectileVisual visual;
  final double speed;
  final double splashRadius;

  Vector2? _lastTargetPos;
  double _life = 3.0;

  ProjectileComponent({
    required Vector2 worldPosition,
    required this.target,
    required this.damage,
    required this.color,
    required this.visual,
    this.speed = 280,
    this.splashRadius = 0,
  }) : super(
         position: worldPosition,
         size: Vector2.all(10),
         anchor: Anchor.center,
         priority: 5,
       );

  Vector2 get worldPosition => position;

  @override
  void update(double dt) {
    super.update(dt);
    _life -= dt;
    if (_life <= 0) {
      removeFromParent();
      return;
    }

    Vector2 dest;
    if (target.isMounted && target.isAlive) {
      dest = target.worldPosition;
      _lastTargetPos = dest.clone();
    } else if (_lastTargetPos != null) {
      dest = _lastTargetPos!;
    } else {
      removeFromParent();
      return;
    }

    final delta = dest - position;
    final dist = delta.length;
    final step = speed * dt;
    if (dist <= step) {
      position.setFrom(dest);
      _impact();
      removeFromParent();
      return;
    }
    position += delta / dist * step;
  }

  void _impact() {
    final game = parent;
    if (game == null) return;

    final impactPos = position.clone();
    if (target.isMounted && target.isAlive) {
      target.takeDamage(damage);
    }
    if (splashRadius > 0) {
      for (final d in game.children.whereType<Damageable>()) {
        if (identical(d, target)) continue;
        if (!d.isAlive) continue;
        if (d.worldPosition.distanceTo(impactPos) <= splashRadius) {
          d.takeDamage(damage * 0.6);
        }
      }
    }
    game.add(
      ParticleEffect(
        worldPosition: impactPos,
        color: color,
        duration: 0.3,
        maxRadius: splashRadius > 0 ? 18 : 10,
      ),
    );
  }

  double _angle() {
    Vector2 dest;
    if (target.isMounted && target.isAlive) {
      dest = target.worldPosition;
    } else if (_lastTargetPos != null) {
      dest = _lastTargetPos!;
    } else {
      return 0;
    }
    final d = dest - position;
    if (d.length2 < 0.01) return 0;
    return math.atan2(d.y, d.x);
  }

  static final _shaftPaint = Paint()..color = Colors.white;
  static final _ballPaint = Paint()..color = const Color(0xFF111827);
  static final _ballHighlight = Paint()..color = Colors.white24;

  @override
  void render(Canvas canvas) {
    final c = Offset(size.x / 2, size.y / 2);
    canvas.save();
    canvas.translate(c.dx, c.dy);
    canvas.rotate(_angle());
    if (visual == ProjectileVisual.arrow) {
      // Şaft
      canvas.drawRect(const Rect.fromLTWH(-6, -0.7, 10, 1.4), _shaftPaint);
      // Uç
      final tip = Path()
        ..moveTo(5, 0)
        ..lineTo(1, -2.5)
        ..lineTo(1, 2.5)
        ..close();
      canvas.drawPath(tip, _shaftPaint);
      // Tüy (kart rengi)
      final feather = Paint()..color = color;
      final f = Path()
        ..moveTo(-6, 0)
        ..lineTo(-9, -2)
        ..lineTo(-7, 0)
        ..lineTo(-9, 2)
        ..close();
      canvas.drawPath(f, feather);
    } else {
      canvas.drawCircle(Offset.zero, 4, _ballPaint);
      canvas.drawCircle(const Offset(-1, -1), 1.5, _ballHighlight);
    }
    canvas.restore();
  }
}
