import 'package:flutter_test/flutter_test.dart';

import 'package:genshin_builder_mobile/data/hoyolab/models/game_record.dart';

void main() {
  group('StygianOnslaughtStatus.fromSeasonJson', () {
    test('parses best record from single player data', () {
      final status = StygianOnslaughtStatus.fromSeasonJson({
        'schedule': {
          'schedule_id': 1,
          'name': '当期',
          'is_valid': true,
          'end_date_time': {'year': 2026, 'month': 6, 'day': 30},
        },
        'single': {
          'has_data': true,
          'best': {'difficulty': 4, 'second': 372},
        },
      });

      expect(status.hasData, isTrue);
      expect(status.difficultyLabel, 'マスター');
      expect(status.bestTimeSeconds, 372);
      expect(status.seasonName, '当期');
    });

    test('sums challenge seconds for total clearance time', () {
      final status = StygianOnslaughtStatus.fromSeasonJson({
        'schedule': {'name': '当期', 'is_valid': true},
        'single': {
          'has_data': true,
          'best': {'difficulty': 5, 'second': 350},
          'challenge': [
            {'second': 102},
            {'second': 119},
            {'second': 129},
          ],
        },
      });

      expect(status.bestTimeSeconds, 350);
      expect(status.difficultyLabel, 'エクストラ');
    });

    test('roundtrips through cache json', () {
      const original = StygianOnslaughtStatus(
        isUnlocked: true,
        bestDifficultyId: 5,
        bestTimeSeconds: 500,
        hasData: true,
        seasonName: 'テストシーズン',
      );

      final restored = StygianOnslaughtStatus.fromCacheJson(original.toJson());
      expect(restored.difficultyLabel, 'エクストラ');
      expect(restored.bestTimeSeconds, 500);
      expect(restored.seasonName, 'テストシーズン');
    });
  });

  group('AdventureStatus cache', () {
    test('includes stygian onslaught', () {
      const status = AdventureStatus(
        stygianOnslaught: StygianOnslaughtStatus(
          isUnlocked: true,
          bestDifficultyId: 3,
          bestTimeSeconds: 240,
          hasData: true,
        ),
      );

      final restored = AdventureStatus.fromCacheJson(status.toJson());
      expect(restored.stygianOnslaught?.difficultyLabel, 'ハード');
    });
  });
}
