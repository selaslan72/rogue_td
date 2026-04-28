import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../../models/run_stats.dart';
import '../../models/tower_card.dart';
import 'enemy_component.dart';
import 'particle_effect.dart';

/// Yerleştirilmiş tower. Range içindeki düşmanları tarayıp ateş eder.
/// MVP'de projectile yok — instant hit + flash + particle efekti.
class TowerComponent extends PositionComponent with TapCallbacks {
  final TowerCard card;
  final TargetingMode targeting;
  final void Function(TowerComponent) onTap;
  final RunStats stats;

  int level = 1; // 1..3

  double _cooldown = 0;
  EnemyComponent? _currentTarget;
  double _muzzleFlash = 0;

  late final Paint _bodyPaint;
  late final Paint _accentPaint;
  late final Paint _strokePaint;
  static final _rangeSelectedPaint = Paint()
    ..color = const Color(0x55FBBF24)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2;
  static final _flashPaint = Paint()..color = const Color(0xFFFBBF24);
  static final _basePaint = Paint()..color = const Color(0xFF374151);
  static final _baseOutlinePaint = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.5;
  static final _darkPaint = Paint()..color = const Color(0xFF1F2937);
  static final _whitePaint = Paint()..color = Colors.white;
  static final _levelOnPaint = Paint()..color = const Color(0xFFFBBF24);
  static final _levelOffPaint = Paint()..color = Colors.white24;

  bool showRange = false;

  // Level çarpanları
  double get _damageMul => level == 1 ? 1.0 : level == 2 ? 1.5 : 2.0;
  double get _rangeMul => 1.0 + (level - 1) * 0.10;
  double get _fireRateMul => 1.0 + (level - 1) * 0.20;

  double get currentDamage => card.damage * _damageMul * stats.damageMul;
  double get currentRange => card.range * _rangeMul * stats.rangeMul;
  double get currentFireRate => card.fireRate * _fireRateMul * stats.fireRateMul;

  bool get canUpgrade => level < 3;
  int get upgradeCost => (card.baseCost * (level == 1 ? 1.0 : 1.5)).round();

  void upgrade() {
    if (canUpgrade) level++;
  }

