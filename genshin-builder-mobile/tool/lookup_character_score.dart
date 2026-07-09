import 'dart:convert';
import 'dart:io';

import 'package:genshin_builder_mobile/domain/artifact_score.dart';

Future<void> main() async {
  final client = HttpClient();
  final res = await client.getUrl(
    Uri.parse('https://gi.yatta.moe/api/v2/jp/avatar'),
  );
  final body = await (await res.close()).transform(utf8.decoder).join();
  final items = (jsonDecode(body)['data'] as Map)['items'] as Map;

  for (final raw in items.values) {
    final a = raw as Map<String, dynamic>;
    final name = a['name'] as String? ?? '';
    if (!name.contains('コロンビーナ') && !name.toLowerCase().contains('columbina')) {
      continue;
    }
    final sp = a['specialProp'];
    final inferred = inferScoreType(sp as String?, name);
    print('id: ${a['id']}');
    print('name: $name');
    print('specialProp: $sp');
    print('inferScoreType: ${artifactScoreTypeToStorage(inferred)}');
  }

  client.close();
}
