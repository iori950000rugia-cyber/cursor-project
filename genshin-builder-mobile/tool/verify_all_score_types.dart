import 'dart:convert';
import 'dart:io';

import 'package:genshin_builder_mobile/data/artifact_score/artifact_score_weight_repository.dart';
import 'package:genshin_builder_mobile/data/artifact_score/local_json_artifact_score_weight_source.dart';
import 'package:genshin_builder_mobile/data/models/master_models.dart';
import 'package:genshin_builder_mobile/domain/artifact_score.dart';
import 'package:genshin_builder_mobile/domain/artifact_score_resolver.dart';

/// 全キャラの取得基準を Amber API と照合する。
/// `dart run tool/verify_all_score_types.dart`
Future<void> main() async {
  final client = HttpClient();
  final req = await client.getUrl(
    Uri.parse('https://gi.yatta.moe/api/v2/jp/avatar'),
  );
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body) as Map<String, dynamic>;
  final items = (json['data'] as Map)['items'] as Map<String, dynamic>;

  final repo = ArtifactScoreWeightRepository(
    LocalJsonArtifactScoreWeightSource(),
  );
  final profiles = await repo.loadProfiles();
  final profileIds = {for (final p in profiles) p.characterId: p};

  final resolver = ArtifactScoreResolver(repo);
  final mismatches = <String>[];
  final summary = <String, int>{};
  var total = 0;

  for (final raw in items.values) {
    final a = raw as Map<String, dynamic>;
    final name = a['name'] as String?;
    final elementKey = a['element'] as String?;
    if (name == null || elementKey == null) continue;
    final id = '${a['id']}';
    if (id.startsWith('10000007-')) continue;

    total++;
    final isTraveler = id.startsWith('10000005-');
    final displayName = isTraveler
        ? '旅人（${_elementLabel(elementKey)}）'
        : name;
    final sp = a['specialProp'] as String?;

    final inferred = inferScoreType(sp, displayName);
    final character = MasterCharacter(
      id: id,
      name: displayName,
      element: 'pyro',
      weaponType: 'sword',
      rarity: 5,
      region: '',
      iconUrl: '',
      scoreType: artifactScoreTypeToStorage(inferred),
    );

    final settings = await resolver.resolve(character: character);
    final actual = artifactScoreTypeToStorage(settings.scoreType);

    // 期待値: 重みJSONがあればそちらを優先、なければ inferScoreType
    String expected = artifactScoreTypeToStorage(inferred);
    final profile = profileIds[id];
    if (profile != null) {
      expected = artifactScoreTypeToStorage(
        inferArtifactScoreTypeFromWeights(profile.weights) ?? inferred,
      );
    }

    summary[actual] = (summary[actual] ?? 0) + 1;

    if (actual != expected) {
      mismatches.add('$displayName ($id): expected=$expected actual=$actual');
    }
  }

  print('=== 全キャラ取得基準 検証 ($total 体) ===\n');
  print('解決結果:');
  for (final e in summary.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value))) {
    print('  ${e.key}: ${e.value}体');
  }

  if (mismatches.isEmpty) {
    print('\n✓ すべてのキャラで取得基準が期待値と一致');
  } else {
    print('\n✗ 不一致 ${mismatches.length}体:');
    for (final m in mismatches) {
      print('  $m');
    }
    exitCode = 1;
  }

  client.close();
}

String _elementLabel(String elementKey) => switch (elementKey) {
      'Fire' => '炎',
      'Water' => '水',
      'Electric' => '雷',
      'Ice' => '氷',
      'Wind' => '風',
      'Rock' => '岩',
      'Grass' => '草',
      _ => elementKey,
    };
