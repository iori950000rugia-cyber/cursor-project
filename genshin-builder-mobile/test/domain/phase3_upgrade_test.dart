import 'package:flutter_test/flutter_test.dart';

import 'package:genshin_builder_mobile/domain/planning/upgrade_option.dart';
import 'package:genshin_builder_mobile/domain/planning/growth_goal.dart';
import 'package:genshin_builder_mobile/domain/account/account_snapshot.dart';
import 'package:genshin_builder_mobile/domain/recommendation/recommendation.dart';
import 'package:genshin_builder_mobile/application/planning/generate_upgrade_options_use_case.dart';
import 'package:genshin_builder_mobile/application/planning/estimate_upgrade_impact_use_case.dart';

void main() {
  group('UpgradeOption model', () {
    test('default option is not calculable', () {
      const opt = UpgradeOption(optionId: 't', characterId: 'c1', optionType: 'level');
      expect(opt.isCalculable, isFalse);
      expect(opt.calculationMode, CalculationMode.unavailable);
    });

    test('option with master data is calculable', () {
      const opt = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'level',
        calculationMode: CalculationMode.exactMasterData,
      );
      expect(opt.isCalculable, isTrue);
    });

    test('inventory status defaults to unknown', () {
      const opt = UpgradeOption(optionId: 't', characterId: 'c1', optionType: 'level');
      expect(opt.inventoryStatus, InventoryStatus.unknown);
    });

    test('UpgradeImpactImpactBand transitions', () {
    expect(EstimateUpgradeImpactUseCase.toBand(0.35), ImpactBand.high);
    expect(EstimateUpgradeImpactUseCase.toBand(0.25), ImpactBand.medium);
    expect(EstimateUpgradeImpactUseCase.toBand(0.15), ImpactBand.low);
    expect(EstimateUpgradeImpactUseCase.toBand(0.05), ImpactBand.minimal);
    expect(EstimateUpgradeImpactUseCase.toBand(0.0), ImpactBand.unknown);
    });

    test('impact has excluded factors', () {
      const impact = UpgradeImpact(
        impactScore: 0.3, impactBand: ImpactBand.high,
        excludedFactors: ['enemyDefense', 'elementalReactions'],
      );
      expect(impact.excludedFactors, contains('enemyDefense'));
      expect(impact.excludedFactors.length, 2);
    });
  });

  group('GenerateUpgradeOptionsUseCase', () {
    const goal = GrowthGoal(
      id: 'g1', userId: 'local', characterId: '10000002',
      targetLevel: 90, targetTalentBurst: 10,
      status: GrowthGoalStatus.active,
    );
    const character = CharacterSnapshot(
      characterId: '10000002', name: 'Ayaka', element: 'cryo',
      weaponType: 'sword', rarity: 5, region: 'Inazuma',
      isOwned: true, level: 1, talentBurst: 1,
    );

    test('generates options for each target', () {
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: goal, character: character, materialInventory: {},
      );
      expect(options.length, 2); // level + talentBurst
    });

    test('options have correct types', () {
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: goal, character: character, materialInventory: {},
      );
      final types = options.map((o) => o.optionType).toSet();
      expect(types, contains('level'));
      expect(types, contains('talentBurst'));
    });

    test('option fromValue/toValue set correctly', () {
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: goal, character: character, materialInventory: {},
      );
      final levelOpt = options.firstWhere((o) => o.optionType == 'level');
      expect(levelOpt.fromValue, 1);
      expect(levelOpt.toValue, 90);
    });

    test('option without inventory shows notSet', () {
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: goal, character: character, materialInventory: {},
      );
      final opt = options.first;
      expect(opt.inventoryStatus, InventoryStatus.notSet);
      expect(opt.remainingMaterials, isEmpty);
      expect(opt.missingData, contains(MissingData.materialInventory));
    });

    test('stepCount is positive', () {
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: goal, character: character, materialInventory: {},
      );
      expect(options.every((o) => (o.stepCount) > 0), isTrue);
    });

    test('no targets produces empty list', () {
      const noTargetGoal = GrowthGoal(
        id: 'g2', userId: 'local', characterId: '10000002',
        status: GrowthGoalStatus.active,
      );
      final options = const GenerateUpgradeOptionsUseCase()(
        goal: noTargetGoal, character: character, materialInventory: {},
      );
      expect(options, isEmpty);
    });
  });

  group('EstimateUpgradeImpactUseCase', () {
    test('level upgrade has impact', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'level',
        fromValue: 1, toValue: 90,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.impactScore, greaterThan(0));
      expect(impact.impactBand, isNot(ImpactBand.unknown));
      expect(impact.excludedFactors, isNotEmpty);
    });

    test('ascension upgrade has impact', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'ascension',
        fromValue: 0, toValue: 6,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.impactScore, greaterThan(0));
      expect(impact.reasons, isNotEmpty);
    });

    test('talent upgrade has impact', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'talentBurst',
        fromValue: 1, toValue: 10,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.impactScore, greaterThan(0));
      expect(impact.affectedAreas, contains('damageOutput'));
    });

    test('weapon upgrade has impact', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'weapon',
        fromValue: 1, toValue: 90,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.impactScore, greaterThan(0));
    });

    test('small gap has lower impact', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'level',
        fromValue: 80, toValue: 90,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.impactBand, ImpactBand.low);
    });

    test('same input produces same output', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'talentSkill',
        fromValue: 1, toValue: 8,
      );
      final impact1 = const EstimateUpgradeImpactUseCase()(option: option);
      final impact2 = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact1.impactScore, impact2.impactScore);
      expect(impact1.impactBand, impact2.impactBand);
    });

    test('confidence is low (no role/combat sim)', () {
      const option = UpgradeOption(
        optionId: 't', characterId: 'c1', optionType: 'level',
        fromValue: 1, toValue: 90,
      );
      final impact = const EstimateUpgradeImpactUseCase()(option: option);
      expect(impact.confidence, RecommendationConfidence.low);
    });
  });
}
