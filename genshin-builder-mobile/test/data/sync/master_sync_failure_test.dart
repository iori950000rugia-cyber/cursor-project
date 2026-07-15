import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:genshin_builder_mobile/data/amber/amber_api.dart';
import 'package:genshin_builder_mobile/data/artifact_score/artifact_score_type_override_registry.dart';
import 'package:genshin_builder_mobile/data/config/remote_json_fetch.dart';
import 'package:genshin_builder_mobile/data/db/app_database.dart';
import 'package:genshin_builder_mobile/data/models/master_models.dart';
import 'package:genshin_builder_mobile/data/sync/master_sync_service.dart';

void main() {
  group('Amber response validation', () {
    setUp(() {
      ArtifactScoreTypeOverrideRegistry.instance.useOverridesForTest({});
    });

    tearDown(() {
      ArtifactScoreTypeOverrideRegistry.instance.resetForTest();
    });

    test(
      'rejects malformed, missing, null, duplicate, and negative data',
      () async {
        final bodies = <String>[
          '',
          '<html>failure</html>',
          '{"response":200',
          '[]',
          '"string"',
          '{"response":200}',
          '{"response":200,"data":{"items":[]}}',
          '{"response":200,"data":{"items":{"a":null}}}',
          '{"response":200,"data":{"items":{"a":"wrong"}}}',
          jsonEncode({
            'response': 200,
            'data': {
              'items': {
                'a': _validCharacter(id: '10000002'),
                'b': _validCharacter(id: '10000002'),
              },
            },
          }),
          jsonEncode({
            'response': 200,
            'data': {
              'items': {'a': _validCharacter(id: '10000002', rank: -1)},
            },
          }),
        ];

        for (final body in bodies) {
          final api = AmberApi(
            client: MockClient((_) async => http.Response(body, 200)),
          );
          await expectLater(api.fetchCharacters(), throwsA(anything));
          api.dispose();
        }
      },
    );

    test('ignores unknown fields in otherwise valid data', () async {
      final api = AmberApi(
        client: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'response': 200,
              'unknownRoot': true,
              'data': {
                'unknownData': 1,
                'items': {
                  'a': {
                    ..._validCharacter(id: '10000002'),
                    'unknownRecord': {'nested': true},
                  },
                },
              },
            }),
            200,
          ),
        ),
      );

      final characters = await api.fetchCharacters();
      expect(characters, hasLength(1));
      expect(characters.single.id, '10000002');
      api.dispose();
    });

    test(
      'rejects 500 family, network disconnect, and oversized body',
      () async {
        for (final status in [500, 502, 503, 504]) {
          final api = AmberApi(
            client: MockClient(
              (_) async => http.Response('<html>internal</html>', status),
            ),
          );
          await expectLater(
            api.fetchCharacters(),
            throwsA(
              isA<RemoteJsonFetchException>().having(
                (e) => e.statusCode,
                'statusCode',
                status,
              ),
            ),
          );
          api.dispose();
        }

        final disconnected = AmberApi(
          client: MockClient((_) async {
            throw http.ClientException('network disconnected');
          }),
        );
        await expectLater(
          disconnected.fetchCharacters(),
          throwsA(
            isA<RemoteJsonFetchException>().having(
              (e) => e.failure,
              'failure',
              RemoteJsonFailureKind.networkError,
            ),
          ),
        );
        disconnected.dispose();

        final oversized = AmberApi(
          client: MockClient(
            (_) async => http.Response('x' * (8 * 1024 * 1024 + 1), 200),
          ),
        );
        await expectLater(
          oversized.fetchCharacters(),
          throwsA(
            isA<RemoteJsonFetchException>().having(
              (e) => e.failure,
              'failure',
              RemoteJsonFailureKind.responseTooLarge,
            ),
          ),
        );
        oversized.dispose();
      },
    );
  });

  group('MasterSyncService failure safety', () {
    late AppDatabase db;

    setUp(() async {
      ArtifactScoreTypeOverrideRegistry.instance.useOverridesForTest({});
      db = await AppDatabase.openInMemory();
      await db.upsertCharactersBatch([_masterCharacter('existing')]);
    });

    tearDown(() async {
      ArtifactScoreTypeOverrideRegistry.instance.resetForTest();
      await db.close();
    });

    test('overall timeout prevents late response from changing DB', () async {
      final gate = Completer<List<MasterCharacter>>();
      final api = _FakeAmberApi(characters: () => gate.future);
      final service = MasterSyncService(
        amberApi: api,
        db: db,
        syncUpgradeDetails: false,
        overallTimeout: const Duration(milliseconds: 20),
      );

      await expectLater(
        service.syncMasterData(),
        throwsA(isA<TimeoutException>()),
      );
      gate.complete([_masterCharacter('late')]);
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect((await db.getAllCharacters()).map((item) => item.id), [
        'existing',
      ]);
      api.dispose();
    });

    test('write failure rolls back the category and redacts details', () async {
      final api = _FakeAmberApi(
        characters: () async => [_masterCharacter('new')],
      );
      final service = MasterSyncService(
        amberApi: api,
        db: db,
        syncUpgradeDetails: false,
        writeFaultHook: (point) {
          if (point == MasterSyncWritePoint.characters) {
            throw StateError('secret path and internal SQL');
          }
        },
      );

      final result = await service.syncMasterData();

      expect((await db.getAllCharacters()).map((item) => item.id), [
        'existing',
      ]);
      expect(result.errors, contains('characters:unavailable'));
      expect(result.errors.join(), isNot(contains('secret path')));
      api.dispose();
    });

    test(
      '500 responses preserve prior data and produce safe error codes',
      () async {
        final api = AmberApi(
          client: MockClient(
            (_) async => http.Response('<html>upstream detail</html>', 500),
          ),
        );
        final service = MasterSyncService(
          amberApi: api,
          db: db,
          syncUpgradeDetails: false,
        );

        final result = await service.syncMasterData();

        expect((await db.getAllCharacters()).map((item) => item.id), [
          'existing',
        ]);
        expect(result.errors, hasLength(3));
        expect(
          result.errors.every((error) => error.endsWith(':httpStatus')),
          isTrue,
        );
        expect(result.errors.join(), isNot(contains('<html>')));
        api.dispose();
      },
    );
  });
}

Map<String, Object?> _validCharacter({required String id, int rank = 5}) => {
  'id': id,
  'name': 'Character $id',
  'rank': rank,
  'element': 'Ice',
  'weaponType': 'WEAPON_SWORD_ONE_HAND',
  'region': 'INAZUMA',
  'icon': 'UI_AvatarIcon_Test',
};

MasterCharacter _masterCharacter(String id) => MasterCharacter(
  id: id,
  name: id,
  element: 'cryo',
  weaponType: 'sword',
  rarity: 5,
  region: 'Inazuma',
  iconUrl: '',
);

class _FakeAmberApi extends AmberApi {
  _FakeAmberApi({required this.characters});

  final Future<List<MasterCharacter>> Function() characters;

  @override
  Future<List<MasterCharacter>> fetchCharacters() => characters();

  @override
  Future<List<MasterWeapon>> fetchWeapons() async => const [];

  @override
  Future<List<MasterMaterial>> fetchMaterials() async => const [];
}
