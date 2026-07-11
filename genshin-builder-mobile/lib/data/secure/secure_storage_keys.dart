/// HoYoLAB 連携のストレージキー（Cookie は secure storage のみ）
class SecureStorageKeys {
  SecureStorageKeys._();

  static const cookie = 'hoyolab_cookie';
  static const uid = 'hoyolab_uid';
  static const region = 'hoyolab_region';
  static const nickname = 'hoyolab_nickname';
  static const appVersion = 'hoyolab_app_version';

  /// SQLCipher DB 鍵（ENABLE_SQLCIPHER=true 時のみ使用）
  static const dbEncryptionKey = 'db_encryption_key';
}
