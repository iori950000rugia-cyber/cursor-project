import 'package:genshin_builder_mobile/domain/level_config.dart';
import 'package:genshin_builder_mobile/domain/level_progression.dart';
import 'package:genshin_builder_mobile/domain/material_requirements.dart';
import 'package:genshin_builder_mobile/domain/models/bookmark.dart';
import 'package:genshin_builder_mobile/domain/models/calculation_models.dart';
import 'package:genshin_builder_mobile/domain/weapon_exp.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('clampInt / snapToLevelMark', () {
    test('clampInt bounds', () {
      expect(clampInt(5.7, 1, 10), 6);
      expect(clampInt('bad', 1, 10), 1);
      expect(clampInt(100, 1, 90), 90);
    });

    test('snapToLevelMark picks nearest mark', () {
      expect(snapToLevelMark(22), 20);
      expect(snapToLevelMark(28), 30);
      expect(snapToLevelMark(90), 90);
    });
  });

  group('getNextStageRequirements', () {
    test('returns exp books for character level segment', () {
      final promotes = <PromoteStage>[
        const PromoteStage(
          promoteLevel: 1,
          unlockMaxLevel: 20,
          costItems: {'100001': 1},
          coinCost: 20000,
        ),
      ];

      final stage = getNextStageRequirements(1, promotes, 'character', 5);
      expect(stage, isNotNull);
      expect(stage!.fromLevel, 1);
      expect(stage.toLevel, 20);
      expect(stage.expTotal, characterExpBetweenMarks['1-20']);
      expect(stage.levelUpMaterials, isNotEmpty);
      expect(stage.levelUpMaterials.first.materialId, '104002');
    });
  });

  group('getWeaponExpBetweenMarks', () {
    test('5-star weapon exp table', () {
      expect(getWeaponExpBetweenMarks(1, 20, 5), 121550);
      expect(getWeaponExpBetweenMarks(80, 90, 5), 3714775);
    });
  });

  group('getRangeLevelRequirements', () {
    test('aggregates mora as __mora__', () {
      final promotes = <PromoteStage>[];
      final lines = getRangeLevelRequirements(1, 20, promotes, 'character');
      expect(lines.any((l) => l.materialId == moraMaterialId), isTrue);
      final mora = lines.firstWhere((l) => l.isMora);
      expect(mora.count, greaterThan(0));
    });

    test('empty when to <= from', () {
      expect(getRangeLevelRequirements(50, 40, [], 'character'), isEmpty);
    });
  });
}
