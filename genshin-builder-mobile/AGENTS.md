# AGENTS.md — Genshin Builder Mobile

## プロジェクト

- **種別**: Flutter モバイルアプリ（非公式ファンツール）
- **参照 Web**: `../genshin-builder-app/`（育成 UI・計算仕様の正）
- **参考**: [genshin_material](https://github.com/chika3742/genshin_material)（HoYoLAB / Drift — **概念参考のみ、コード転載禁止**）

## Phase

| Phase | 内容 |
|-------|------|
| **1** | キャラ詳細 + 素材計算 + ブックマーク + Amber 同期 + **Drift** |
| **2** | HoYoLAB（WebView + Cookie MethodChannel/WebViewCookieManager + secure storage + dailyNote） |

詳細: `ARCHITECTURE.md`, `docs/PHASE1_IMPLEMENTATION.md`, `docs/PHASE2_HOYOLAB.md`

## 作業ルール

1. **既存 Web を変更しない**
2. **domain/ は純 Dart** — Flutter / Drift / http に依存しない。マスタ型は `domain/models/`、Amber 詳細 DTO は `domain/models/amber_detail_models.dart`
3. **計算・ブックマーク sourceKey は Web と一致**
4. **genshin_material は参考のみ** — DS 署名・API パターンを理解し自前実装
5. **Cookie は secure storage のみ**（Phase 2）
6. **README 非公式免責を維持**

## ディレクトリ

```
lib/
  domain/
    models/          # Master* / Amber detail DTOs / calc models
  data/
    db/              # Drift
    amber/
    sync/
    repositories/
    hoyolab/
    secure/
    artifact_score/  # Resolver 等（Repository 依存は data）
  platform/          # MethodChannel（Cookie フォールバック）
  features/
  providers/
```

## コマンド

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift / Pigeon
flutter analyze
flutter test
flutter run
```
