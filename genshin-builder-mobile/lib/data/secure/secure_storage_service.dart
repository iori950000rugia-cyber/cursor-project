import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'secure_storage_keys.dart';

/// Cookie / UID / region を端末内暗号化保存（SharedPreferences 禁止）
class SecureStorageService {
  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
            );

  final FlutterSecureStorage _storage;

  Future<String?> read(String key) => _storage.read(key: key);

  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  Future<void> delete(String key) => _storage.delete(key: key);

  Future<void> deleteHoyolabSession() async {
    for (final key in [
      SecureStorageKeys.cookie,
      SecureStorageKeys.uid,
      SecureStorageKeys.region,
      SecureStorageKeys.nickname,
    ]) {
      await delete(key);
    }
  }

  Future<String?> getCookie() => read(SecureStorageKeys.cookie);

  Future<void> saveCookie(String cookie) =>
      write(SecureStorageKeys.cookie, cookie);

  Future<String?> getUid() => read(SecureStorageKeys.uid);

  Future<String?> getRegion() => read(SecureStorageKeys.region);

  Future<String?> getNickname() => read(SecureStorageKeys.nickname);

  Future<void> saveRole({
    required String uid,
    required String region,
    String? nickname,
  }) async {
    await write(SecureStorageKeys.uid, uid);
    await write(SecureStorageKeys.region, region);
    if (nickname != null) {
      await write(SecureStorageKeys.nickname, nickname);
    }
  }

  Future<String?> getAppVersionOverride() =>
      read(SecureStorageKeys.appVersion);

  Future<void> saveAppVersionOverride(String version) =>
      write(SecureStorageKeys.appVersion, version);
}
