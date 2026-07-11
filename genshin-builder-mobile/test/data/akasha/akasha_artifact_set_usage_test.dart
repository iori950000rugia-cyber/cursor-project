import 'package:genshin_builder_mobile/data/akasha/akasha_artifact_set_usage.dart';
import 'package:genshin_builder_mobile/domain/artifacts/artifact_set_recommendations.dart';
import 'package:genshin_builder_mobile/domain/models/master_models.dart';
import 'package:genshin_builder_mobile/providers/artifact_sets_page_providers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('countArtifactSetsFromBuilds', () {
    test('counts sets with 2+ pieces only', () {
      final builds = [
        {
          'artifactSets': {
            'Emblem of Severed Fate': {'count': 4},
            "Gladiator's Finale": {'count': 1},
          },
        },
        {
          'artifactSets': {
            'Emblem of Severed Fate': {'count': 2},
            "Gladiator's Finale": {'count': 2},
          },
        },
      ];
      final counts = countArtifactSetsFromBuilds(builds);
      expect(counts['Emblem of Severed Fate'], 2);
      expect(counts["Gladiator's Finale"], 1);
    });
  });

  group('invertCharacterSetUsage', () {
    test('ranks characters by rate per set', () {
      final index = invertCharacterSetUsage(
        snapshots: [
          (
            characterId: '10000052',
            rates: {'Emblem of Severed Fate': 0.9},
            isRemote: true,
          ),
          (
            characterId: '10000023',
            rates: {'Emblem of Severed Fate': 0.4},
            isRemote: true,
          ),
          (
            characterId: 'x',
            rates: {'Emblem of Severed Fate': 0.01},
            isRemote: true,
          ),
        ],
        minRate: 0.05,
      );
      final hits = index['Emblem of Severed Fate']!;
      expect(hits.length, 2);
      expect(hits.first.characterId, '10000052');
      expect(hits.last.characterId, '10000023');
    });
  });

  group('selectArtifactRecommendationSampleIds', () {
    test('includes all characters with owned first', () {
      final a = MasterCharacter(
        id: '10000052',
        name: '雷電将軍',
        element: '雷',
        rarity: 5,
        weaponType: '長柄武器',
        region: '稲妻',
        iconUrl: '',
      );
      final b = MasterCharacter(
        id: '10000023',
        name: '香菱',
        element: '炎',
        rarity: 4,
        weaponType: '長柄武器',
        region: '璃月',
        iconUrl: '',
      );
      final c = MasterCharacter(
        id: '10000030',
        name: '鍾離',
        element: '岩',
        rarity: 5,
        weaponType: '長柄武器',
        region: '璃月',
        iconUrl: '',
      );

      final ids = selectArtifactRecommendationSampleIds(
        ownedIds: {b.id},
        progressList: const [],
        allCharacters: [a, b, c],
      );
      expect(ids.length, 3);
      expect(ids.first, b.id);
      expect(ids.toSet(), {a.id, b.id, c.id});
    });
  });
}
