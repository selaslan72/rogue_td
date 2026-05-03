import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../../models/enemy_def.dart';
import 'damageable.dart';
import 'particle_effect.dart';

/// Yol üzerinde waypoint'leri takip eden düşman.
/// HP bittiğinde ölür ve callback'le altın verir.
/// Yola sızarsa (son waypoint geçilirse) can düşürür.
class EnemyComponent extends PositionComponent implements Damageable {
  final EnemyDef def;
  final List<Vector2> waypoints;
  final void Function(EnemyComponent self) onKilled;
  final void Function(EnemyComponent self) onLeaked;

  late double _hp;
  int _waypointIndex = 1;
  double _slowMultiplier = 1.0;
  double _slowTimer = 0;
  double _animTime = 0;

  static final _hpBgPaint = Paint()..color = const Color(0xCC1A1A1A);
  static final _hpFillPaint = Paint()..color = const Color(0xFF4ADE80);
  static final _outlinePaint = Paint()
    ..color = Colors.black54
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final _eyePaint = Paint()..color = Colors.white;
  static final _chestBeltPaint = Paint()..color = Colors.black38;
  static final _slowRingPaint = Paint()
    ..color = const Color(0x8838BDF8)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;

  final double _armorBonus;
  late final Paint _bodyPaint;
  late final Paint _helmetPaint;

  EnemyComponent({
    required this.def,
    required this.waypoints,
    required this.onKilled,
    required this.onLeaked,
    double hpMultiplier = 1.0,
    double speedMultiplier = 1.0,
    double armorBonus = 0,
  }) : _hpMul = hpMultiplier,
       _speedMul = speedMultiplier,
       _armorBonus = armorBonus,
       super(
         position: waypoints.first.clone(),
         size: Vector2.all(20 * def.sizeScale),
         anchor: Anchor.center,
         priority: def.isBoss ? 6 : 5,
       ) {
    _hp = def.maxHp * _hpMul;
    _bodyPaint = Paint()..color = def.color;
    _helmetPaint = Paint()..color = Color.lerp(def.color, Colors.black, 0.45)!;
  }

  final double _hpMul;
  final double _speedMul;

  double get hpRatio => (_hp / (def.maxHp * _hpMul)).clamp(0.0, 1.0);
  @override
  bool get isAlive => _hp > 0;
  @override
  Vector2 get worldPosition => position;
  @override
  double get bodyRadius => 10.0 * def.sizeScale;
  double get pathProgress {
    if (waypoints.length < 2) return 0;
    if (_waypointIndex >= waypoints.length) return waypoints.length.toDouble();

    final previous = waypoints[_waypointIndex - 1];
    final target = waypoints[_waypointIndex];
    final segmentLength = previous.distanceTo(target);
    if (segmentLength <= 0) return (_waypointIndex - 1).toDouble();

    final segmentProgress = previous.distanceTo(position) / segmentLength;
    return (_waypointIndex - 1) + segmentProgress.clamp(0.0, 1.0);
  }

  @override
  void takeDamage(double amount) {
    if (!isAlive) return;
    final effective = (amount - def.armor - _armorBonus).clamp(0.0, double.infinity);
    _hp -= effective;
    if (_hp <= 0) {
      _hp = 0;
      parent?.add(
        ParticleEffect(
          worldPosition: worldPosition.clone(),
          color: def.color,
          duration: 0.45,
          maxRadius: def.isBoss ? 28 : 16,
        ),
      );
      onKilled(this);
      removeFromParent();
    }
  }

  void applySlow(double multiplier, double duration) {
    _slowMultiplier = multiplier;
    _slowTimer = duration;
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    _animTime += dt;

    if (_slowTimer > 0) {
      _slowTimer -= dt;
      if (_slowTimer <= 0) _slowMultiplier = 1.0;
    }

    if (_waypointIndex >= waypoints.length) {
      onLeaked(this);
      removeFromParent();
      return;
    }

    final target = waypoints[_waypointIndex];
    final delta = target - position;
    final distance = delta.length;
    final stepDistance = def.speed * _speedMul * _slowMultiplier * dt;

    if (distance <= stepDistance) {
      position.setFrom(target);
      _waypointIndex++;
    } else {
      position.add(delta.normalized() * stepDistance);
    }
  }

  @override
  void render(Canvas canvas) {
    if (def.isFlying) {
      _renderWings(canvas);
    }
    _renderSoldier(canvas);
    if (def.isBoss) {
      _renderCrown(canvas);
    }
    _renderHpBar(canvas);
    if (_slowMultiplier < 1.0) {
      canvas.drawCircle(
        Offset(size.x / 2, size.y / 2),
        size.x / 2 + 2,
        _slowRingPaint,
      );
    }
  }

