import 'package:flutter/material.dart';

/// Düşman türleri — wave şablonu bu tanımları referans verir.
enum EnemyKind {
  fast,    // hızlı, az HP
  basic,   // ortalama
  tank,    // yavaş, çok HP
  flying,  // uçan, sadece radar/havadan vurabilen
  boss,    // boss wave (her 10 wave'de)
}

@immutable
class EnemyDef {
  final String id;
  final String name;
  final EnemyKind kind;
  final double maxHp;
  final double speed;       // birim/saniye
  final int armor;          // hasardan düşülen sabit
  final int goldReward;     // ölünce verilen altın
  final int damageOnLeak;   // yola sızarsa kaç can götürür
  final Color color;        // şimdilik geometri renk
  final double sizeScale;   // 1.0 = default; boss için 1.7 vb.

  const EnemyDef({
    required this.id,
    required this.name,
    required this.kind,
    required this.maxHp,
    required this.speed,
    this.armor = 0,
    this.goldReward = 5,
    this.damageOnLeak = 1,
    required this.color,
    this.sizeScale = 1.0,
  });

  bool get isFlying => kind == EnemyKind.flying;
  bool get isBoss => kind == EnemyKind.boss;
}
