/**
 * 武器レベルアップ用の魔鉱・必要EXP
 *
 * Project Amber API は武器詳細の items に魔鉱 ID（104011〜104013）を返すが、
 * 目盛り間の必要EXPはAPI未提供のため、レアリティ別の定数表を使用する。
 * 定数はゲーム内実測値（5★/4★/3★）に基づく。
 */

import { LEVEL_MARKS } from "./level-config";

/** 仕上げ用雑鉱 / 良鉱 / 魔鉱（API material ID） */
export const WEAPON_ENHANCEMENT_ORES = [
  { id: "104013", name: "仕上げ用魔鉱", exp: 10_000 },
  { id: "104012", name: "仕上げ用良鉱", exp: 2_000 },
  { id: "104011", name: "仕上げ用雑鉱", exp: 400 },
] as const;

/** レアリティ別・目盛り間の必要武器EXP */
const WEAPON_EXP_BY_RARITY: Record<number, Record<string, number>> = {
  // 3★（1★2★も同表を流用）
  3: {
    "1-20": 53_475,
    "20-30": 127_978,
    "30-40": 145_247,
    "40-50": 275_350,
    "50-60": 408_650,
    "60-70": 572_725,
    "70-80": 772_825,
    "80-90": 1_638_650,
  },
  4: {
    "1-20": 81_000,
    "20-30": 194_512,
    "30-40": 220_613,
    "40-50": 418_725,
    "50-60": 618_400,
    "60-70": 866_675,
    "70-80": 1_168_350,
    "80-90": 2_476_475,
  },
  5: {
    "1-20": 121_550,
    "20-30": 291_591,
    "30-40": 331_209,
    "40-50": 628_150,
    "50-60": 927_675,
    "60-70": 1_299_125,
    "70-80": 1_750_375,
    "80-90": 3_714_775,
  },
};

export interface EnhancementOreSuggestion {
  materialId: string;
  name: string;
  count: number;
}

function resolveRarityTable(rarity: number): Record<string, number> {
  if (rarity >= 5) return WEAPON_EXP_BY_RARITY[5];
  if (rarity === 4) return WEAPON_EXP_BY_RARITY[4];
  return WEAPON_EXP_BY_RARITY[3];
}

/** 目盛り間の必要武器EXPを合算 */
export function getWeaponExpBetweenMarks(
  from: number,
  to: number,
  rarity: number,
): number {
  const table = resolveRarityTable(rarity);
  const fromMark = snapMark(from);
  const toMark = snapMark(to);
  if (toMark <= fromMark) return 0;

  let total = 0;
  const startIdx = LEVEL_MARKS.indexOf(fromMark as (typeof LEVEL_MARKS)[number]);
  for (let i = Math.max(0, startIdx); i < LEVEL_MARKS.length - 1; i++) {
    const a = LEVEL_MARKS[i];
    const b = LEVEL_MARKS[i + 1];
    if (b <= fromMark) continue;
    if (a >= toMark) break;
    total += table[`${a}-${b}`] ?? 0;
    if (b >= toMark) break;
  }
  return total;
}

/** 武器レベルアップに必要なモラ（EXPの10%） */
export function getWeaponLevelUpMora(expTotal: number): number {
  return Math.round(expTotal / 10);
}

/** 魔鉱のおすすめ内訳（大→小の貪欲法） */
export function suggestWeaponOres(totalExp: number): EnhancementOreSuggestion[] {
  if (totalExp <= 0) return [];
  let remaining = totalExp;
  const result: EnhancementOreSuggestion[] = [];

  for (const ore of WEAPON_ENHANCEMENT_ORES) {
    const count = Math.floor(remaining / ore.exp);
    if (count > 0) {
      result.push({ materialId: ore.id, name: ore.name, count });
      remaining -= count * ore.exp;
    }
  }
  if (remaining > 0) {
    const fine = WEAPON_ENHANCEMENT_ORES[2];
    const extra = Math.ceil(remaining / fine.exp);
    const existing = result.find((r) => r.materialId === fine.id);
    if (existing) {
      existing.count += extra;
    } else {
      result.push({
        materialId: fine.id,
        name: fine.name,
        count: extra,
      });
    }
  }
  return result;
}

function snapMark(level: number): number {
  let closest: number = LEVEL_MARKS[0];
  let minDiff = Math.abs(level - closest);
  for (const mark of LEVEL_MARKS) {
    const diff = Math.abs(level - mark);
    if (diff < minDiff) {
      minDiff = diff;
      closest = mark;
    }
  }
  return closest;
}

/** API items から魔鉱IDを抽出（104011〜104013） */
export function parseWeaponEnhancementOreIds(
  items: Record<string, unknown> | undefined,
): string[] {
  if (!items) return WEAPON_ENHANCEMENT_ORES.map((o) => o.id);
  return WEAPON_ENHANCEMENT_ORES.filter((o) => items[o.id] != null).map(
    (o) => o.id,
  );
}
