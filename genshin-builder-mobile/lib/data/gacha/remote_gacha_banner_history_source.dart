import 'package:http/http.dart' as http;

import '../../domain/gacha/gacha_banner_schedule.dart';
import '../config/config_load_log.dart';
import '../config/remote_json_fetch.dart';
import 'asset_gacha_banner_history_source.dart';

const _configKind = 'gacha_banner_history';

/// リモート JSON からバナー履歴を取得（`--dart-define=GACHA_BANNER_HISTORY_URL=`）
class RemoteGachaBannerHistorySource implements GachaBannerHistorySource {
  RemoteGachaBannerHistorySource({
    required this.url,
    http.Client? client,
    this.timeout = const Duration(seconds: 10),
  }) : _client = client ?? http.Client();

  final String url;
  final http.Client _client;
  final Duration timeout;

  @override
  Future<GachaBannerSchedule> load() async {
    if (url.isEmpty) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.unexpected,
      );
    }
    final decoded = await fetchRemoteJsonMap(
      client: _client,
      url: url,
      kind: _configKind,
      timeout: timeout,
      maxBytes: kRemoteJsonMaxBytesGachaBannerHistory,
    );
    try {
      // domain validator + parse (lib/domain is not modified).
      return GachaBannerSchedule.fromJson(decoded);
    } on FormatException catch (e) {
      throw configLoadFromFormatException(kind: _configKind, error: e);
    } catch (_) {
      throw const ConfigLoadException(
        kind: _configKind,
        failure: ConfigLoadFailureKind.unexpected,
      );
    }
  }
}