  TowerComponent({
    required this.card,
    required Vector2 worldPosition,
    required this.onTap,
    required this.stats,
    this.targeting = TargetingMode.first,
  }) : super(
          position: worldPosition,
          size: Vector2.all(36),
          anchor: Anchor.center,
          priority: 4,
        ) {
    _bodyPaint = Paint()..color = card.color;
    _accentPaint = Paint()..color = _lighten(card.color, 0.25);
    _strokePaint = Paint()
      ..color = _darken(card.color, 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
  }

  static Color _lighten(Color c, double t) =>
      Color.lerp(c, Colors.white, t) ?? c;
  static Color _darken(Color c, double t) =>
      Color.lerp(c, Colors.black, t) ?? c;

  @override
  bool onTapDown(TapDownEvent event) {
    onTap(this);
    return true;
  }

  @override
  void update(double dt) {
    super.update(dt);

    if (_cooldown > 0) _cooldown -= dt;
    if (_muzzleFlash > 0) _muzzleFlash -= dt * 4;

    if (_currentTarget != null) {
      if (!_currentTarget!.isMounted ||
          !_currentTarget!.isAlive ||
          !_inRange(_currentTarget!)) {
        _currentTarget = null;
      }
    }

    _currentTarget ??= _acquireTarget();

    if (_currentTarget != null && _cooldown <= 0) {
      _fire(_currentTarget!);
      _cooldown = 1.0 / currentFireRate;
      _muzzleFlash = 1.0;
    }
  }

  bool _inRange(EnemyComponent enemy) {
    return enemy.worldPosition.distanceTo(position) <= currentRange;
  }

  EnemyComponent? _acquireTarget() {
    final enemies = parent?.children.whereType<EnemyComponent>().where(_inRange);
    if (enemies == null || enemies.isEmpty) return null;

    switch (targeting) {
      case TargetingMode.first:
        return enemies.reduce(
          (a, b) => a.worldPosition.y > b.worldPosition.y ? a : b,
        );
      case TargetingMode.strongest:
        return enemies.reduce(
          (a, b) => a.def.maxHp > b.def.maxHp ? a : b,
        );
      case TargetingMode.weakest:
        return enemies.reduce(
          (a, b) => a.hpRatio < b.hpRatio ? a : b,
        );
      case TargetingMode.closest:
        return enemies.reduce(
          (a, b) => a.worldPosition.distanceTo(position) <
                  b.worldPosition.distanceTo(position)
              ? a
              : b,
        );
    }
  }

  void _spawnHit(Vector2 worldPos) {
    parent?.add(ParticleEffect(
      worldPosition: worldPos,
      color: card.color,
      duration: 0.3,
      maxRadius: 10,
    ));
  }

  void _fire(EnemyComponent target) {
    switch (card.type) {
      case TowerType.singleTarget:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
      case TowerType.splash:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
        const splashRadius = 60.0;
        final others = parent?.children.whereType<EnemyComponent>() ?? [];
        for (final e in others) {
          if (e != target &&
              e.worldPosition.distanceTo(target.worldPosition) <= splashRadius) {
            e.takeDamage(currentDamage * 0.6);
          }
        }
      case TowerType.slow:
        target.takeDamage(currentDamage);
        target.applySlow(0.5, 1.5);
        _spawnHit(target.worldPosition.clone());
      case TowerType.damageOverTime:
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
      case TowerType.chain:
        // Tesla = 2 zincir, Lightning = 3, Frost King = 3, default 2
        final chainCount = card.id == 'lightning' || card.id == 'frost-king' ? 3 : 2;
        target.takeDamage(currentDamage);
        _spawnHit(target.worldPosition.clone());
        var lastHit = target;
        var dmg = currentDamage * 0.7;
        final hit = <EnemyComponent>{target};
        for (int i = 1; i < chainCount; i++) {
          final next = _findChainNext(lastHit, hit);
          if (next == null) break;
          next.takeDamage(dmg);
          if (card.id == 'frost-king') next.applySlow(0.4, 1.2);
          _spawnHit(next.worldPosition.clone());
          hit.add(next);
          lastHit = next;
          dmg *= 0.7;
        }
      case TowerType.support:
        break;
    }
  }

  EnemyComponent? _findChainNext(EnemyComponent from, Set<EnemyComponent> hit) {
    const chainRadius = 80.0;
    EnemyComponent? best;
    double bestDist = chainRadius;
    final all = parent?.children.whereType<EnemyComponent>() ?? [];
    for (final e in all) {
      if (hit.contains(e) || !e.isAlive) continue;
      final d = e.worldPosition.distanceTo(from.worldPosition);
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  double _aimAngle() {
    if (_currentTarget != null) {
      final d = _currentTarget!.worldPosition - position;
      if (d.length2 > 0.01) return math.atan2(d.y, d.x);
    }
    return -math.pi / 2; // varsayılan: yukarı
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);

    if (showRange) {
      canvas.drawCircle(center, currentRange, _rangeSelectedPaint);
    }

    // Taban (tüm tower'lar için ortak — koyu disk)
    canvas.drawCircle(center, size.x / 2 - 2, _basePaint);
    canvas.drawCircle(center, size.x / 2 - 2, _baseOutlinePaint);

    // Karta özel silüet
    _renderModel(canvas, center);

    // Muzzle flash
    if (_muzzleFlash > 0 && _currentTarget != null) {
      final dir = (_currentTarget!.worldPosition - position).normalized();
      final tip = center + Offset(dir.x, dir.y) * (size.x / 2);
      canvas.drawCircle(tip, 4 * _muzzleFlash, _flashPaint);
    }

    // Level göstergesi — tabanda 3 dot
    if (level > 1) {
      const dotR = 3.0;
      const gap = 8.0;
      final startX = center.dx - gap;
      final dotY = center.dy + size.y / 2 - 4;
      for (int i = 0; i < 3; i++) {
        canvas.drawCircle(
          Offset(startX + i * gap, dotY),
          dotR,
          i < level ? _levelOnPaint : _levelOffPaint,
        );
      }
    }
  }

  // ─── Model çizimleri ────────────────────────────────────────────────────
  // 5 archetype × 3 level = 15 görsel varyant. Her tower upgrade'de
  // şekli görünür biçimde değişir (daha büyük/karmaşık silüet).

  void _renderModel(Canvas canvas, Offset center) {
    switch (card.id) {
      case 'archer':
        _renderBow(canvas, center, level);
      case 'cannon':
        _renderCannon(canvas, center, level);
      case 'frost':
        _renderFrost(canvas, center, level);
      case 'flame':
        _renderFlame(canvas, center, level);
      case 'tesla':
        _renderTesla(canvas, center, level);
      default:
        canvas.drawCircle(center, 8, _bodyPaint);
        canvas.drawCircle(center, 8, _strokePaint);
    }
  }

  void _withRotation(Canvas canvas, Offset center, double angle, void Function() draw) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);
    draw();
    canvas.restore();
  }

