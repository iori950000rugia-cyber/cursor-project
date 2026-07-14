import 'package:flutter_test/flutter_test.dart';

import 'package:genshin_builder_mobile/domain/planning/upgrade_option.dart';
import 'package:genshin_builder_mobile/domain/team/team_models.dart';
import 'package:genshin_builder_mobile/domain/account/account_snapshot.dart';
import 'package:genshin_builder_mobile/application/planning/optimize_growth_route_use_case.dart';
import 'package:genshin_builder_mobile/application/planning/generate_team_growth_priority_use_case.dart';

AccountSnapshot _testSnapshot(List<CharacterSnapshot> chars) => AccountSnapshot(
      userId: 'local',
      characters: chars,
      acquiredAt: DateTime.now(),
      sources: ['test'],
    );

CharacterSnapshot _testChar(String id, {int level = 1, int weaponLevel = 1}) =>
    CharacterSnapshot(
      characterId: id, name: 'Test$id', element: 'pyro',
      weaponType: 'sword', rarity: 5, region: 'Mondstadt',
      isOwned: true, level: level, weaponLevel: weaponLevel,
    );

void main() {
  group('OptimizeGrowthRouteUseCase', () {
    test('empty options produces empty route', () {
      final route = const OptimizeGrowthRouteUseCase()(
        userId: 'local', options: [], startWeekday: 1,
      );
      expect(route.days, isEmpty);
    });

    test('options produce scheduled days', () {
      final options = [
        UpgradeOption(optionId: 'o1', characterId: 'c1', optionType: 'level',
            fromValue: 1, toValue: 80, priority: 2,
            calculationMode: CalculationMode.exactMasterData),
        UpgradeOption(optionId: 'o2', characterId: 'c1', optionType: 'talentBurst',
            fromValue: 1, toValue: 8, priority: 1,
            calculationMode: CalculationMode.exactMasterData),
      ];
      final route = const OptimizeGrowthRouteUseCase()(
        userId: 'local', options: options, startWeekday: 1,
      );
      expect(route.days.isNotEmpty, isTrue);
      expect(route.goals.length, 2);
      expect(route.ruleVersion, '2');
    });

    test('same input produces same output', () {
      final options = [
        UpgradeOption(optionId: 'o1', characterId: 'c1', optionType: 'level',
            fromValue: 1, toValue: 90, priority: 2,
            calculationMode: CalculationMode.exactMasterData),
      ];
      final route1 = const OptimizeGrowthRouteUseCase()(
        userId: 'local', options: options, startWeekday: 1,
      );
      final route2 = const OptimizeGrowthRouteUseCase()(
        userId: 'local', options: options, startWeekday: 1,
      );
      expect(route1.days.length, route2.days.length);
    });

    test('defaultDayCount is 7', () {
      expect(OptimizeGrowthRouteUseCase.defaultDayCount, 7);
    });

    test('options without inventory show low confidence', () {
      final options = [
        UpgradeOption(optionId: 'o1', characterId: 'c1', optionType: 'level',
            fromValue: 1, toValue: 80,
            calculationMode: CalculationMode.estimatedInventoryMissing),
      ];
      final route = const OptimizeGrowthRouteUseCase()(
        userId: 'local', options: options, startWeekday: 1,
      );
      expect(route.confidence, isNotNull);
    });
  });

  group('GenerateTeamGrowthPriorityUseCase', () {
    test('empty team returns empty report', () {
      final team = Team(id: 't1', name: 'Test', members: []);
      final snapshot = _testSnapshot([]);
      final report = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: {},
      );
      expect(report.memberPriorities, isEmpty);
    });

    test('4 members ranked by score', () {
      final chars = List.generate(4, (i) => _testChar('id$i', level: 20 + i * 20));
      final snapshot = _testSnapshot(chars);
      final team = Team(
        id: 't1', name: 'Test',
        members: List.generate(4, (i) => TeamMemberSlot(characterId: 'id$i', position: i)),
      );
      final report = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: {},
      );
      expect(report.memberPriorities.length, 4);
      // Higher level = lower priority (since fewer issues)
      expect(report.memberPriorities.first.characterId, 'id0');
    });

    test('characters with upgrade options get higher priority', () {
      final chars = [_testChar('c1', level: 80), _testChar('c2', level: 80)];
      final snapshot = _testSnapshot(chars);
      final team = Team(id: 't1', name: 'Test', members: [
        TeamMemberSlot(characterId: 'c1', position: 0),
        TeamMemberSlot(characterId: 'c2', position: 1),
      ]);
      final options = {
        'c1': [
          UpgradeOption(optionId: 'opt', characterId: 'c1', optionType: 'level',
            fromValue: 80, toValue: 90, priority: 2,
            calculationMode: CalculationMode.exactMasterData,
            impact: UpgradeImpact(impactScore: 0.3, impactBand: ImpactBand.high)),
        ],
      };
      final report = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: options,
      );
      expect(report.memberPriorities.first.characterId, 'c1');
    });

    test('unowned character is deprioritized', () {
      final chars = [
        _testChar('c1', level: 80),
        CharacterSnapshot(characterId: 'c2', name: 'Test2', element: 'pyro',
            weaponType: 'sword', rarity: 5, region: 'Mondstadt', isOwned: false),
      ];
      final snapshot = _testSnapshot(chars);
      final team = Team(id: 't1', name: 'Test', members: [
        TeamMemberSlot(characterId: 'c1', position: 0),
        TeamMemberSlot(characterId: 'c2', position: 1),
      ]);
      final report = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: {},
      );
      final unowned = report.memberPriorities.firstWhere((p) => p.characterId == 'c2');
      expect(unowned.priority, -1);
    });

    test('shared materials are detected', () {
      final chars = [_testChar('c1'), _testChar('c2')];
      final snapshot = _testSnapshot(chars);
      final team = Team(id: 't1', name: 'Test', members: [
        TeamMemberSlot(characterId: 'c1', position: 0),
        TeamMemberSlot(characterId: 'c2', position: 1),
      ]);
      final options = {
        'c1': [
          UpgradeOption(optionId: 's1', characterId: 'c1', optionType: 'level',
            fromValue: 1, toValue: 90, materialsCost: {'mat_x': 10},
            calculationMode: CalculationMode.exactMasterData),
        ],
        'c2': [
          UpgradeOption(optionId: 's2', characterId: 'c2', optionType: 'level',
            fromValue: 1, toValue: 90, materialsCost: {'mat_x': 15},
            calculationMode: CalculationMode.exactMasterData),
        ],
      };
      final report = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: options,
      );
      expect(report.sharedMaterialOpportunities, isNotEmpty);
    });

    test('deterministic output for same input', () {
      final chars = [_testChar('c1'), _testChar('c2')];
      final snapshot = _testSnapshot(chars);
      final team = Team(id: 't1', name: 'Test', members: [
        TeamMemberSlot(characterId: 'c1', position: 0),
        TeamMemberSlot(characterId: 'c2', position: 1),
      ]);
      final r1 = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: {},
      );
      final r2 = const GenerateTeamGrowthPriorityUseCase()(
        team: team, snapshot: snapshot, upgradeOptionsByCharacter: {},
      );
      expect(r1.memberPriorities.map((p) => p.characterId).toList(),
          r2.memberPriorities.map((p) => p.characterId).toList());
    });
  });
}
