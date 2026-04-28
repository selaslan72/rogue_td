import 'dart:math';
import '../models/tower_card.dart';

/// Ağırlıklı kart havuzu. Her "draw" sonrası decay uygular, her wave sonrası
/// ağırlıkları kısmen geri kazandırır — böylece aynı kart tekrar tekrar çıkmaz.
class CardPool {
  final List<TowerCard> _all;
  final _weights = <String, double>{};
  final _rng = Random();

  static const _baseWeight = {
    TowerRarity.common: 3.0,
    TowerRarity.rare: 2.0,
    TowerRarity.legendary: 1.0,
  };

  CardPool(List<TowerCard> cards) : _all = List.unmodifiable(cards) {
    for (final c in cards) {
      _weights[c.id] = _baseWeight[c.rarity]!;
    }
  }

  /// 3 benzersiz kart çeker (havuz küçükse daha az döner).
  List<TowerCard> drawThree() {
    final n = min(3, _all.length);
    final result = <TowerCard>[];
    final remaining = List.of(_all);

    while (result.length < n && remaining.isNotEmpty) {
      final total = remaining.fold(0.0, (s, c) => s + (_weights[c.id] ?? 1.0));
      double roll = (total > 0) ? _rng.nextDouble() * total : 0;
      TowerCard picked = remaining.last;
      for (final c in remaining) {
        roll -= _weights[c.id] ?? 1.0;
        if (roll <= 0) {
          picked = c;
          break;
        }
      }
      result.add(picked);
      remaining.remove(picked);
    }
    return result;
  }

  /// Teklif edilen kartın ağırlığını düşür (gösterildi ama belki seçilmedi).
  void onOffered(TowerCard card) {
    final base = _baseWeight[card.rarity]!;
    _weights[card.id] = (_weights[card.id]! * 0.5).clamp(0.15, base);
  }

  /// Seçilen kartın ağırlığını daha fazla düşür (yakın zamanda tekrar çıkmasın).
  void onPicked(TowerCard card) {
    final base = _baseWeight[card.rarity]!;
    _weights[card.id] = (_weights[card.id]! * 0.3).clamp(0.08, base);
  }

  /// Wave sonu ağırlık iyileşmesi — her turda biraz toparla.
  void recoverWeights() {
    for (final c in _all) {
      final base = _baseWeight[c.rarity]!;
      _weights[c.id] = (_weights[c.id]! + 0.4).clamp(0.0, base);
    }
  }
}
