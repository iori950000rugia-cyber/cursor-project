import 'package:flutter_test/flutter_test.dart';
import 'package:genshin_builder_mobile/data/hoyolab/hoyolab_character_discovery_store.dart';
import 'package:genshin_builder_mobile/data/hoyolab/hoyolab_home_disk_cache.dart';
import 'package:genshin_builder_mobile/data/hoyolab/models/game_record.dart';

class _MemorySettingsStore implements HoyolabSettingsStore {
  final _values = <String, String>{};

  @override
  Future<String?> getSetting(String key) async => _values[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _values[key] = value;
  }
}

void main() {
  group('HoyolabCharacterDiscoveryStore', () {
    late HoyolabCharacterDiscoveryStore store;

    setUp(() {
      store = HoyolabCharacterDiscoveryStore(_MemorySettingsStore());
    });

    test('first snapshot seeds without assigning discovered dates', () async {
      final enriched = await store.enrichOwnedCharacters(
        uid: '123',
        characters: {
          '10000002': const HoyolabOwnedCharacter(
            id: '10000002',
            name: '綾華',
            level: 90,
          ),
        },
      );

      expect(enriched['10000002']!.obtainedAt, isNull);
    });

    test('newly owned character gets discovered date on next fetch', () async {
      await store.enrichOwnedCharacters(
        uid: '123',
        characters: {
          '10000002': const HoyolabOwnedCharacter(
            id: '10000002',
            name: '綾華',
            level: 90,
          ),
        },
      );

      final enriched = await store.enrichOwnedCharacters(
        uid: '123',
        characters: {
          '10000002': const HoyolabOwnedCharacter(
            id: '10000002',
            name: '綾華',
            level: 90,
          ),
          '10000003': const HoyolabOwnedCharacter(
            id: '10000003',
            name: '胡桃',
            level: 80,
          ),
        },
      );

      expect(enriched['10000002']!.obtainedAt, isNull);
      expect(enriched['10000003']!.obtainedAt, isNotNull);
    });

    test('keeps API obtainedAt when present', () async {
      final apiDate = DateTime(2024, 6, 1);
      await store.enrichOwnedCharacters(
        uid: '123',
        characters: {
          '10000002': HoyolabOwnedCharacter(
            id: '10000002',
            name: '綾華',
            level: 90,
            obtainedAt: apiDate,
          ),
        },
      );

      final enriched = await store.enrichOwnedCharacters(
        uid: '123',
        characters: {
          '10000002': HoyolabOwnedCharacter(
            id: '10000002',
            name: '綾華',
            level: 90,
            obtainedAt: apiDate,
          ),
        },
      );

      expect(enriched['10000002']!.obtainedAt, apiDate);
    });
  });

  group('parseObtainedAtFromCharacterJson', () {
    test('parses unix seconds', () {
      final parsed = parseObtainedAtFromCharacterJson({
        'obtained_time': 1675518507,
      });
      expect(parsed, DateTime.fromMillisecondsSinceEpoch(1675518507 * 1000));
    });

    test('parses datetime string', () {
      final parsed = parseObtainedAtFromCharacterJson({
        'wear_time': '2023-04-21 20:54:19',
      });
      expect(parsed?.year, 2023);
      expect(parsed?.month, 4);
      expect(parsed?.day, 21);
    });
  });
}
