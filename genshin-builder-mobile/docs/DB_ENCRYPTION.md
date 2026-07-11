# DB Encryption (SQLCipher)

ローカル Drift DB（`genshin_builder.db`）の任意暗号化。

## 既定動作（安全側）

- `--dart-define=ENABLE_SQLCIPHER` 未指定 / `false` → **平文 SQLite**（従来どおり）
- 既存インストールの DB はそのまま開ける
- ネイティブは `sqlcipher_flutter_libs` のみ（`sqlite3_flutter_libs` と同時依存不可）。フラグ OFF では PRAGMA key を実行しない

## 有効化

```bash
flutter run --dart-define=ENABLE_SQLCIPHER=true
```

有効時:

1. `SecureStorageService.getOrCreateDbKey()` で 32 バイト鍵を Secure Storage に保存
2. `NativeDatabase` の `setup` で `PRAGMA key = '…'` を実行
3. Android では `openCipherOnAndroid` + 旧端末向け workaround を適用

## 注意

- **平文 DB に後から鍵を付けても透過的には暗号化されない**。既存データを暗号化したい場合はアプリデータ削除後の再同期、または別途マイグレーションが必要
- 鍵はログ・UI・コミットに出さない
- applicationId / 署名設定とは独立（本ドキュメントは DB のみ）

## 関連コード

- `lib/data/db/drift/app_database.dart` — `kEnableSqlCipher` / `open`
- `lib/data/secure/secure_storage_service.dart` — `getOrCreateDbKey`
- `lib/data/secure/secure_storage_keys.dart` — `dbEncryptionKey`
