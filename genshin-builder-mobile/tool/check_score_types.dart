import 'dart:convert';
import 'dart:io';

/// 全キャラの取得基準を検証するツール。
/// 期待値: Web版 inferScoreType + モバイル名前マップ + 重みJSON
void main() async {
  final client = HttpClient();
  final req = await client.getUrl(
    Uri.parse('https://gi.yatta.moe/api/v2/jp/avatar'),
  );
  final res = await req.close();
  final body = await res.transform(utf8.decoder).join();
  final json = jsonDecode(body) as Map<String, dynamic>;
  final items = (json['data'] as Map)['items'] as Map<String, dynamic>;

  const weightProfiles = {
    '10000052': 'recharge', // 雷電将軍
    '10000046': 'hp', // 胡桃
    '10000042': 'atk', // 刻晴
  };

  final currentWrong = <String>[];
  final byType = <String, int>{};

  for (final raw in items.values) {
    final a = raw as Map<String, dynamic>;
    final name = a['name'] as String?;
    final elementKey = a['element'] as String?;
    if (name == null || elementKey == null) continue;
    final id = '${a['id']}';
    if (id.startsWith('10000007-')) continue;

    final isTraveler = id.startsWith('10000005-');
    final displayName = isTraveler
        ? '旅人（${_elementLabel(elementKey)}）'
        : name;
    final sp = a['specialProp'] as String?;

    final expected = weightProfiles[id] ?? _infer(sp, displayName);
    final current = _currentMobileResolve(displayName, scoreTypeDb: '');

    byType[expected] = (byType[expected] ?? 0) + 1;

    if (current != expected) {
      currentWrong.add(
        '$displayName ($id): 現在=$current 期待=$expected specialProp=$sp',
      );
    }
  }

  print('=== 全キャラ取得基準 検証 (${byType.values.fold(0, (a, b) => a + b)}体) ===\n');
  print('期待値の内訳:');
  for (final e in byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value))) {
    print('  ${e.key}: ${e.value}体');
  }

  print('\n--- 現在のモバイル実装との不一致 (${currentWrong.length}体) ---');
  if (currentWrong.isEmpty) {
    print('なし（すべて一致）');
  } else {
    for (final line in currentWrong) {
      print('  $line');
    }
  }

  client.close();
}

String _currentMobileResolve(String name, {required String scoreTypeDb}) {
  // resolveArtifactScoreType の現行ロジック（DB空 + 名前マップのみ）
  const nameMap = {
    '胡桃': 'hp',
    '鍾離': 'hp',
    '珊瑚宮心海': 'hp',
    '夜蘭': 'hp',
    'ニィロウ': 'hp',
    'ディシア': 'hp',
    '白朮': 'hp',
    'フリーナ': 'hp',
    'ヌヴィレット': 'hp',
    'シグウィン': 'hp',
    'ムアラニ': 'hp',
    'コロンビーナ': 'hp',
    'ノエル': 'def',
    '荒瀧一斗': 'def',
    'ゴロー': 'def',
    '雲菫': 'def',
    '千織': 'def',
    'シロネン': 'def',
    'カチーナ': 'def',
    '楓原万葉': 'em',
    'スクロース': 'em',
    'ナヒーダ': 'em',
    '綺良々': 'em',
    'ヨォーヨ': 'em',
    'コレイ': 'em',
    'ティナリ': 'em',
    '久岐忍': 'em',
    'ラウマ': 'em',
    'アイノ': 'em',
    '雷電将軍': 'recharge',
  };
  return nameMap[name] ?? 'atk';
}

String _infer(String? specialProp, String name) {
  const nameOverrides = {
    '胡桃': 'hp',
    '鍾離': 'hp',
    '珊瑚宮心海': 'hp',
    '夜蘭': 'hp',
    'ニィロウ': 'hp',
    'ディシア': 'hp',
    '白朮': 'hp',
    'フリーナ': 'hp',
    'ヌヴィレット': 'hp',
    'シグウィン': 'hp',
    'ムアラニ': 'hp',
    'コロンビーナ': 'hp',
    'ノエル': 'def',
    '荒瀧一斗': 'def',
    'ゴロー': 'def',
    '雲菫': 'def',
    '千織': 'def',
    'シロネン': 'def',
    'カチーナ': 'def',
    '楓原万葉': 'em',
    'スクロース': 'em',
    'ナヒーダ': 'em',
    '綺良々': 'em',
    'ヨォーヨ': 'em',
    'コレイ': 'em',
    'ティナリ': 'em',
    '久岐忍': 'em',
    'ラウマ': 'em',
    'アイノ': 'em',
    '雷電将軍': 'recharge',
  };
  if (nameOverrides.containsKey(name)) return nameOverrides[name]!;
  return switch (specialProp) {
    'FIGHT_PROP_HP_PERCENT' => 'hp',
    'FIGHT_PROP_DEFENSE_PERCENT' => 'def',
    'FIGHT_PROP_ELEMENT_MASTERY' => 'em',
    'FIGHT_PROP_CHARGE_EFFICIENCY' => 'recharge',
    'FIGHT_PROP_ATTACK_PERCENT' => 'atk',
    _ => 'atk',
  };
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
