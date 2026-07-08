# Phase 2 — HoYoLAB 連携（設計 + 骨組み）

[genshin_material](https://github.com/chika3742/genshin_material) の HoYoLAB 実装を **参考** に、本プロジェクト用コードとして新規作成する（ソース転載しない）。

## ゴール（Phase 2 完了時）

1. WebView で HoYoLAB にログイン → Cookie を secure storage に保存
2. UID / server (region) を選択・保存
3. ホーム or 設定に **dailyNote**（天然樹脂 / 濃縮樹脂 / デイリー）を表示
4. ログアウト・Cookie 失効時のエラーハンドリング

## 骨組み（今回作成するファイル — 実装は段階的）

| ファイル | 状態 | 責務 |
|----------|------|------|
| `pigeon/hoyolab_integration.dart` | 定義のみ | `@HostApi()` `String fetchCookie()` |
| `lib/platform/pigeon/hoyolab_integration.g.dart` | codegen | Pigeon 生成物 |
| `android/.../HoyolabIntegrationApiImpl.kt` | スタブ | WebView Cookie → Dart |
| `ios/Runner/HoyolabIntegrationApiImpl.swift` | スタブ | 同上 |
| `lib/data/secure/secure_storage_service.dart` | インターフェース + 実装 | cookie / uid / region キー |
| `lib/data/hoyolab/hoyolab_session.dart` | モデル | ログイン状態 |
| `lib/data/hoyolab/hoyolab_auth.dart` | DS 署名 | `_getDsToken`, headers |
| `lib/data/hoyolab/hoyolab_api.dart` | API | verifyLToken, getDailyNote, getUserGameRoles |
| `lib/data/hoyolab/models/daily_note.dart` | JSON モデル | 樹脂・派遣・ボス等 |
| `lib/data/repositories/hoyolab_repository.dart` | 統合 | session + api + secure |
| `lib/features/hoyolab/hoyolab_login_screen.dart` | UI | WebView + ログイン完了 |
| `lib/features/hoyolab/widgets/daily_note_card.dart` | UI | 樹脂表示 |
| `lib/providers/hoyolab_providers.dart` | Riverpod | session, dailyNote |

## アーキテクチャ

```
features/hoyolab/hoyolab_login_screen
    │
    ├─ webview_flutter → https://act.hoyolab.com/...
    │
    └─ HoyolabIntegrationApi.fetchCookie()  [Pigeon]
            │
            ▼
    secure_storage_service.save(cookie)
            │
            ▼
    hoyolab_api.verifyLToken()
    hoyolab_api.getUserGameRoles() → uid, region 保存
            │
            ▼
    hoyolab_api.getDailyNote() → DailyNote
            │
            ▼
    home_screen / daily_note_card
```

## API 仕様メモ（自前実装）

### 共通ヘッダ

```dart
User-Agent: miHoYoBBSOversea/{appVersion}
Origin: https://act.hoyolab.com
Referer: https://act.hoyolab.com/
Cookie: {stored cookie}
x-rpc-client_type: 2
x-rpc-app_version: {appVersion}   // 例 4.13.0 — 要追従
x-rpc-language: ja-jp
DS: {t},{r},{md5}
```

### DS 署名（グローバル）

```
salt = okr4obncj8bw5a65hbnn5oo6ixjc3l9w
t = floor(now_ms / 1000)
r = 100000 + random(0..99999)
q = urlencode sorted query "key=value&..."
b = request body string (GET は "")
c = md5("salt={salt}&t={t}&r={r}&b={b}&q={q}")
DS = "{t},{r},{c}"
```

### dailyNote

- GET `https://bbs-api-os.hoyolab.com/game_record/app/genshin/api/dailyNote`
- Query: `role_id={uid}`, `server={region}`
- retcode `10102`: リアルタイムメモ未公開 → ユーザーに HoYoLAB で公開設定を案内

### 既知 retcode（サイレント扱い検討）

| retcode | 意味 |
|---------|------|
| -100 | ログイン期限切れ → 再ログイン |
| 10102 | リアルタイムメモ OFF |
| -502001 | キャラ不存在 |
| -502002 | キャラデータ非公開 |

## Secure Storage キー

| キー | 内容 |
|------|------|
| `hoyolab_cookie` | ログイン Cookie 全文 |
| `hoyolab_uid` | ゲーム内 UID |
| `hoyolab_region` | サーバー (os_asia 等) |
| `hoyolab_app_version` | x-rpc-app_version 上書き用（任意） |

## Pigeon 定義（案）

```dart
// pigeon/hoyolab_integration.dart
@HostApi()
abstract class HoyolabIntegrationApi {
  @async
  String fetchCookie();
}
```

ネイティブ側: WebView の `CookieManager` から `.hoyolab.com` / `.mihoyo.com` ドメインの Cookie を連結して返す。

## Phase 2 実装順（骨組み後）

| 順 | タスク |
|----|--------|
| P2-1 | Pigeon + Android/iOS スタブ（固定文字列返却で結線確認） |
| P2-2 | secure_storage + hoyolab_session |
| P2-3 | hoyolab_auth（DS 単体テスト） |
| P2-4 | hoyolab_api.getDailyNote + モデル |
| P2-5 | WebView ログイン画面 |
| P2-6 | ホーム dailyNote ウィジェット |
| P2-7 | verifyLToken / ログアウト / エラー UI |

## Phase 1 との境界

- Phase 1 の Drift に `app_settings` テーブルを用意し、Phase 2 で HoYoLAB キーを追加（migration v2）
- 育成計算 (`domain/`) は HoYoLAB に依存しない
- HoYoLAB からのキャラ Lv 取り込みは Phase 2 後半（`avatarList` / batch_compute）— 初期は dailyNote のみ

## セキュリティチェックリスト

- [ ] Cookie をログ出力しない
- [ ] secure_storage のみ（debug ビルドも原則同様）
- [ ] ユーザー明示操作でのみログイン
- [ ] 非公式ツール免責を HoYoLAB 設定画面に表示

## 参考リンク

- genshin_material `lib/core/hoyolab_api.dart` — API 一覧・DS・キュー
- genshin_material `lib/pigeon.g.dart` — `HoyolabIntegrationApi`
- [HoYoLAB 開発者向け情報](https://github.com/DGP-Studio/Snap.HoyoLab) 等のコミュニティドキュメント（非公式）
