import 'package:flutter_test/flutter_test.dart';
import 'package:rogue_td/models/game_season.dart';
import 'package:rogue_td/models/meta_perk.dart';
import 'package:rogue_td/services/progress_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ProgressService.instance.reloadForTesting();
    await ProgressService.instance.reset();
  });

  test('stores stars separately for spring and winter levels', () async {
    final progress = ProgressService.instance;

    await progress.setStars(1, 3, season: GameSeason.spring);
    await progress.setStars(1, 1, season: GameSeason.winter);

    expect(progress.starsFor(1, season: GameSeason.spring), 3);
    expect(progress.starsFor(1, season: GameSeason.winter), 1);
    expect(progress.totalStarsFor(GameSeason.spring), 3);
    expect(progress.totalStarsFor(GameSeason.winter), 1);
  });

  test('uses season-specific stars for unlock checks', () async {
    final progress = ProgressService.instance;

    await progress.setStars(1, 3, season: GameSeason.spring);

    expect(progress.isUnlocked(3, season: GameSeason.spring), isTrue);
    expect(progress.isUnlocked(3, season: GameSeason.winter), isFalse);
  });

  test('unlocks winter after enough spring stars', () async {
    final progress = ProgressService.instance;

    expect(progress.isSeasonUnlocked(GameSeason.spring), isTrue);
    expect(progress.isSeasonUnlocked(GameSeason.winter), isFalse);

    for (var levelId = 1; levelId <= 20; levelId++) {
      await progress.setStars(levelId, 3, season: GameSeason.spring);
    }

    expect(progress.totalStarsFor(GameSeason.spring), 60);
    expect(progress.isSeasonUnlocked(GameSeason.winter), isTrue);
  });

  test('migrates legacy level stars into spring progress', () async {
    SharedPreferences.setMockInitialValues({'level_stars_v1': '{"1":3,"2":2}'});

    await ProgressService.instance.reloadForTesting();

    expect(ProgressService.instance.starsFor(1, season: GameSeason.spring), 3);
    expect(ProgressService.instance.starsFor(2, season: GameSeason.spring), 2);
    expect(ProgressService.instance.starsFor(1, season: GameSeason.winter), 0);
  });

  test('buyPerk spends fragments and raises perk level', () async {
    final progress = ProgressService.instance;
    await progress.addFragments(50);

    final perk = MetaPerks.treasury;
    final cost = perk.costForNext(0); // 8

    final ok = await progress.buyPerk(perk.id, cost);

    expect(ok, isTrue);
    expect(progress.perkLevel(perk.id), 1);
    expect(progress.totalFragments, 50 - cost);
  });

  test('buyPerk fails when fragments are insufficient', () async {
    final progress = ProgressService.instance;
    await progress.addFragments(3);

    final ok = await progress.buyPerk(MetaPerks.treasury.id, 8);

    expect(ok, isFalse);
    expect(progress.perkLevel(MetaPerks.treasury.id), 0);
    expect(progress.totalFragments, 3);
  });

  test('MetaBonuses reflect purchased perk levels', () async {
    final progress = ProgressService.instance;
    await progress.addFragments(500);

    // Hazine x2, Surlar x1, Keskinlik x1
    await progress.buyPerk(MetaPerks.treasury.id, MetaPerks.treasury.costForNext(0));
    await progress.buyPerk(MetaPerks.treasury.id, MetaPerks.treasury.costForNext(1));
    await progress.buyPerk(MetaPerks.ramparts.id, MetaPerks.ramparts.costForNext(0));
    await progress.buyPerk(MetaPerks.sharpness.id, MetaPerks.sharpness.costForNext(0));

    final bonuses = MetaBonuses.fromProgress(progress);

    expect(bonuses.bonusGold, 60); // 30 × 2
    expect(bonuses.bonusLives, 1);
    expect(bonuses.damageMul, closeTo(1.04, 1e-9));
    expect(bonuses.rangeMul, 1.0); // Kartal Gözü alınmadı
  });

  test('perk levels persist across reloads', () async {
    final progress = ProgressService.instance;
    await progress.addFragments(50);
    await progress.buyPerk(MetaPerks.sharpness.id, MetaPerks.sharpness.costForNext(0));

    await progress.reloadForTesting();

    expect(progress.perkLevel(MetaPerks.sharpness.id), 1);
  });
}
