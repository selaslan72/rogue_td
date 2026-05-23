import 'package:flutter_test/flutter_test.dart';
import 'package:rogue_td/models/game_season.dart';
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

  test('migrates legacy level stars into spring progress', () async {
    SharedPreferences.setMockInitialValues({'level_stars_v1': '{"1":3,"2":2}'});

    await ProgressService.instance.reloadForTesting();

    expect(ProgressService.instance.starsFor(1, season: GameSeason.spring), 3);
    expect(ProgressService.instance.starsFor(2, season: GameSeason.spring), 2);
    expect(ProgressService.instance.starsFor(1, season: GameSeason.winter), 0);
  });
}
