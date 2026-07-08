import 'dart:convert';

import 'package:http/http.dart' as http;

import 'hoyolab_auth.dart';
import 'hoyolab_constants.dart';
import 'hoyolab_exceptions.dart';
import 'models/daily_note.dart';

class HoyolabApiResult<T> {
  const HoyolabApiResult({
    required this.retcode,
    required this.message,
    this.data,
  });

  final int retcode;
  final String message;
  final T? data;

  bool get hasError => retcode != 0;

  factory HoyolabApiResult.fromJson(
    Map<String, dynamic> json,
    T Function(Object? obj) fromJsonT,
  ) =>
      HoyolabApiResult(
        retcode: json['retcode'] as int? ?? -1,
        message: json['message'] as String? ?? '',
        data: json['data'] == null ? null : fromJsonT(json['data']),
      );
}

/// HoYoLAB API クライアント（genshin_material 参考・自前実装）
class HoyolabApi {
  HoyolabApi({
    required this.cookie,
    this.region,
    this.uid,
    this.appVersion = HoyolabConstants.defaultAppVersion,
    http.Client? client,
    ApiRequestQueue? queue,
  })  : _client = client ?? http.Client(),
        _queue = queue ?? _sharedQueue;

  final String? cookie;
  final String? region;
  final String? uid;
  final String appVersion;
  final http.Client _client;
  final ApiRequestQueue _queue;

  static final _sharedQueue = ApiRequestQueue();

  Future<List<HoyolabRegion>> lookupRegions() {
    return _queue.run(() async {
      final uri = Uri.parse(
        '${HoyolabConstants.getAllRegionsUrl}?game_biz=hk4e_global',
      );
      final response = await _client.get(uri);
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final result = HoyolabApiResult<List<HoyolabRegion>>.fromJson(
        json,
        (obj) => (obj as List<dynamic>)
            .map((e) => HoyolabRegion.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
      if (result.hasError) {
        throw HoyolabApiException(result.retcode, result.message);
      }
      return result.data ?? [];
    });
  }

  Future<HoyolabUserInfo> verifyLToken() {
    _ensureCookie();
    return _queue.run(() async {
      final response = await _client.post(
        Uri.parse(HoyolabConstants.verifyLTokenUrl),
        headers: HoyolabAuth.buildHeaders(
          cookie: cookie!,
          appVersion: appVersion,
        ),
      );
      return _parse(
        response.body,
        (obj) => HoyolabUserInfo.fromJson(
          (obj as Map<String, dynamic>)['user_info'] as Map<String, dynamic>,
        ),
      );
    });
  }

  Future<List<HoyolabGameRole>> getUserGameRoles({required String region}) {
    _ensureCookie();
    return _queue.run(() async {
      final uri = Uri.parse(
        '${HoyolabConstants.getUserGameRolesUrl}?game_biz=hk4e_global&region=$region',
      );
      final response = await _client.get(
        uri,
        headers: HoyolabAuth.buildHeaders(
          cookie: cookie!,
          appVersion: appVersion,
        ),
      );
      return _parseList(
        response.body,
        (json) => HoyolabGameRole.fromJson(json, region: region),
      );
    });
  }

  Future<DailyNote> getDailyNote() {
    _ensureDailyNoteParams();
    final query = {
      'role_id': uid!,
      'server': region!,
    };
    return _queue.run(() async {
      final uri = Uri.parse(HoyolabConstants.dailyNoteUrl)
          .replace(queryParameters: query);
      final ds = HoyolabAuth.generateDsToken(queryParameters: query);
      final response = await _client.get(
        uri,
        headers: HoyolabAuth.buildHeaders(
          cookie: cookie!,
          appVersion: appVersion,
          dsToken: ds,
        ),
      );
      return _parse(
        response.body,
        (obj) => DailyNote.fromJson(obj! as Map<String, dynamic>),
      );
    });
  }

  T _parse<T>(String body, T Function(Object? obj) fromJsonT) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final result = HoyolabApiResult<T>.fromJson(json, fromJsonT);
    if (result.hasError) {
      throw HoyolabApiException(result.retcode, result.message);
    }
    if (result.data == null) {
      throw const HoyolabApiException(-1, 'empty data');
    }
    return result.data as T;
  }

  List<T> _parseList<T>(
    String body,
    T Function(Map<String, dynamic> json) fromJsonItem,
  ) {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final result = HoyolabApiResult<List<T>>.fromJson(
      json,
      (obj) {
        final data = obj as Map<String, dynamic>;
        final list = data['list'] as List<dynamic>? ?? [];
        return list
            .map((e) => fromJsonItem(e as Map<String, dynamic>))
            .toList();
      },
    );
    if (result.hasError) {
      throw HoyolabApiException(result.retcode, result.message);
    }
    return result.data ?? [];
  }

  void _ensureCookie() {
    if (cookie == null || cookie!.isEmpty) {
      throw StateError('Missing cookie');
    }
  }

  void _ensureDailyNoteParams() {
    _ensureCookie();
    if (uid == null || uid!.isEmpty) {
      throw StateError('Missing uid');
    }
    if (region == null || region!.isEmpty) {
      throw StateError('Missing region');
    }
  }
}
