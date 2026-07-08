# Phase 1 実装計画 — 育成 UI + 素材計算 + ブックマーク（Drift）

Web 版 `genshin-builder-app/` を仕様の正とする。

## ゴール

- キャラ詳細で Lv / 天賦 / 武器を操作し、**次段階**・**目標範囲**の必要素材を表示
- 素材をブックマークし、ホーム / 一覧で **materialId 合算 + キャラアイコン** 表示
- Project Amber からマスタ同期、**Drift** に永続化

## 優先順位

| 順 | タスク | 成果物 |
|----|--------|--------|
| **P1-0** | sqflite → **Drift 移行** | `lib/data/db/drift/*` 定義済み。codegen + 切替待ち |
| **P1-1** | ドメイン完成度（sourceKey ユーティリティ） | `domain/bookmark_utils.dart` ✅ |
| **P1-2** | Repository を Drift DAO 経由に | `character/bookmark/progress_repository` |
| **P1-3** | Amber 同期強化 | `master_sync_service`（upgrade 全件 or バッチ） |
| **P1-4** | キャラ詳細 UI 分割 | `LevelMaterialsPanel`, `TalentSection`, `WeaponSection` |
| **P1-5** | ブックマーク UX | 範囲ダイアログ、個別トグル、ホームサイドバー相当 |
| **P1-6** | 育成進捗の保存 | スライダー debounce → `user_progress` |
| **P1-7** | テスト | domain 数値一致 + Drift repository |

## ファイル一覧（新規 / 変更）

### Drift

| ファイル | 内容 |
|----------|------|
| `lib/data/db/app_database.dart` | `@DriftDatabase` 定義 |
| `lib/data/db/tables/master_tables.dart` | characters, weapons, materials, upgrades |
| `lib/data/db/tables/user_tables.dart` | user_progress, material_bookmarks, sync_logs, app_settings |
| `lib/data/db/daos/character_dao.dart` | マスタ CRUD |
| `lib/data/db/daos/bookmark_dao.dart` | ブックマーク CRUD + 合算クエリ |
| `lib/data/db/daos/progress_dao.dart` | 育成進捗 |
| `build.yaml` | drift 設定 |

**削除予定**: 現 `lib/data/db/app_database.dart`（sqflite 版）

### ドメイン

| Flutter | Web |
|---------|-----|
| `lib/domain/bookmark_utils.dart` | `bookmark-utils.ts` |
| 既存 `level_*`, `material_*`, `weapon_exp` | そのまま維持・テスト追加 |

### Features（UI）

| ファイル | Web 参照 |
|----------|----------|
| `features/characters/widgets/level_materials_panel.dart` | `LevelMaterialsPanel.tsx` |
| `features/characters/widgets/talent_section.dart` | `TalentSection.tsx` |
| `features/characters/widgets/weapon_section.dart` | `WeaponSection.tsx` |
| `features/characters/widgets/bookmark_range_dialog.dart` | 範囲ブックマーク UI |
| `features/bookmarks/widgets/aggregated_bookmark_list.dart` | `BookmarkMaterialsSidebar.tsx` |
| `features/shared/cultivation_bookmark_button.dart` | `CultivationBookmarkButton.tsx` |

### 既存から改修

| ファイル | 変更内容 |
|----------|----------|
| `character_detail_screen.dart` | パネル分割・Web 同等 UX |
| `home_screen.dart` | 合算ブックマーク + キャラアバター |
| `providers/app_providers.dart` | Drift Database プロバイダ |
| `pubspec.yaml` | drift 追加、sqflite 削除 |

## 受け入れ条件

- [ ] `flutter test test/domain/` 全 pass
- [ ] Lv 1→90 範囲のモラ合算が Web と一致（同一 promotes 入力時）
- [ ] ブックマーク sourceKey が Web 形式
- [ ] オフライン時も Drift キャッシュでキャラ一覧・詳細が開ける
- [ ] README 非公式免責あり

## Phase 1 スコープ外

- HoYoLAB（Phase 2）
- 聖遺物スコア・自動ステ計算（Web `ArtifactSection` は Phase 1 後半 or Phase 3）
