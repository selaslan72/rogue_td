import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';
import 'enemy_component.dart';
import 'particle_effect.dart';

enum ProjectileVisual { arrow, ball, iceShard, fireball }

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
  final double slowAmount;
  final double slowDuration;
  final double impactRadius;

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
    this.slowAmount = 0,
    this.slowDuration = 0,
    this.impactRadius = 0,
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
      if (slowAmount > 0 && target is EnemyComponent) {
        (target as EnemyComponent).applySlow(slowAmount, slowDuration);
      }
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
    final mxr = impactRadius > 0
        ? impactRadius
        : (splashRadius > 0 ? 18.0 : 10.0);
    final dur = visual == ProjectileVisual.iceShard ? 0.45 : 0.3;
    game.add(
      ParticleEffect(
        worldPosition: impactPos,
        color: color,
        duration: dur,
        maxRadius: mxr,
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
    switch (visual) {
      case ProjectileVisual.arrow:
        canvas.drawRect(const Rect.fromLTWH(-6, -0.7, 10, 1.4), _shaftPaint);
        final tip = Path()
          ..moveTo(5, 0)
          ..lineTo(1, -2.5)
          ..lineTo(1, 2.5)
          ..close();
        canvas.drawPath(tip, _shaftPaint);
        final feather = Paint()..color = color;
        final f = Path()
          ..moveTo(-6, 0)
          ..lineTo(-9, -2)
          ..lineTo(-7, 0)
          ..lineTo(-9, 2)
          ..close();
        canvas.drawPath(f, feather);
      case ProjectileVisual.ball:
        canvas.drawCircle(Offset.zero, 4, _ballPaint);
        canvas.drawCircle(const Offset(-1, -1), 1.5, _ballHighlight);
      case ProjectileVisual.iceShard:
        // Kristal kama: +x yönünde uçar
        final crystal = Path()
          ..moveTo(8, 0)        // ileri uç
          ..lineTo(3, -3.5)
          ..lineTo(-5, -2)
          ..lineTo(-8, 0)       // arka uç
          ..lineTo(-5, 2)
          ..lineTo(3, 3.5)
          ..close();
        canvas.drawPath(crystal, Paint()..color = color);
        canvas.drawPath(
          crystal,
          Paint()
            ..color = Colors.white70
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.8,
        );
        // İç parlaklık çizgisi
        canvas.drawLine(
          const Offset(-5, 0),
          const Offset(5, 0),
          Paint()
            ..color = Colors.white.withValues(alpha: 0.55)
            ..strokeWidth = 0.7,
        );
        // Arkada bırakılan iki küçük ışık noktası
        canvas.drawCircle(
          const Offset(-7, -1),
          1.0,
          Paint()..color = color.withValues(alpha: 0.6),
        );
        canvas.drawCircle(
          const Offset(-7, 1),
          1.0,
          Paint()..color = color.withValues(alpha: 0.6),
        );
      case ProjectileVisual.fireball:
        // Arka alev izi
        final trail = Path()
          ..moveTo(-3, 0)
          ..lineTo(-10, -3)
          ..lineTo(-14, 0)
          ..lineTo(-10, 3)
          ..close();
        canvas.drawPath(
          trail,
          Paint()..color = color.withValues(alpha: 0.55),
        );
        // Dış parıltı
        canvas.drawCircle(
          Offset.zero,
          6.5,
          Paint()..color = color.withValues(alpha: 0.28),
        );
        // Ana top
        canvas.drawCircle(Offset.zero, 4.5, Paint()..color = color);
        // Parlak merkez
        canvas.drawCircle(
          const Offset(-1.2, -1.2),
          1.8,
          Paint()..color = Colors.white.withValues(alpha: 0.85),
        );
    }
    canvas.restore();
  }
}
