# Domain Golden（Web ↔ Mobile パリティ）

Web（TypeScript）と Mobile（Dart）が **同一の計算結果** を返すことを保証するための golden テストです。

## ファイル

| パス | 役割 |
|------|------|
| `cases.json` | 入力と期待値（両側のテストが読む） |

## 実行

```bash
# Web
cd genshin-builder-app
npm test -- src/lib/__tests__/domain-golden.test.ts

# Mobile
cd genshin-builder-mobile
flutter test test/domain/domain_golden_test.dart
```

## ケース追加手順

1. `cases.json` に `input` / `expected` を追加する
2. Web・Mobile の両方でテストを実行し、どちらも緑になることを確認する
3. 片側だけ失敗する場合は、その側のドメイン実装のズレを修正する（golden を安易に合わせない）

## ルール

- 期待値は **両実装が一致した確定値** のみ入れる
- 並び順に依存しない比較（`linesByMaterialId` など）を優先する
- 外部 API / DB に依存するケースは入れない（純関数のみ）
