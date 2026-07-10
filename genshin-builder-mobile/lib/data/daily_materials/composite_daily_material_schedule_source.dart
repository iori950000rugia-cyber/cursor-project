import '../../domain/daily_materials/daily_material_models.dart';
import 'daily_material_schedule_repository.dart';

/// ローカル asset を正本とし、リモート version が同等以上ならリモートを採用する。
class CompositeDailyMaterialScheduleSource
    implements DailyMaterialScheduleSource {
  CompositeDailyMaterialScheduleSource({
    required DailyMaterialScheduleSource localSource,
    DailyMaterialScheduleSource? remoteSource,
    this.refreshInterval = const Duration(hours: 12),
  })  : _local = localSource,
        _remote = remoteSource;

  final DailyMaterialScheduleSource _local;
  final DailyMaterialScheduleSource? _remote;
  final Duration refreshInterval;

  DailyMaterialSchedule? _cache;
  DateTime? _lastRefreshAt;

  @override
  Future<DailyMaterialSchedule> load() async {
    if (_cache != null && !_shouldRefresh()) return _cache!;
    try {
      _cache = await _resolve();
      _lastRefreshAt = DateTime.now();
    } catch (_) {
      if (_cache != null) return _cache!;
      rethrow;
    }
    return _cache!;
  }

  bool _shouldRefresh() {
    final last = _lastRefreshAt;
    if (last == null) return true;
    return DateTime.now().difference(last) >= refreshInterval;
  }

  Future<DailyMaterialSchedule> _resolve() async {
    final local = await _local.load();
    final remote = _remote;
    if (remote == null) return local;
    try {
      final remoteSchedule = await remote.load();
      if (remoteSchedule.version >= local.version) {
        return remoteSchedule;
      }
    } catch (_) {
      // リモート失敗時はローカル asset を使う
    }
    return local;
  }
}
