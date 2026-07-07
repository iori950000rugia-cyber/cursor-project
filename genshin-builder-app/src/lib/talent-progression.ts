/**
 * 天賦（スキル）レベルの計算ロジック
 */

import {
  TALENT_LEVEL_MAX,
  TALENT_MARKS,
} from "./level-config";
import { clampInt } from "./level-progression";

export interface TalentLevelUpgrade {
  level: number;
  costItems: Record<string, number>;
  coinCost: number;
}

export interface MaterialCost {
  materialId: string;
  count: number;
}

/** 次の天賦レベルに必要な素材 */
export interface NextTalentRequirements {
  fromLevel: number;
  toLevel: number;
  materials: MaterialCost[];
  mora: number;
}

/** 天賦レベルを目盛り（1刻み）にスナップ */
export function snapTalentLevel(
  value: unknown,
  max: number = TALENT_LEVEL_MAX,
): number {
  const n = clampInt(value, 1, max);
  let closest: number = TALENT_MARKS[0];
  let minDiff = Math.abs(n - closest);
  for (const mark of TALENT_MARKS) {
    if (mark > max) break;
    const diff = Math.abs(n - mark);
    if (diff < minDiff) {
      minDiff = diff;
      closest = mark;
    }
  }
  return closest;
}

/** 指定レベルへの強化データを取得 */
export function getTalentUpgradeAtLevel(
  level: number,
  upgrades: TalentLevelUpgrade[],
): TalentLevelUpgrade | null {
  return upgrades.find((u) => u.level === level) ?? null;
}

/** 次の天賦レベルに必要な素材を計算 */
export function getNextTalentRequirements(
  currentLevel: number,
  max: number,
  upgrades: TalentLevelUpgrade[],
): NextTalentRequirements | null {
  const fromLevel = snapTalentLevel(currentLevel, max);
  if (fromLevel >= max) return null;

  const toLevel = fromLevel + 1;
  const upgrade = getTalentUpgradeAtLevel(toLevel, upgrades);
  const costItems = upgrade?.costItems ?? {};

  return {
    fromLevel,
    toLevel,
    materials: Object.entries(costItems).map(([materialId, count]) => ({
      materialId,
      count,
    })),
    mora: upgrade?.coinCost ?? 0,
  };
}

/** 各レベル強化の一覧（Lv.2〜） */
export function getTalentUpgradeInfos(
  upgrades: TalentLevelUpgrade[],
): Array<{
  level: number;
  materials: MaterialCost[];
  mora: number;
}> {
  return upgrades
    .filter((u) => u.level > 1 && Object.keys(u.costItems).length > 0)
    .sort((a, b) => a.level - b.level)
    .map((u) => ({
      level: u.level,
      materials: Object.entries(u.costItems).map(([materialId, count]) => ({
        materialId,
        count,
      })),
      mora: u.coinCost,
    }));
}
