import 'package:flutter/material.dart';

import '../models/meta_perk.dart';
import '../services/progress_service.dart';

/// Rün Atölyesi — run'larda kazanılan fragment'lerle kalıcı meta upgrade'ler
/// satın alınan ekran. Bölüm seçim ekranından açılır.
class RuneShopScreen extends StatefulWidget {
  const RuneShopScreen({super.key});

  @override
  State<RuneShopScreen> createState() => _RuneShopScreenState();
}

class _RuneShopScreenState extends State<RuneShopScreen> {
  final _progress = ProgressService.instance;
  String? _flashPerkId; // satın alma sonrası kısa vurgu

  Future<void> _buy(MetaPerk perk) async {
    final level = _progress.perkLevel(perk.id);
    if (level >= perk.maxLevel) return;
    final cost = perk.costForNext(level);
    if (_progress.totalFragments < cost) return;
    final ok = await _progress.buyPerk(perk.id, cost);
    if (ok && mounted) {
      setState(() => _flashPerkId = perk.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fragments = _progress.totalFragments;
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A14),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: Colors.white70,
                  ),
                  const Expanded(
                    child: Text(
                      'RÜN ATÖLYESİ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFA78BFA),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFFA78BFA).withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('💎', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      '$fragments fragment',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.separated(
                  itemCount: MetaPerks.all.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final perk = MetaPerks.all[i];
                    return _PerkCard(
                      perk: perk,
                      level: _progress.perkLevel(perk.id),
                      fragments: fragments,
                      flash: _flashPerkId == perk.id,
                      onBuy: () => _buy(perk),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Bonuslar her run başında otomatik uygulanır.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white38, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PerkCard extends StatelessWidget {
  final MetaPerk perk;
  final int level;
  final int fragments;
  final bool flash;
  final VoidCallback onBuy;

  const _PerkCard({
    required this.perk,
    required this.level,
    required this.fragments,
    required this.flash,
    required this.onBuy,
  });

  String get _effectLabel {
    final isPercent = perk.perLevelValue < 1;
    if (isPercent) {
      final pct = (perk.perLevelValue * level * 100).round();
      return level == 0 ? '—' : '+%$pct';
    }
    final total = (perk.perLevelValue * level).round();
    return level == 0 ? '—' : '+$total';
  }

  @override
  Widget build(BuildContext context) {
    final maxed = level >= perk.maxLevel;
    final cost = maxed ? 0 : perk.costForNext(level);
    final affordable = !maxed && fragments >= cost;
    const accent = Color(0xFFA78BFA);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: flash
            ? accent.withValues(alpha: 0.18)
            : const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accent.withValues(alpha: 0.5), width: 1.4),
      ),
      child: Row(
        children: [
          Text(perk.icon, style: const TextStyle(fontSize: 30)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      perk.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _effectLabel,
                      style: const TextStyle(
                        color: accent,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  perk.description,
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Row(
                  children: List.generate(perk.maxLevel, (i) {
                    final filled = i < level;
                    return Container(
                      width: 14,
                      height: 6,
                      margin: const EdgeInsets.only(right: 4),
                      decoration: BoxDecoration(
                        color: filled ? accent : Colors.white12,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _BuyButton(
            maxed: maxed,
            cost: cost,
            affordable: affordable,
            onBuy: onBuy,
          ),
        ],
      ),
    );
  }
}

class _BuyButton extends StatelessWidget {
  final bool maxed;
  final int cost;
  final bool affordable;
  final VoidCallback onBuy;

  const _BuyButton({
    required this.maxed,
    required this.cost,
    required this.affordable,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    if (maxed) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white10,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'MAX',
          style: TextStyle(
            color: Colors.white54,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      );
    }
    const accent = Color(0xFFA78BFA);
    return Material(
      color: affordable ? accent : Colors.white10,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: affordable ? onBuy : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'AL',
                style: TextStyle(
                  color: affordable ? const Color(0xFF0A0A14) : Colors.white38,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '💎$cost',
                style: TextStyle(
                  color: affordable
                      ? const Color(0xFF0A0A14)
                      : Colors.white38,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
