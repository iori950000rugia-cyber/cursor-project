import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/hoyolab/models/game_record.dart';
import 'package:genshin_builder_mobile/data/models/master_models.dart';
import 'package:genshin_builder_mobile/domain/character_list_sort.dart';

MasterCharacter _char({
  required String id,
  required String name,
  int rarity = 5,
  String element = 'pyro',
  String region = 'モンド',
}) =>
    MasterCharacter(
      id: id,
      name: name,
      element: element,
      weaponType: 'sword',
      rarity: rarity,
      region: region,
      iconUrl: '',
    );

HoyolabOwnedCharacter _owned({
  required String id,
  required String name,
  int level = 1,
  int constellation = 0,
  int friendship = 0,
  DateTime? obtainedAt,
}) =>
    HoyolabOwnedCharacter(
      id: id,
      name: name,
      level: level,
      constellation: constellation,
      friendship: friendship,
      obtainedAt: obtainedAt,
    );

void main() {
  group('character list sort', () {
    test('owned characters appear before unowned with default settings', () {
      final characters = [
        _char(id: '10000002', name: '綾華'),
        _char(id: '10000003', name: '未所持'),
      ];
      final ownedMap = {
        '10000002': _owned(id: '10000002', name: '綾華', level: 90),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
      );

      expect(entries.first.isOwned, isTrue);
      expect(entries.last.isOwned, isFalse);
    });

    test('traveler id matches base id without element suffix', () {
      final characters = [
        _char(id: '10000005-anemo', name: '旅人（風）', element: 'anemo'),
      ];
      final ownedMap = {
        '10000005': _owned(id: '10000005', name: '旅人', level: 90),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
      );

      expect(entries.single.isOwned, isTrue);
    });

    test('sorts by name ascending when group is off', () {
      final characters = [
        _char(id: '1', name: '胡桃'),
        _char(id: '2', name: 'アヤカ'),
        _char(id: '3', name: 'ガイア'),
      ];

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: const {},
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.nameAsc,
          groupByOwnership: false,
        ),
      );

      expect(entries.map((e) => e.character.name).toList(),
          ['アヤカ', 'ガイア', '胡桃']);
    });

    test('sorts by rarity descending across unified list', () {
      final characters = [
        _char(id: '1', name: '四星', rarity: 4),
        _char(id: '2', name: '五星A', rarity: 5),
        _char(id: '3', name: '五星B', rarity: 5),
      ];

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: const {},
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.rarityDesc,
          groupByOwnership: false,
        ),
      );

      expect(entries.first.character.rarity, 5);
      expect(entries.last.character.rarity, 4);
    });

    test('sorts owned entries by level within groups', () {
      final characters = [
        _char(id: '1', name: '低レベル'),
        _char(id: '2', name: '高レベル'),
        _char(id: '3', name: '未所持'),
      ];
      final ownedMap = {
        '1': _owned(id: '1', name: '低レベル', level: 40),
        '2': _owned(id: '2', name: '高レベル', level: 90),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.levelDesc,
          groupByOwnership: true,
        ),
      );

      expect(entries[0].character.name, '高レベル');
      expect(entries[1].character.name, '低レベル');
      expect(entries.last.isOwned, isFalse);
    });

    test('sorts by obtained date descending', () {
      final characters = [
        _char(id: '1', name: '古い'),
        _char(id: '2', name: '新しい'),
      ];
      final ownedMap = {
        '1': _owned(
          id: '1',
          name: '古い',
          obtainedAt: DateTime(2024, 1, 1),
        ),
        '2': _owned(
          id: '2',
          name: '新しい',
          obtainedAt: DateTime(2025, 1, 1),
        ),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.obtainedDesc,
          groupByOwnership: false,
        ),
      );

      expect(entries.first.character.name, '新しい');
      expect(entries.last.character.name, '古い');
    });

    test('owned default puts dated characters before undated ones', () {
      final characters = [
        _char(id: '1', name: '日付なし'),
        _char(id: '2', name: '新しい'),
        _char(id: '3', name: '古い'),
      ];
      final ownedMap = {
        '1': _owned(id: '1', name: '日付なし', level: 90),
        '2': _owned(
          id: '2',
          name: '新しい',
          obtainedAt: DateTime(2025, 1, 1),
        ),
        '3': _owned(
          id: '3',
          name: '古い',
          obtainedAt: DateTime(2024, 1, 1),
        ),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.ownedDefault,
          groupByOwnership: true,
        ),
      );

      expect(entries[0].character.name, '新しい');
      expect(entries[1].character.name, '古い');
      expect(entries[2].character.name, '日付なし');
    });

    test('CharacterListSortMode.fromStorage falls back safely', () {
      expect(
        CharacterListSortModeLabels.fromStorage('nameAsc'),
        CharacterListSortMode.nameAsc,
      );
      expect(
        CharacterListSortModeLabels.fromStorage('invalid'),
        CharacterListSortMode.ownedDefault,
      );
    });
  });
}