  // ── Archer ─────────────────────────────────────────────────────────────
  // L1: küçük yay + tek ok
  // L2: büyük yay + tek ok + sadak (yan disk)
  // L3: çift kollu çapraz yay (crossbow) + iki ok
  void _renderBow(Canvas canvas, Offset center, int lvl) {
    _withRotation(canvas, center, _aimAngle(), () {
      final bowPaint = Paint()
        ..color = card.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = lvl == 1 ? 2.0 : 2.8
        ..strokeCap = StrokeCap.round;
      final radius = lvl == 1 ? 8.0 : (lvl == 2 ? 11.0 : 12.0);
      final rect = Rect.fromCircle(center: const Offset(-4, 0), radius: radius);
      canvas.drawArc(rect, -math.pi / 2.2, math.pi / 1.1, false, bowPaint);
      // Kiriş
      canvas.drawLine(
          Offset(-4, -radius * 0.85), Offset(-4, radius * 0.85),
          Paint()..color = Colors.white70..strokeWidth = 1);
      // Ok (lar)
      final arrowLen = lvl == 3 ? 14.0 : 11.0;
      void drawArrow(double dy) {
        canvas.drawLine(Offset(-4, dy), Offset(arrowLen - 4, dy),
            Paint()..color = Colors.white..strokeWidth = 1.4);
        final tip = Path()
          ..moveTo(arrowLen - 1, dy)
          ..lineTo(arrowLen - 5, dy - 3)
          ..lineTo(arrowLen - 5, dy + 3)
          ..close();
        canvas.drawPath(tip, _whitePaint);
      }
      if (lvl == 3) {
        drawArrow(-3);
        drawArrow(3);
        // Crossbow: ikinci ark
        canvas.drawArc(
            Rect.fromCircle(center: const Offset(-7, 0), radius: 8),
            -math.pi / 2.2, math.pi / 1.1, false, bowPaint);
      } else {
        drawArrow(0);
      }
      if (lvl >= 2) {
        // Sadak — sağ yanda küçük disk
        canvas.drawCircle(const Offset(-9, -7), 2, _accentPaint);
        canvas.drawCircle(const Offset(-9, -7), 2, _strokePaint);
      }
    });
  }

  // ── Cannon ─────────────────────────────────────────────────────────────
  // L1: kısa namlu
  // L2: uzun + kalın namlu, gövde büyük
  // L3: çift namlu yan yana
  void _renderCannon(Canvas canvas, Offset center, int lvl) {
    _withRotation(canvas, center, _aimAngle(), () {
      final bodyR = lvl == 1 ? 6.5 : (lvl == 2 ? 8.0 : 9.0);
      // Gövde
      canvas.drawCircle(Offset.zero, bodyR, _bodyPaint);
      canvas.drawCircle(Offset.zero, bodyR, _strokePaint);
      // Cıvata noktaları (L2+)
      if (lvl >= 2) {
        final boltPaint = Paint()..color = const Color(0xFF111827);
        for (int i = 0; i < 4; i++) {
          final a = i * math.pi / 2 + math.pi / 4;
          canvas.drawCircle(
            Offset(math.cos(a) * (bodyR - 1.5), math.sin(a) * (bodyR - 1.5)),
            1.0, boltPaint,
          );
        }
      }
      void drawBarrel(double dy) {
        final length = lvl == 1 ? 9.0 : (lvl == 2 ? 13.0 : 12.0);
        final width = lvl == 1 ? 6.0 : (lvl == 2 ? 8.0 : 6.0);
        canvas.drawRect(
            Rect.fromLTWH(2, dy - width / 2, length, width), _darkPaint);
        canvas.drawCircle(
            Offset(2 + length, dy), width / 2 + 0.5, _strokePaint);
      }
      if (lvl == 3) {
        drawBarrel(-3.5);
        drawBarrel(3.5);
      } else {
        drawBarrel(0);
      }
    });
  }

