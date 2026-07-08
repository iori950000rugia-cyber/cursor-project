# AGENTS.md — Genshin Builder Mobile

## プロジェクト

- **種別**: Flutter モバイルアプリ（非公式ファンツール）
- **参照 Web**: `../genshin-builder-app/`（育成 UI・計算仕様の正）
- **参考**: [genshin_material](https://github.com/chika3742/genshin_material)（HoYoLAB / Drift — **概念参考のみ、コード転載禁止**）

## Phase

| Phase | 内容 |
|-------|------|
| **1** | キャラ詳細 + 素材計算 + ブックマーク + Amber 同期 + **Drift** |
| **2** | HoYoLAB（WebView + Pigeon Cookie + secure storage + dailyNote）— 設計 + 骨組み |

詳細: `ARCHITECTURE.md`, `docs/PHASE1_IMPLEMENTATION.md`, `docs/PHASE2_HOYOLAB.md`

## 作業ルール

1. **既存 Web を変更しない**
2. **domain/ は純 Dart** — Flutter / Drift / http に依存しない
3. **計算・ブックマーク sourceKey は Web と一致**
4. **genshin_material は参考のみ** — DS 署名・API パターンを理解し自前実装
5. **Cookie は secure storage のみ**（Phase 2）
6. **README 非公式免責を維持**

## ディレクトリ

```
lib/
  domain/
  data/
    db/          Drift（Phase 1）
    amber/
    sync/
    hoyolab/     Phase 2 骨組み
    secure/      Phase 2 骨組み
    repositories/
  platform/pigeon/   Phase 2
  features/
  providers/
pigeon/          Pigeon 入力定義
```

## コマンド

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # Drift / Pigeon
flutter analyze
flutter test
flutter run
```
