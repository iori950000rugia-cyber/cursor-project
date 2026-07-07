/**
 * レベル・突破のマスター設定
 *
 * 将来レベル上限や目盛りが変わっても、ここ（または同期マスタ）を更新するだけで
 * UI側のロジックを変えずに対応できるようにする。
 */

/** スライダーの目盛り（スナップ先） */
export const LEVEL_MARKS = [1, 20, 30, 40, 50, 60, 70, 80, 90] as const;

export type LevelMark = (typeof LEVEL_MARKS)[number];

/** 現在プレイ可能な最大レベル */
export const LEVEL_MAX = 90;

/** スライダー表示上の最大レベル（将来拡張用の余白） */
export const LEVEL_DISPLAY_MAX = 100;

/** 突破が発生する目盛り（Lv.1 除く） */
export const ASCENSION_MARKS = LEVEL_MARKS.filter((m) => m > 1);

/** 経験値書（将来マスターデータ化） */
export const EXP_BOOKS = [
  { id: "104003", name: "大英雄の経験", exp: 20_000 },
  { id: "104002", name: "冒険家の経験", exp: 5_000 },
  { id: "104001", name: "流浪者の経験", exp: 1_000 },
] as const;

/**
 * 目盛り間の必要経験値（キャラクター共通）
 * キー: "from-to" 例 "20-30"
 * 将来 API から取得する場合はこの定数を差し替える。
 */
export const CHARACTER_EXP_BETWEEN_MARKS: Record<string, number> = {
  "1-20": 12_275,
  "20-30": 57_900,
  "30-40": 65_700,
  "40-50": 39_300,
  "50-60": 94_800,
  "60-70": 114_300,
  "70-80": 280_800,
  "80-90": 393_750,
};

/** 武器はキャラの約 1.5 倍（目安。将来マスターデータ化） */
export const WEAPON_EXP_MULTIPLIER = 1.5;

/** @deprecated 武器は weapon-exp.ts の魔鉱計算を使用 */

/** 天賦レベル（スキル） */
export const TALENT_LEVEL_MAX = 10;

/** 天賦スライダー表示上の最大（命ノ星座+3 用の余白） */
export const TALENT_LEVEL_DISPLAY_MAX = 13;

/** 天賦の目盛り（1刻み） */
export const TALENT_MARKS = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10] as const;

/** 将来対応の天賦レベル（凸+3） */
export const TALENT_FUTURE_MARKS = [11, 12, 13] as const;
