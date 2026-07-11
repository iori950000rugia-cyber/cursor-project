# Agent Memory — Genshin Builder Mobile

セッションごとの設計判断ログ。重要な決定のみ追記する。

## 2026-07-11 — 聖遺物一覧 UI（グリッド＋詳細ダイアログ）

- 一覧は地域セクション付き `GridView`（幅で 3/4/5/6 列）。セルはアイコン＋セット名
- アイコン URL は `UI_RelicIcon_*` → `assets/UI/reliquary/`（直下は 404）
- 地域は Amber `sortOrder` 帯 + 層岩例外。API に region が無いため
- 装備キャラ: **`/character/detail` の relics が正本**（`/character/list` は装備なし）。進捗 JSON はフォールバック。突合はアイコン ID → 名前/route/aliases。2部位以上のみ
- 所持ビルドは最大40件バッチ＋TTLキャッシュ。HoYoLAB 反映は即保存（debounce 破棄対策）


## 2026-07-11 — 聖遺物管理（育成完了・完成率・セット一覧）

- **育成完了**: 既存 `user_progress.is_completed` を `UserProgress.artifactCompleted` として利用（新テーブルなし）。キャラ詳細聖遺物タブでチェック、オフライン永続
- **完成率**: `domain/artifact_completion.dart` で計算のみ（装備/Lv/メイン/サブ/スコア）。DB には保存しない
- **装備紐づけ**: `/character/detail` relics を主、所持 list / 進捗 `artifacts` を副

- **セット一覧**: Amber `ArtifactSetDetail` + `/artifacts` タブ。推奨は `assets/config/artifact_set_recommendations.json`（名前キー）
- **ナビ**: ホーム/キャラ/曜日/聖遺物/素材/設定（曜日は維持）

## 2026-07-11 — contentHash / Level EXP JSON / 設定検証 / SQLCipher / hook 強化

- **突破 contentHash**: `CharacterUpgrades` / `WeaponUpgrades` に `contentHash`（schema v6）。upsert 時に promotes+talents（武器は levelUpItemIds）の MD5 を保存。通常同期は未取得・空ハッシュ UNION、加えて `refreshStaleUpgrades`（既定 true）で各最大 15 件ランダム再取得。設定画面に注記
- **Level EXP**: 正本 `assets/config/level_exp_table.json` + `LevelExpTableSource`。同期は asset → DB。`getAllLevelExpSegments` 追加。計算は従来どおり `UpgradeDataCache.levelExpSegments` 優先
- **設定検証**: `config_validators.dart` を remote source の `fromJson` 前に呼ぶ。`tool/validate_config_json.dart` + `assets/config/schemas/*.schema.json`
- **SQLCipher**: `sqlcipher_flutter_libs` のみ（`sqlite3_flutter_libs` は外した）。`ENABLE_SQLCIPHER=true` 時のみ PRAGMA key。既定 false で平文 DB 維持。`docs/DB_ENCRYPTION.md`
- **auto-commit**: `EXCLUDE_PATTERNS` / `SECRET_PATTERNS` 強化。pending に `files[]`。最大 40 ファイルでスキップ。diff に ltoken/cookie/PRIVATE KEY があれば中止
- **docs**: `DAILY_MATERIAL_SCHEDULE_REMOTE.md`（URL 設定手順）

## 2026-07-11 — 機能拡張 1–10（本番 applicationId 除く）

- **1** 想定ステータスに2セット効果（Web 同等テキスト抽出）
- **2** 命ノ星座タップで凸シミュ（再タップで戻す・長押しで効果）
- **3** 曜日素材に聖遺物秘境・週ボス（スケジュール + 週ボスは天賦コスト紐づけ）
- **4** `docs/DAILY_MATERIAL_SCHEDULE_REMOTE.md`（`DAILY_MATERIAL_SCHEDULE_URL`）
- **5** 突破 `contentHash` + 同期時の stale 再取得（最大15件）
- **6** `assets/config/level_exp_table.json` を正本に
- **7** リモート設定の `config_validators` + `tool/validate_config_json.dart`
- **8** 本番 applicationId — **後回し**（未公開）
- **9** SQLCipher は `ENABLE_SQLCIPHER` オプトイン（既定オフ）`docs/DB_ENCRYPTION.md`
- **10** auto-commit: 除外強化・touched files・件数上限・秘密スキャン
- **11–13** Team / Damage / Cloud — プラン確定後

