# Daily Material Schedule — Remote JSON

曜日別天賦本・武器突破スケジュールのリモート配信。

## 1. 正本

- ローカル: `assets/config/daily_material_schedule.json`
- リモート: `--dart-define=DAILY_MATERIAL_SCHEDULE_URL=` で指定した HTTPS JSON
- 合成: `CompositeDailyMaterialScheduleSource` — リモートの `version` がローカル以上ならリモート採用。失敗時はローカルへフォールバック

## 2. バリデーション

リモート取得後、`fromJson` の前に `validateDailyMaterialScheduleJson` を実行する。
必須: `version`、非空の `talentSeries` / `weaponSeries`、各シリーズの `id`・`materialIds`・`days`（1–7）。
不正なら例外 → composite がローカルに戻る。

スキーマ参考: `assets/config/schemas/daily_material_schedule.schema.json`

ローカル検証:

```bash
dart run tool/validate_config_json.dart
```

## 3. JSON 最低構成

`assets/config/daily_material_schedule.json` と同型。`days` は ISO 曜日（1=月 … 7=日）。日曜はアプリ側で全シリーズ開放。

## 4. 有効化方法（remote）

```bash
flutter run --dart-define=DAILY_MATERIAL_SCHEDULE_URL=https://your-domain/path/daily_material_schedule.json
```

未指定時は local asset のみ。

本番ビルドでも remote を使う場合は、CI/CD のリリースコマンドに同じ `--dart-define` を入れる。

推奨チェック:

1. URL が 200 で JSON を返す
2. `version` がローカル以上
3. `dart run tool/validate_config_json.dart` 相当の形を満たす
4. アプリの曜日画面でシリーズが表示される

## 5. 聖遺物スコア重みとの対比

| dart-define | 用途 |
|-------------|------|
| `DAILY_MATERIAL_SCHEDULE_URL` | 曜日スケジュール |
| `ARTIFACT_SCORE_WEIGHTS_URL` | 聖遺物スコア重み（詳細は `ARTIFACT_SCORE_WEIGHT_OPERATIONS.md`） |
