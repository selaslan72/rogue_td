import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'damageable.dart';
import 'enemy_component.dart';
import 'particle_effect.dart';

/// Barracks tower'ından çıkan melee asker.
/// En yakın düşmana yürür, kontak menzilinde vurur, temasta hasar alır.
/// Ölünce parent tower respawn timer'ı başlatır (callback).
class SoldierComponent extends PositionComponent implements Damageable {
  final Color color;
  final Vector2 towerPos;
  final double recruitRange; // tower menzili — bu mesafenin dışına çıkmaz
  final double damage;       // her vuruşta verdiği hasar
  final double fireRate;     // saniyede vuruş sayısı
  final double maxHp;
  final double speed;
  final void Function() onDied;

  static const double contactRange = 14.0;

  late double _hp;
  double _attackCd = 0;
  double _hitFlash = 0;
  double _animTime = 0;
  EnemyComponent? _target;

  static final _bodyOutline = Paint()
    ..color = Colors.black87
    ..style = PaintingStyle.stroke
    ..strokeWidth = 0.8;
  static final _eyePaint = Paint()..color = Colors.white;
  static final _hpBgPaint = Paint()..color = const Color(0xCC1A1A1A);
  static final _hpFillPaint = Paint()..color = const Color(0xFF4ADE80);
  static final _swordPaint = Paint()..color = const Color(0xFFE5E7EB);

  late final Paint _bodyPaint;
  late final Paint _helmetPaint;

  SoldierComponent({
    required this.color,
    required this.towerPos,
    required this.recruitRange,
    required this.damage,
    required this.fireRate,
    required this.maxHp,
    required this.speed,
    required this.onDied,
    Vector2? spawnAt,
  }) : super(
          position: (spawnAt ?? towerPos).clone(),
          size: Vector2.all(16),
          anchor: Anchor.center,
          priority: 5,
        ) {
    _hp = maxHp;
    _bodyPaint = Paint()..color = color;
    _helmetPaint = Paint()..color = Color.lerp(color, Colors.black, 0.45)!;
  }

  @override
  bool get isAlive => _hp > 0;
  @override
  Vector2 get worldPosition => position;
  @override
  double get bodyRadius => 7.0;

  @override
  void takeDamage(double amount) {
    if (!isAlive) return;
    _hp -= amount;
    _hitFlash = 0.2;
    if (_hp <= 0) {
      _hp = 0;
      parent?.add(ParticleEffect(
        worldPosition: worldPosition.clone(),
        color: color,
        duration: 0.35,
        maxRadius: 12,
      ));
      onDied();
      removeFromParent();
    }
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!isAlive) return;

    _animTime += dt;
    if (_attackCd > 0) _attackCd -= dt;
    if (_hitFlash > 0) _hitFlash -= dt;

    // Hedef seçimi: mevcut hedef ölmüş/uzaklaşmışsa yenisini bul
    if (_target == null ||
        !_target!.isMounted ||
        !_target!.isAlive ||
        _target!.worldPosition.distanceTo(towerPos) > recruitRange + 24) {
      _target = _findNearestEnemy();
    }

    final t = _target;
    if (t == null) {
      // Düşman yok: kuleye geri dön (sadece çok uzaktaysa)
      final toTower = towerPos - position;
      if (toTower.length > 6) {
        position.add(toTower.normalized() * speed * 0.7 * dt);
      }
      return;
    }

    final delta = t.worldPosition - position;
    final dist = delta.length;