  // ── Frost ──────────────────────────────────────────────────────────────
  // L1: 6-spoke flake
  // L2: 8-spoke + merkez taş
  // L3: 8-spoke + ek mini-spoke + dış kristal halkası
  void _renderFrost(Canvas canvas, Offset center, int lvl) {
    final spokes = lvl == 1 ? 6 : 8;
    final radius = lvl == 1 ? 10.0 : (lvl == 2 ? 12.0 : 14.0);
    final p = Paint()
      ..color = card.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < spokes; i++) {
      final a = i * 2 * math.pi / spokes;
      final tip = center + Offset(math.cos(a), math.sin(a)) * radius;
      canvas.drawLine(center, tip, p);
      final t1 = tip - Offset(math.cos(a) * 4, math.sin(a) * 4);
      final n = Offset(-math.sin(a), math.cos(a)) * 3;
      canvas.drawLine(t1, t1 + n, p);
      canvas.drawLine(t1, t1 - n, p);
    }
    if (lvl == 3) {
      // Dış kristal üçgenler
      final crystalPaint = Paint()..color = _accentPaint.color;
      for (int i = 0; i < 4; i++) {
        final a = i * math.pi / 2 + math.pi / 4;
        final c = center + Offset(math.cos(a), math.sin(a)) * (radius + 2);
        final tri = Path()
          ..moveTo(c.dx, c.dy - 2.5)
          ..lineTo(c.dx + 2, c.dy + 1.5)
          ..lineTo(c.dx - 2, c.dy + 1.5)
          ..close();
        canvas.drawPath(tri, crystalPaint);
      }
    }
    // Merkez
    if (lvl >= 2) {
      canvas.drawCircle(center, 3, _accentPaint);
      canvas.drawCircle(center, 3, _strokePaint);
    } else {
      canvas.drawCircle(center, 2.5, _whitePaint);
    }
  }

  // ── Flame ──────────────────────────────────────────────────────────────
  // L1: küçük tank + dar koni
  // L2: büyük tank + geniş koni
  // L3: çift nozul + çok geniş koni
  void _renderFlame(Canvas canvas, Offset center, int lvl) {
    _withRotation(canvas, center, _aimAngle(), () {
      final tankR = lvl == 1 ? 5.0 : (lvl == 2 ? 7.0 : 7.5);
      // Tank
      canvas.drawCircle(Offset(-3, 0), tankR, _bodyPaint);
      canvas.drawCircle(Offset(-3, 0), tankR, _strokePaint);
      void drawNozzle(double dy) {
        canvas.drawRect(Rect.fromLTWH(2, dy - 2, 6, 4), _darkPaint);
        // Koni
        final coneW = lvl == 1 ? 4.0 : (lvl == 2 ? 7.0 : 8.0);
        final coneH = lvl == 1 ? 5.0 : (lvl == 2 ? 7.0 : 8.0);
        final cone = Path()
          ..moveTo(8, dy - coneH / 2 + 1)
          ..lineTo(8 + coneW, dy - coneH / 2)
          ..lineTo(8 + coneW, dy + coneH / 2)
          ..lineTo(8, dy + coneH / 2 - 1)
          ..close();
        canvas.drawPath(cone, _accentPaint);
        canvas.drawPath(cone, _strokePaint);
      }
      if (lvl == 3) {
        drawNozzle(-4);
        drawNozzle(4);
      } else {
        drawNozzle(0);
      }
    });
  }

  // ── Tesla ──────────────────────────────────────────────────────────────
  // L1: 2 disk
  // L2: 3 disk + spark
  // L3: 3 disk + spark + iki yan mini-coil
  void _renderTesla(Canvas canvas, Offset center, int lvl) {
    final disks = lvl == 1 ? 2 : 3;
    final showSpark = lvl >= 2;
    // Bar
    canvas.drawRect(
        Rect.fromLTWH(center.dx - 1.5, center.dy - 10, 3, 20), _darkPaint);
    final h = 18.0 / (disks + 1);
    final diskW = lvl == 3 ? 16.0 : 14.0;
    for (int i = 0; i < disks; i++) {
      final y = center.dy - 9 + h * (i + 1);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, y), width: diskW, height: 4),
          _bodyPaint);
      canvas.drawOval(
          Rect.fromCenter(center: Offset(center.dx, y), width: diskW, height: 4),
          _strokePaint);
    }
    // Tepe topu
    final topR = lvl == 3 ? 3.5 : 2.5;
    canvas.drawCircle(Offset(center.dx, center.dy - 11), topR, _accentPaint);
    canvas.drawCircle(Offset(center.dx, center.dy - 11), topR, _strokePaint);
    if (showSpark) {
      final sparkPaint = Paint()
        ..color = _accentPaint.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round;
      final spark = Path()
        ..moveTo(center.dx + 4, center.dy - 12)
        ..lineTo(center.dx + 7, center.dy - 9)
        ..lineTo(center.dx + 5, center.dy - 7)
        ..lineTo(center.dx + 9, center.dy - 4);
      canvas.drawPath(spark, sparkPaint);
    }
    if (lvl == 3) {
      // Yan mini-coil'ler
      for (final dx in [-7.0, 7.0]) {
        canvas.drawRect(
            Rect.fromLTWH(center.dx + dx - 1, center.dy - 5, 2, 12), _darkPaint);
        canvas.drawCircle(Offset(center.dx + dx, center.dy - 6), 1.6, _accentPaint);
      }
    }
  }
}
