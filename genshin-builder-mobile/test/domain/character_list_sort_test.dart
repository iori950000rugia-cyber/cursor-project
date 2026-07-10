import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/models/master_models.dart';
import 'package:genshin_builder_mobile/domain/character_list_sort.dart';

MasterCharacter _char({
  required String id,
  required String name,
  int rarity = 5,
  String element = 'pyro',
  String region = 'mondstadt',
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

OwnedCharacterSortInfo _owned({
  int level = 1,
  int constellation = 0,
  int friendship = 0,
  DateTime? obtainedAt,
}) =>
    OwnedCharacterSortInfo(
      level: level,
      constellation: constellation,
      friendship: friendship,
      obtainedAt: obtainedAt,
    );

void main() {
  group('character list sort', () {
    test('owned characters appear before unowned with default settings', () {
      final characters = [
        _char(id: '10000002', name: 'Ayaka'),
        _char(id: '10000003', name: 'Unowned'),
      ];
      final ownedMap = {
        '10000002': _owned(level: 90),
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
        _char(id: '10000005-anemo', name: 'TravelerAnemo', element: 'anemo'),
      ];
      final ownedMap = {
        '10000005': _owned(level: 90),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
      );

      expect(entries.single.isOwned, isTrue);
    });

    test('sorts by name ascending when group is off', () {
      final characters = [
        _char(id: '1', name: 'HuTao'),
        _char(id: '2', name: 'Ayaka'),
        _char(id: '3', name: 'Kaeya'),
      ];

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: const {},
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.nameAsc,
          groupByOwnership: false,
        ),
      );

      expect(entries.map((e) => e.character.name).toList(), [
        'Ayaka',
        'HuTao',
        'Kaeya',
      ]);
    });

    test('sorts by rarity descending', () {
      final characters = [
        _char(id: '1', name: 'A', rarity: 4),
        _char(id: '2', name: 'B', rarity: 5),
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
    });

    test('sorts owned entries by level within groups', () {
      final characters = [
        _char(id: '1', name: 'Low'),
        _char(id: '2', name: 'High'),
        _char(id: '3', name: 'Unowned'),
      ];
      final ownedMap = {
        '1': _owned(level: 40),
        '2': _owned(level: 90),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.levelDesc,
          groupByOwnership: true,
        ),
      );

      expect(entries[0].character.name, 'High');
      expect(entries[1].character.name, 'Low');
      expect(entries.last.isOwned, isFalse);
    });

    test('sorts by obtained date descending', () {
      final characters = [
        _char(id: '1', name: 'Old'),
        _char(id: '2', name: 'New'),
      ];
      final ownedMap = {
        '1': _owned(obtainedAt: DateTime(2024, 1, 1)),
        '2': _owned(obtainedAt: DateTime(2025, 1, 1)),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.obtainedDesc,
          groupByOwnership: false,
        ),
      );

      expect(entries.first.character.name, 'New');
      expect(entries.last.character.name, 'Old');
    });

    test('owned default puts dated characters before undated ones', () {
      final characters = [
        _char(id: '1', name: 'NoDate'),
        _char(id: '2', name: 'New'),
        _char(id: '3', name: 'Old'),
      ];
      final ownedMap = {
        '1': _owned(level: 90),
        '2': _owned(obtainedAt: DateTime(2025, 1, 1)),
        '3': _owned(obtainedAt: DateTime(2024, 1, 1)),
      };

      final entries = buildCharacterListEntries(
        characters: characters,
        ownedMap: ownedMap,
        settings: const CharacterListSortSettings(
          mode: CharacterListSortMode.ownedDefault,
          groupByOwnership: true,
        ),
      );

      // ascending obtainedAt: older dated first, then undated
      expect(entries[0].character.name, 'Old');
      expect(entries[1].character.name, 'New');
      expect(entries[2].character.name, 'NoDate');
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