    if (dist > contactRange) {
      // Yürü — ama kule menzilinin dışına çıkma
      final stepDist = speed * dt;
      final move = delta.normalized() * stepDist;
      final next = position + move;
      if (next.distanceTo(towerPos) <= recruitRange + 8) {
        position.setFrom(next);
      } else {
        // Sınırda dur
        final towardEdge = (next - towerPos).normalized() * recruitRange;
        position.setFrom(towerPos + towardEdge);
      }
    } else {
      // Kontak: vur ve temas hasarı al
      if (_attackCd <= 0) {
        t.takeDamage(damage);
        _attackCd = 1.0 / fireRate;
      }
      // Düşman temas hasarı (saniyelik)
      _hp -= t.def.contactDamage * dt;
      if (_hp <= 0) {
        _hp = 0;
        parent?.add(ParticleEffect(
          worldPosition: worldPosition.clone(),
          color: color,
          duration: 0.35,
          maxRadius: 12,
        ));
        onDied();
        removeFromParent();
        return;
      }
    }
  }

  EnemyComponent? _findNearestEnemy() {
    final all = parent?.children.whereType<EnemyComponent>() ?? [];
    EnemyComponent? best;
    double bestDist = double.infinity;
    for (final e in all) {
      if (!e.isAlive) continue;
      // Tower menzilinin biraz dışına çıksa bile takip et — kovala
      if (e.worldPosition.distanceTo(towerPos) > recruitRange + 24) continue;
      final d = e.worldPosition.distanceTo(position);
      if (d < bestDist) {
        bestDist = d;
        best = e;
      }
    }
    return best;
  }

  double _facingAngle() {
    if (_target != null && _target!.isAlive) {
      final d = _target!.worldPosition - position;
      if (d.length2 > 0.01) return math.atan2(d.y, d.x);
    }
    return -math.pi / 2;
  }

  @override
  void render(Canvas canvas) {
    final cx = size.x / 2;
    final cy = size.y / 2;

    // Hit flash arka halka
    if (_hitFlash > 0) {
      final p = Paint()
        ..color = Colors.white.withValues(alpha: _hitFlash * 3.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(Offset(cx, cy), bodyRadius + 1, p);
    }

    // Bacak salınımı
    final swing = math.sin(_animTime * 9) * 0.7;

    // Bacaklar
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 2.5 + swing, cy + 2, 1.6, 5),
        const Radius.circular(1),
      ),
      _bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx + 0.9 - swing, cy + 2, 1.6, 5),
        const Radius.circular(1),
      ),
      _bodyPaint,
    );

    // Gövde
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 3, cy - 2, 6, 5),
        const Radius.circular(1.5),
      ),
      _bodyPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 3, cy - 2, 6, 5),
        const Radius.circular(1.5),
      ),
      _bodyOutline,
    );

    // Kafa
    canvas.drawCircle(Offset(cx, cy - 4), 2.5, _bodyPaint);
    canvas.drawCircle(Offset(cx, cy - 4), 2.5, _bodyOutline);
    canvas.drawCircle(Offset(cx - 0.9, cy - 4), 0.7, _eyePaint);
    canvas.drawCircle(Offset(cx + 0.9, cy - 4), 0.7, _eyePaint);

    // Miğfer
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - 2.8, cy - 7, 5.6, 1.8),
        const Radius.circular(1),
      ),
      _helmetPaint,
    );

    // Kılıç — hedef yönüne dönerek vuruş animasyonu
    final swingT = (_attackCd / (1.0 / fireRate)).clamp(0.0, 1.0);
    final attackPulse = (1.0 - swingT) * (swingT > 0.7 ? 1.0 : 0.0);
    canvas.save();
    canvas.translate(cx, cy);
    canvas.rotate(_facingAngle() + math.pi / 2 + attackPulse * 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-0.6, -8, 1.2, 7),
        const Radius.circular(0.5),
      ),
      _swordPaint,
    );
    canvas.drawRect(const Rect.fromLTWH(-1.6, -1, 3.2, 1), _bodyPaint);
    canvas.restore();

    // HP bar (sadece hasar aldıysa)
    if (_hp < maxHp) {
      const barH = 1.6;
      final barW = size.x * 0.7;
      const barY = -3.0;
      final barX = (size.x - barW) / 2;
      canvas.drawRect(Rect.fromLTWH(barX, barY, barW, barH), _hpBgPaint);
      canvas.drawRect(
        Rect.fromLTWH(barX, barY, barW * (_hp / maxHp), barH),
        _hpFillPaint,
      );
    }
  }
}
