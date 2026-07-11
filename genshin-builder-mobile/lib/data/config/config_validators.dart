/// リモート / ローカル設定 JSON の最低限バリデーション。
/// 失敗時は [FormatException] を投げ、composite source がフォールバックできるようにする。
library;

void validateArtifactScoreWeightsJson(Map<String, dynamic> json) {
  final profiles = json['profiles'];
  if (profiles is! List || profiles.isEmpty) {
    throw const FormatException(
      'artifact_score_weights: profiles must be a non-empty list',
    );
  }
  for (var i = 0; i < profiles.length; i++) {
    final item = profiles[i];
    if (item is! Map) {
      throw FormatException(
        'artifact_score_weights: profiles[$i] must be an object',
      );
    }
    final map = Map<String, dynamic>.from(item);
    final characterId = '${map['characterId'] ?? ''}'.trim();
    if (characterId.isEmpty) {
      throw FormatException(
        'artifact_score_weights: profiles[$i].characterId is required',
      );
    }
    final weights = map['weights'];
    if (weights is! Map) {
      throw FormatException(
        'artifact_score_weights: profiles[$i].weights is required',
      );
    }
  }
}

void validateDailyMaterialScheduleJson(Map<String, dynamic> json) {
  final version = json['version'];
  if (version is! num) {
    throw const FormatException(
      'daily_material_schedule: version must be a number',
    );
  }

  void validateSeries(String key, {bool required = true}) {
    final list = json[key];
    if (list == null) {
      if (required) {
        throw FormatException(
          'daily_material_schedule: $key must be a non-empty list',
        );
      }
      return;
    }
    if (list is! List) {
      throw FormatException(
        'daily_material_schedule: $key must be a list',
      );
    }
    if (required && list.isEmpty) {
      throw FormatException(
        'daily_material_schedule: $key must be a non-empty list',
      );
    }
    for (var i = 0; i < list.length; i++) {
      final item = list[i];
      if (item is! Map) {
        throw FormatException(
          'daily_material_schedule: $key[$i] must be an object',
        );
      }
      final map = Map<String, dynamic>.from(item);
      final id = '${map['id'] ?? ''}'.trim();
      if (id.isEmpty) {
        throw FormatException(
          'daily_material_schedule: $key[$i].id is required',
        );
      }
      final materialIds = map['materialIds'];
      if (materialIds is! List || materialIds.isEmpty) {
        throw FormatException(
          'daily_material_schedule: $key[$i].materialIds must be non-empty',
        );
      }
      for (final mid in materialIds) {
        if ('$mid'.trim().isEmpty) {
          throw FormatException(
            'daily_material_schedule: $key[$i].materialIds contains empty id',
          );
        }
      }
      final days = map['days'];
      if (days is! List || days.isEmpty) {
        throw FormatException(
          'daily_material_schedule: $key[$i].days must be non-empty',
        );
      }
      for (final d in days) {
        final day = d is num ? d.toInt() : int.tryParse('$d');
        if (day == null || day < 1 || day > 7) {
          throw FormatException(
            'daily_material_schedule: $key[$i].days must be 1–7 (got $d)',
          );
        }
      }
    }
  }

  validateSeries('talentSeries');
  validateSeries('weaponSeries');
  validateSeries('artifactSeries', required: false);
  validateSeries('weeklyBossSeries', required: false);
}