## 2026-07-11 — マスタ同期の自動更新対応

- **現状解析**: Amber 一覧は毎回 upsert。突破は **未取得 ID のみ**（`fullUpgrade` は未配線だった）。起動同期は初回のみ。曜日スケジュールは asset 固定。
- **改善**:
  - `MasterContentProbe` — Amber 一覧件数 vs ローカル件数で新コンテンツ検知
  - 起動時: `shouldAutoSyncOnLaunch`（未同期/突破不足）またはプローブ `shouldSync` で自動同期
  - 設定: 「完全再同期」で `fullUpgrade: true`（突破全件再取得）
  - `getLastSyncTime` は `success` + `partial` を対象
  - 曜日スケジュール: `DAILY_MATERIAL_SCHEDULE_URL`（dart-define）でリモート JSON。`version` がローカル以上なら採用
- **残課題（手動/将来）**: 新天賦本シリーズの JSON 追記（リモート未設定時）。既存突破の全件差分は contentHash サンプル再取得 + 完全再同期でカバー
- **恒久ルール**: 機能追加時は Sync 連携必須（`.cursor/rules/genshin-master-sync-extensibility.mdc` + `AGENTS.md` §8）

## 2026-07-11 — 拡張アーキテクチャ P0–P3

- **P0**: `application/characters`（State + Load/Save/ApplyHoyolab UseCase）。Notifier は UseCase 呼び出しに薄型化
- **P1**: `domain/repositories` 契約 + `DriftCharacterRepository` / `DriftProgressRepository`。features の master/display/weights は domain 参照へ
- **P2**: `domain/team` · `domain/damage` · `domain/meta` + Akasha→`MetaRankingSource` アダプタ
- **P3**: `UserAccount` + `CloudSyncPort` + `LocalOnlyCloudSync`（`cloudSyncPortProvider`）
- **docs**: AGENTS 層依存ルール、ARCHITECTURE 図更新

## 2026-07-11 — セキュリティ Phase 0–1

- **Release**: minify/shrink + ProGuard、`key.properties` 任意署名、`allowBackup=false` + data extraction 除外
- **HoYoLAB**: 全 HTTP に 25s timeout。cookie は `verifyLToken` + ロール取得成功後のみ SecureStorage へ
- **エラー**: `core/errors/user_facing_error.dart` でユーザー文言と debug ログを分離。生 `$e` 表示を除去
- **CI**: mobile CI に簡易 secret ガード、release 例に `--obfuscate --split-debug-info`
- **未実施（次段階）**: applicationId 本番化。SQLCipher を本番常時 ON にする場合のネイティブ衝突確認・平文→暗号マイグレーション
- **起用**: プロジェクト Skill `.cursor/skills/genshin-security-checklist/`
- **自動読込**: `.cursor/rules/genshin-security-checklist.mdc`（alwaysApply）。Read 前に「genshin-security-checklist を読みます」と宣言

## 2026-07-11 — アーキテクチャ改善（段階実装）

