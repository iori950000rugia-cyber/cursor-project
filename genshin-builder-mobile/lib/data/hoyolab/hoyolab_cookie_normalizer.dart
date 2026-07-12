/// Parse / normalize HoYoLAB cookie header strings (no logging of bodies).
class HoyolabCookieNormalizer {
  HoyolabCookieNormalizer._();

  /// Typical HoYoLAB jars are far smaller; reject only pathological input.
  static const maxRawLength = 16384;

  /// Generous cap so normal multi-domain jars are not rejected.
  static const maxEntries = 200;

  static const tokenKeys = {'ltoken_v2', 'ltoken'};

  /// Parse cookie header into a name→value map (later keys win within [raw]).
  static Map<String, String>? parseToMap(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    if (trimmed.length > maxRawLength) return null;

    final map = <String, String>{};
    for (final part in trimmed.split(';')) {
      final segment = part.trim();
      if (segment.isEmpty) continue;
      if (_hasControlChars(segment)) continue;

      final eq = segment.indexOf('=');
      if (eq <= 0) continue;
      final key = segment.substring(0, eq).trim();
      final value = segment.substring(eq + 1).trim();
      if (key.isEmpty || value.isEmpty) continue;
      if (_hasControlChars(key) || _hasControlChars(value)) continue;
      map[key] = value;
      if (map.length > maxEntries) return null;
    }
    if (map.isEmpty) return null;
    return map;
  }

  /// Serialize map to a Cookie header with a trailing semicolon.
  static String serialize(Map<String, String> map) {
    if (map.isEmpty) return '';
    final body = map.entries.map((e) => '${e.key}=${e.value}').join('; ');
    return body.endsWith(';') ? body : '$body;';
  }

  /// Minimum form check: exact token key with non-empty value.
  static bool hasRequiredToken(Map<String, String> map) {
    for (final key in tokenKeys) {
      final value = map[key];
      if (value != null && value.isNotEmpty) return true;
    }
    return false;
  }

  /// Parse, require token key, return normalized header — or null.
  static String? normalize(String? raw) {
    final map = parseToMap(raw);
    if (map == null || !hasRequiredToken(map)) return null;
    return serialize(map);
  }

  /// Merge maps: [base] wins on key conflict; [fill] only adds missing keys.
  static Map<String, String> mergePreferBase({
    required Map<String, String> base,
    required Map<String, String> fill,
  }) {
    final out = Map<String, String>.from(base);
    for (final e in fill.entries) {
      if (!out.containsKey(e.key)) {
        out[e.key] = e.value;
      }
    }
    return out;
  }

  static bool _hasControlChars(String s) {
    for (var i = 0; i < s.length; i++) {
      final c = s.codeUnitAt(i);
      if (c <= 0x1F || c == 0x7F) return true;
    }
    return false;
  }
}
