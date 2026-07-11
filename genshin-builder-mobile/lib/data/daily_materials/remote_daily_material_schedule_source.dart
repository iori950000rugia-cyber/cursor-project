import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/daily_materials/daily_material_models.dart';
import '../config/config_validators.dart';
import 'daily_material_schedule_repository.dart';

/// リモート JSON から曜日スケジュールを取得（`--dart-define=DAILY_MATERIAL_SCHEDULE_URL=`）
class RemoteDailyMaterialScheduleSource
    implements DailyMaterialScheduleSource {
  RemoteDailyMaterialScheduleSource({
    required this.url,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final String url;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<DailyMaterialSchedule> load() async {
    if (url.isEmpty) {
      throw StateError('DAILY_MATERIAL_SCHEDULE_URL is empty');
    }
    final response = await _client.get(Uri.parse(url)).timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception(
        'daily material schedule remote error: ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    validateDailyMaterialScheduleJson(decoded);
    return DailyMaterialSchedule.fromJson(decoded);
  }
}