- **Phase 0**: `genshin-mobile-ci.yml`（analyze + test）。ARCHITECTURE/AGENTS を Drift・MethodChannel 実態に更新
- **Phase 1**: `Master*` / `ArtifactStatWeights` を `domain/` へ。`OwnedCharacterSortInfo` で一覧ソートから HoYoLAB DTO 分離。Amber 詳細 DTO を `domain/models/amber_detail_models.dart`。Resolver / relic sync は data 層へ
- **Phase 2**: UI Amber 型は domain models。`CharacterDetailTabViews` で詳細タブ分割（screen ~672LOC）。曜日 UI を `features/daily_materials/widgets/` へ
- **Phase 3**: `ProgressRepository` in-memory Drift テスト。`AppDatabase.openInMemory`
- **Phase 4**: Amber JSON デコードを `Isolate.run`（32KB超）。ホーム prefetch は `ref.listen`
- **Phase 5**: `game_record` を props/owned/build/adventure に分割（barrel 維持）。golden に `snapTalentLevel` + `clampInt.below-min`
- **Phase 6（完了）**:
  - `characterDetailProvider`（`AutoDisposeNotifier`）で詳細画面の状態・debounce 保存を分離
  - Amber マスタ一覧パースを `amber_master_parsers.dart` + `Isolate.run`（characters/weapons/materials）
  - golden に `artifactMainStatValue` / `inferScoreType` / `calcPieceScore`（Web・Mobile 同一ケース）

## 2026-07-10 — 曜日別育成素材管理

- **画面**: `/daily` + ボトムナビ「曜日」。ホームにショートカット。初期タブは JST 4:00 リセット考慮の今日
- **スケジュール正本**: `assets/config/daily_material_schedule.json`（天賦本・武器突破シリーズ × 曜日）。新シリーズは JSON 追記のみ
- **不足数**: 既存 `getRangeTalentRequirements` / `getRangeLevelRequirements`。キャラ/武器紐づけは upgrade の `costItems` から自動（ハードコード一覧なし）
- **進捗**: `ProgressDao.getAllProgress` 追加。対象は保存済み `UserProgress`（天賦→10 / 武器→90）
- **起動時 prefetch**: ホームで `dailyProgressPrefetchProvider`。今日の天賦素材を使う**所持キャラ**だけ `getOrCreate` + HoYoLAB 詳細同期（並列3）。未連携時はスキップ。完了後 `dailyMaterialsPlanProvider` を invalidate
- **層**: domain planner（純関数） / data schedule+service / features UI。将来: 聖遺物秘境・週ボスは `DailyMaterialKind` 拡張

## 2026-07-10 — キャラ詳細シミュレーション機能

- **ステータス計算**: `domain/character_stats.dart`（Web `stats.ts` 移植・純Dart）。基礎×曲線＋突破＋武器＋聖遺物。セット効果・武器パッシブは対象外
- **曲線/スキル詳細**: `data/amber/amber_detail_repository.dart` — `/static/avatarCurve|weaponCurve` + avatar/weapon detail をメモリキャッシュ。失敗時 null → UI フォールバック
- **取得/シミュ分離**: `CharacterBuildSnapshot` に取得情報を保持。「取得情報に戻す」（AppBar + 想定タブ）で復元。編集状態は従来通り Drift 保存
- **UI**: 「想定」タブ（天賦↔HoYoLAB間）で現在/想定/差分表示。聖遺物タブ上部にスコア合計カード（基準選択は最下部へ移動）。天賦タブにスキル詳細（説明+レベル別倍率/CT）。武器変更時に差分確認ダイアログ
- **7–11**: 武器種フィルタ（`allowedWeaponType`）。武器/聖遺物は長押しで詳細シート。レベルタブに基礎ステ・突破ステ・次の段階素材（突破素材セクションは廃止し次の段階へ統合）。Lv90でもスライダーでシミュレーション可
- **12**: 武器選択はボトムシート一覧。行タップ=変更、ⓘ=`showWeaponDetailSheet`（変更しない）。共通行 UI は `SelectableDetailListTile`（聖遺物選択にも流用可）
- **14**: ヘッダーに命ノ星座 6 アイコン（`ConstellationIconsRow`）。取得済みは元素色。タップで Amber 凸効果。表示凸数 `_constellation` は取得データと分離（将来シミュ用）。`AvatarDetailData.constellations` を Amber からパース
- **武器並び替え**: `weapon_list_sort.dart` + 選択シート上部ドロップダウン（人気順・使用率 / レア度 / 基礎ATK）。人気順は Akasha `GET /api/builds?filter=[characterId]…&sort=_id` を最大 200 件集計（失敗時はローカル推定）。シート表示中のみ保持。フィルター用 `WeaponListFilter` を先行定義
- **テスト**: `test/domain/character_stats_test.dart` / `weapon_list_sort_test.dart`
- **次回**: 想定ステータスにセット効果を加算する場合は Amber reliquary セット効果テキストの取得が必要（詳細シートでは取得済み）

