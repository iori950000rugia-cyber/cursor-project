/**
 * 育成範囲（開始〜終了レベル）の必要素材を合算する
 */

import type { UpgradeDataCache } from "@/lib/repository/upgrade-data";
import type { RequirementLine } from "@/types/bookmark";
import { MORA_MATERIAL_ID } from "@/types/bookmark";
import {
  getNextStageRequirements,
  snapToLevelMark,
  type PromoteStage,
} from "./level-progression";
import {
  getTalentUpgradeAtLevel,
  snapTalentLevel,
  type TalentLevelUpgrade,
} from "./talent-progression";

function mergeRequirementLines(lines: RequirementLine[]): RequirementLine[] {
  const map = new Map<string, RequirementLine>();

  for (const line of lines) {
    const existing = map.get(line.materialId);
    if (existing) {
      existing.count += line.count;
    } else {
      map.set(line.materialId, { ...line });
    }
  }

  return [...map.values()].sort((a, b) => {
    if (a.isMora) return 1;
    if (b.isMora) return -1;
    return a.name.localeCompare(b.name, "ja");
  });
}

/** キャラ/武器: fromLevel → toLevel の必要素材を合算 */
export function getRangeLevelRequirements(
  fromLevel: number,
  toLevel: number,
  promotes: PromoteStage[],
  kind: "character" | "weapon",
  weaponRarity = 5,
  cache?: UpgradeDataCache,
  resolveName?: (materialId: string) => string,
): RequirementLine[] {
  const from = snapToLevelMark(fromLevel);
  const to = snapToLevelMark(toLevel);
  if (to <= from) return [];

  const materialMap = new Map<string, number>();
  const levelUpMap = new Map<string, { name: string; count: number }>();
  let mora = 0;

  let current: number = from;
  while (current < to) {
    const stage = getNextStageRequirements(
      current,
      promotes,
      kind,
      weaponRarity,
      cache,
    );
    if (!stage || stage.toLevel > to) break;

    for (const { materialId, count } of stage.materials) {
      materialMap.set(materialId, (materialMap.get(materialId) ?? 0) + count);
    }
    for (const item of stage.levelUpMaterials) {
      const prev = levelUpMap.get(item.materialId);
      if (prev) {
        prev.count += item.count;
      } else {
        levelUpMap.set(item.materialId, {
          name: item.name,
          count: item.count,
        });
      }
    }
    mora += stage.mora;
    current = stage.toLevel;
  }

  const lines: RequirementLine[] = [];

  for (const [materialId, count] of materialMap) {
    lines.push({
      materialId,
      name: resolveName?.(materialId) ?? `素材 #${materialId}`,
      count,
    });
  }
  for (const [materialId, { name, count }] of levelUpMap) {
    lines.push({
      materialId,
      name: resolveName?.(materialId) ?? name,
      count,
    });
  }
  if (mora > 0) {
    lines.push({
      materialId: MORA_MATERIAL_ID,
      name: "モラ",
      count: mora,
      isMora: true,
    });
  }

  return mergeRequirementLines(lines);
}

/** 天賦: fromLevel → toLevel の必要素材を合算 */
export function getRangeTalentRequirements(
  fromLevel: number,
  toLevel: number,
  max: number,
  upgrades: TalentLevelUpgrade[],
  resolveName?: (materialId: string) => string,
): RequirementLine[] {
  const from = snapTalentLevel(fromLevel, max);
  const to = snapTalentLevel(toLevel, max);
  if (to <= from) return [];

  const materialMap = new Map<string, number>();
  let mora = 0;

  for (let level = from + 1; level <= to; level++) {
    const upgrade = getTalentUpgradeAtLevel(level, upgrades);
    if (!upgrade) continue;
    for (const [materialId, count] of Object.entries(upgrade.costItems)) {
      materialMap.set(materialId, (materialMap.get(materialId) ?? 0) + count);
    }
    mora += upgrade.coinCost;
  }

  const lines: RequirementLine[] = [];
  for (const [materialId, count] of materialMap) {
    lines.push({
      materialId,
      name: resolveName?.(materialId) ?? `素材 #${materialId}`,
      count,
    });
  }
  if (mora > 0) {
    lines.push({
      materialId: MORA_MATERIAL_ID,
      name: "モラ",
      count: mora,
      isMora: true,
    });
  }

  return mergeRequirementLines(lines);
}

/** 次の1段階分を RequirementLine[] に変換 */
export function nextStageToRequirementLines(
  materials: Array<{ materialId: string; count: number }>,
  levelUpMaterials: Array<{ materialId: string; name: string; count: number }>,
  mora: number,
  resolveName: (materialId: string) => string,
  resolveIcon?: (materialId: string) => string | null,
): RequirementLine[] {
  const lines: RequirementLine[] = [];

  for (const { materialId, count } of materials) {
    lines.push({
      materialId,
      name: resolveName(materialId),
      count,
      iconUrl: resolveIcon?.(materialId) ?? null,
    });
  }
  for (const { materialId, name, count } of levelUpMaterials) {
    lines.push({
      materialId,
      name: resolveName(materialId) || name,
      count,
      iconUrl: resolveIcon?.(materialId) ?? null,
    });
  }
  if (mora > 0) {
    lines.push({
      materialId: MORA_MATERIAL_ID,
      name: "モラ",
      count: mora,
      isMora: true,
      iconUrl: null,
    });
  }

  return lines;
}