  void _renderWings(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;
    final flap = sin(_animTime * 14) * 3;
    final wingPaint = Paint()..color = const Color(0xCCFFFFFF);
    final wingOutline = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final left = Path()
      ..moveTo(cx - 2, cy)
      ..quadraticBezierTo(cx - 12, cy - 6 - flap, cx - 14, cy - 1 - flap)
      ..quadraticBezierTo(cx - 9, cy + 1, cx - 2, cy);
    final right = Path()
      ..moveTo(cx + 2, cy)
      ..quadraticBezierTo(cx + 12, cy - 6 - flap, cx + 14, cy - 1 - flap)
      ..quadraticBezierTo(cx + 9, cy + 1, cx + 2, cy);
    canvas.drawPath(left, wingPaint);
    canvas.drawPath(right, wingPaint);
    canvas.drawPath(left, wingOutline);
    canvas.drawPath(right, wingOutline);
  }

  void _renderCrown(Canvas canvas) {
    final cx = size.x / 2;
    final crownY = 1.0;
    final crownW = size.x * 0.45;
    final crownH = 4.0;
    final paint = Paint()..color = const Color(0xFFFBBF24);
    final outline = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    final path = Path()
      ..moveTo(cx - crownW / 2, crownY + crownH)
      ..lineTo(cx - crownW / 2, crownY + crownH * 0.4)
      ..lineTo(cx - crownW / 4, crownY)
      ..lineTo(cx, crownY + crownH * 0.4)
      ..lineTo(cx + crownW / 4, crownY)
      ..lineTo(cx + crownW / 2, crownY + crownH * 0.4)
      ..lineTo(cx + crownW / 2, crownY + crownH)
      ..close();
    canvas.drawPath(path, paint);
    canvas.drawPath(path, outline);
  }

  void _renderSoldier(Canvas canvas) {
    final cx = size.x / 2;
    final isFast = def.kind == EnemyKind.fast;
    final isTank = def.kind == EnemyKind.tank;

    // Per-type body proportions
    final double headR = isTank
        ? 3.5
        : isFast
        ? 2.5
        : 3.0;
    final double headCY = isTank ? 5.0 : 4.0;
    final double bodyW = isTank
        ? 12.0
        : isFast
        ? 6.0
        : 8.0;
    final double bodyH = isTank
        ? 7.0
        : isFast
        ? 5.0
        : 6.0;
    final double bodyTop = headCY + headR + 1.0;
    final double bodyBot = bodyTop + bodyH;
    final double legW = isTank
        ? 3.0
        : isFast
        ? 1.5
        : 2.0;
    final double legH = (size.y - bodyBot).clamp(2.0, 9.0);
    final double legGap = isTank ? 3.0 : 2.0;
    final double armW = isTank ? 3.0 : 2.0;
    final double armH = isTank ? 6.0 : 4.0;
    final double helmetW = headR * 2.3;
    final double helmetH = isTank ? 3.0 : 2.0;

    // Leg swing animation
    final double speed = isFast
        ? 10.0
        : isTank
        ? 5.0
        : 7.0;
    final double swing = sin(_animTime * speed) * 0.8;

    final double lLegX = cx - legW - legGap / 2;
    final double rLegX = cx + legGap / 2;

    // --- Left leg ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(lLegX + swing, bodyBot, legW, legH),
        const Radius.circular(1.5),
      ),
      _bodyPaint,
    );
    // --- Right leg ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(rLegX - swing, bodyBot, legW, legH),
        const Radius.circular(1.5),
      ),
      _bodyPaint,
    );

    // --- Body ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
        const Radius.circular(2),
      ),
      _bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2, bodyTop, bodyW, bodyH),
        const Radius.circular(2),
      ),
      _outlinePaint,
    );

    // Chest belt stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 1.5, bodyTop + 2, 3, bodyH - 3),
        const Radius.circular(1),
      ),
      _chestBeltPaint,
    );

    // --- Left arm ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - bodyW / 2 - armW + 0.5, bodyTop + 1, armW, armH),
        const Radius.circular(1),
      ),
      _bodyPaint,
    );
    // --- Right arm ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + bodyW / 2 - 0.5, bodyTop + 1, armW, armH),
        const Radius.circular(1),
      ),
      _bodyPaint,
    );

    // --- Head ---
    canvas.drawCircle(Offset(cx, headCY), headR, _bodyPaint);
    canvas.drawCircle(Offset(cx, headCY), headR, _outlinePaint);

    // Eyes
    canvas.drawCircle(Offset(cx - 1.1, headCY + 0.5), 0.9, _eyePaint);
    canvas.drawCircle(Offset(cx + 1.1, headCY + 0.5), 0.9, _eyePaint);

    // --- Helmet ---
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          cx - helmetW / 2,
          headCY - headR - helmetH + 1.0,
          helmetW,
          helmetH,
        ),
        const Radius.circular(1),
      ),
      _helmetPaint,
    );
  }

  void _renderHpBar(Canvas canvas) {
    const barH = 3.0;
    final barW = size.x;
    const barY = -8.0;
    canvas.drawRect(Rect.fromLTWH(0, barY, barW, barH), _hpBgPaint);
    canvas.drawRect(Rect.fromLTWH(0, barY, barW * hpRatio, barH), _hpFillPaint);
  }
}