## 2026-07-10 — Domain Golden パリティ

- **正本**: `../shared/domain-golden/cases.json`
- **テスト**: `test/domain/domain_golden_test.dart`（Web Vitest と同一ケース）
- **CI**: `.github/workflows/genshin-domain-golden.yml`
- **方針**: 片側だけ失敗したら実装を直す。golden を安易に変更しない

## 2026-07-08 — 全体最適化（構成見直し）

- **進捗保存**: キャラ詳細スライダー変更を 800ms debounce で `user_progress` 永続化
- **DB**: `upgrade_serde.dart` 共有、マスタ同期を batch upsert に変更
- **Repository**: `progress_repository.dart` を分離、`materialsMapProvider` 追加
- **HoYoLAB**: dailyNote エラーを `HoyolabApiException.userMessage` で表示
- **Web**: `formatMora` / `isMaterialBookmarked` 重複除去、ARCHITECTURE ブックマーク追記

## 2026-07-08 — Phase 2 HoYoLAB 連携実装

- **API**: `hoyolab_api.dart` — dailyNote / verifyLToken / getUserGameRoles + `ApiRequestQueue` 500ms
- **認証**: DS 署名（`hoyolab_auth.dart`）、Cookie は `flutter_secure_storage` のみ
- **UI**: WebView ログイン、設定（連携/解除/UID選択）、ホーム `DailyNoteCard`
- **機能フラグ**: `app_settings.hoyolab_link_enabled`（Remote Config 相当）
- **Cookie 取得**: `webview_flutter` の `WebViewCookieManager`（Pigeon は未使用）

## 2026-07-08 — Phase 1 着手（bookmark_utils + Drift 土台）

- **P1-1 完了**: `domain/bookmark_utils.dart` — Web `bookmark-utils.ts` 準拠の sourceKey / エントリ生成
- **P1-0 着手**: `lib/data/db/drift/` に tables / daos / AppDatabase 定義。現行は sqflite 継続（`sqflite_database.dart`）
- **app_settings** 追加（v2 migration）— `localUserId` を DB 永続化（毎回 UUID 生成バグ修正）
- **次ステップ**: `flutter pub get && dart run build_runner build` → Drift 切替、UI パネル分割（P1-4）


- **Phase 1**: Drift DB + Web 同等の育成 UI / ブックマーク（sqflite scaffold から移行）
- **Phase 2**: HoYoLAB（WebView + Pigeon Cookie + secure storage + dailyNote）— 設計 + 骨組み
- **参考**: genshin_material の HoYoLAB 部分は MIT 尊重の上、概念参考のみで自前実装
- **ARCHITECTURE.md** を Phase 分け・UI 移植マップ・HoYoLAB シーケンス図付きで更新

## 2026-07-08 — 初回 scaffold

- **方針**: Web 版計算ロジックを `lib/domain/` に移植。UI は Flutter ネイティブ新規。
- **DB**: Phase 1 は `sqflite`（Drift は genshin_material 参考として Phase 1.5 移行候補）。
- **データ源**: Project Amber (`gi.yatta.moe`) — Web と同一。
- **HoYoLAB**: Phase 2 のみ。Cookie 非実装。
- **Flutter SDK**: 開発環境に未インストールのため、`flutter create .` は README 手順に記載。
- **匿名 userId**: Web と同様ローカル UUID（`user_progress.user_id`）。
