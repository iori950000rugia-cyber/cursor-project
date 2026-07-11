import 'dart:convert';

import 'package:crypto/crypto.dart';

/// 突破データの内容ハッシュ（MD5）。差分検知・マイグレーション後の再取得に使う。
String computeUpgradeContentHash({
  required String promotesJson,
  required String secondaryJson,
}) {
  final payload = '$promotesJson|$secondaryJson';
  return md5.convert(utf8.encode(payload)).toString();
}
