import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/config/config_validators.dart';
import 'package:genshin_builder_mobile/data/db/upgrade_content_hash.dart';

void main() {
  group('config_validators', () {
    test('accepts valid artifact score weights', () {
      expect(
        () => validateArtifactScoreWeightsJson({
          'profiles': [
            {
              'characterId': '10000052',
              'name': '雷電将軍',
              'weights': {'critRate': 2},
            },
          ],
        }),
        returnsNormally,
      );
    });

    test('rejects empty characterId', () {
      expect(
        () => validateArtifactScoreWeightsJson({
          'profiles': [
            {'characterId': '', 'weights': {}},
          ],
        }),
        throwsFormatException,
      );
    });

    test('accepts valid daily schedule', () {
      expect(
        () => validateDailyMaterialScheduleJson({
          'version': 1,
          'talentSeries': [
            {
              'id': 'freedom',
              'days': [1, 4],
              'materialIds': ['104301'],
            },
          ],
          'weaponSeries': [
            {
              'id': 'decarabian',
              'days': [1, 4],
              'materialIds': ['114001'],
            },
          ],
        }),
        returnsNormally,
      );
    });

    test('rejects day outside 1-7', () {
      expect(
        () => validateDailyMaterialScheduleJson({
          'version': 1,
          'talentSeries': [
            {
              'id': 'freedom',
              'days': [0],
              'materialIds': ['104301'],
            },
          ],
          'weaponSeries': [
            {
              'id': 'decarabian',
              'days': [1],
              'materialIds': ['114001'],
            },
          ],
        }),
        throwsFormatException,
      );
    });
  });

  group('upgrade_content_hash', () {
    test('is stable for same payload', () {
      final a = computeUpgradeContentHash(
        promotesJson: '[]',
        secondaryJson: '{}',
      );
      final b = computeUpgradeContentHash(
        promotesJson: '[]',
        secondaryJson: '{}',
      );
      expect(a, b);
      expect(a.length, 32);
    });

    test('changes when payload changes', () {
      final a = computeUpgradeContentHash(
        promotesJson: '[]',
        secondaryJson: '{}',
      );
      final b = computeUpgradeContentHash(
        promotesJson: '[{}]',
        secondaryJson: '{}',
      );
      expect(a, isNot(b));
    });
  });
}
