/**
 * レベル・突破・必要素材の計算ロジック
 * 突破・天賦・EXP素材は DB 同期データ（UpgradeDataCache）を優先する
 */

import type { UpgradeDataCache } from "@/lib/repository/upgrade-data";
import {
  CHARACTER_EXP_BETWEEN_MARKS,
  EXP_BOOKS,
  LEVEL_MARKS,
  LEVEL_MAX,
  type LevelMark,
} from "./level-config";
import { getWeaponExpBetweenMarks } from "./weapon-exp";

/** 突破1段階分（API promote から正規化） */
export interface PromoteStage {
  promoteLevel: number;
  unlockMaxLevel: number;
  costItems: Record<string, number>;
  coinCost: number;
  requiredPlayerLevel?: number;
}

export interface MaterialCost {
  materialId: string;
  count: number;
}

export interface ExpBookSuggestion {
  materialId: string;
  name: string;
  count: number;
}

export interface EnhancementOreSuggestion {
  materialId: string;
  name: string;
  count: number;
}

/** レベルアップ素材（キャラ=経験値書 / 武器=魔鉱） */
export type LevelUpMaterialSuggestion =
  | ExpBookSuggestion
  | EnhancementOreSuggestion;

/** 次の育成段階までに必要な素材 */
export interface NextStageRequirements {
  fromLevel: number;
  toLevel: number;
  needsAscension: boolean;
  materials: MaterialCost[];
  mora: number;
  expTotal: number;
  levelUpMaterials: LevelUpMaterialSuggestion[];
  /** @deprecated levelUpMaterials を使用 */
  expBooks: ExpBookSuggestion[];
}

/** 突破段階ごとの表示情報 */
export interface AscensionStageInfo {
  level: number;
  promoteLevel: number;
  requiresAscension: boolean;
  materials: MaterialCost[];
  mora: number;
  requiredPlayerLevel?: number;
}

export function clampInt(value: unknown, min: number, max: number): number {
  const n = Math.round(Number(value));
  if (Number.isNaN(n)) return min;
  return Math.min(max, Math.max(min, n));
}

export function snapToLevelMark(value: unknown): LevelMark {
  return snapToMarks(value, LEVEL_MARKS, LEVEL_MAX) as LevelMark;
}

export function snapToMarks(
  value: unknown,
  marks: readonly number[],
  max: number,
): number {
  const min = marks[0] ?? 1;
  const n = clampInt(value, min, max);
  let closest = min;
  let minDiff = Infinity;
  for (const mark of marks) {
    if (mark > max) continue;
    const diff = Math.abs(n - mark);
    if (diff < minDiff) {
      minDiff = diff;
      closest = mark;
    }
  }
  return closest;
}

export function levelToVisualRatio(level: number, displayMax: number): number {
  return clampInt(level, 1, displayMax) / displayMax;
}

export function getNextMilestone(level: number): number | null {
  const snapped = snapToLevelMark(level);
  const idx = LEVEL_MARKS.indexOf(snapped);
  if (idx < 0 || idx >= LEVEL_MARKS.length - 1) return null;
  return LEVEL_MARKS[idx + 1];
}

export function getRequiredPromoteLevel(
  level: number,
  promotes: PromoteStage[],
): number {
  if (level <= 1) return 0;
  const sorted = [...promotes].sort(
    (a, b) => a.unlockMaxLevel - b.unlockMaxLevel,
  );
  for (const p of sorted) {
    if (p.unlockMaxLevel >= level) return p.promoteLevel;
  }
  return sorted.at(-1)?.promoteLevel ?? 0;
}

function mergeMaterials(
  target: Map<string, number>,
  items: Record<string, number>,
): void {
  for (const [id, count] of Object.entries(items)) {
    target.set(id, (target.get(id) ?? 0) + count);
  }
}

function resolveRarity(rarity: number): number {
  if (rarity >= 5) return 5;
  if (rarity === 4) return 4;
  return 3;
}

function getExpBetweenMarks(
  from: number,
  to: number,
  kind: "character" | "weapon",
  weaponRarity: number,
  cache?: UpgradeDataCache,
): number {
  const fromMark = snapToLevelMark(from);
  const toMark = snapToLevelMark(to);
  if (toMark <= fromMark) return 0;

  if (cache && cache.levelExpSegments.length > 0) {
    const rarity = kind === "character" ? 0 : resolveRarity(weaponRarity);
    let total = 0;
    const startIdx = LEVEL_MARKS.indexOf(fromMark);
    for (let i = startIdx; i < LEVEL_MARKS.length - 1; i++) {
      const a = LEVEL_MARKS[i];
      const b = LEVEL_MARKS[i + 1];
      if (b <= fromMark) continue;
      if (a >= toMark) break;
      const seg = cache.levelExpSegments.find(
        (s) =>
          s.targetType === kind &&
          s.rarity === rarity &&
          s.fromLevel === a &&
          s.toLevel === b,
      );
      total += seg?.expRequired ?? 0;
      if (b >= toMark) break;
    }
    if (total > 0) return total;
  }

  if (kind === "weapon") {
    return getWeaponExpBetweenMarks(fromMark, toMark, weaponRarity);
  }

  let total = 0;
  const startIdx = LEVEL_MARKS.indexOf(fromMark);
  for (let i = startIdx; i < LEVEL_MARKS.length - 1; i++) {
    const a = LEVEL_MARKS[i];
    const b = LEVEL_MARKS[i + 1];
    if (b <= fromMark) continue;
    if (a >= toMark) break;
    total += CHARACTER_EXP_BETWEEN_MARKS[`${a}-${b}`] ?? 0;
    if (b >= toMark) break;
  }
  return total;
}

interface LevelUpItem {
  materialId: string;
  name: string;
  exp: number;
}

function getLevelUpItems(
  kind: "character" | "weapon",
  cache?: UpgradeDataCache,
): LevelUpItem[] {
  const fromCache = (cache?.levelUpMaterials ?? [])
    .filter((m) => m.targetType === kind)
    .map((m) => ({
      materialId: m.materialId,
      name: m.name,
      exp: m.exp,
    }))
    .sort((a, b) => b.exp - a.exp);

  if (fromCache.length > 0) return fromCache;

  if (kind === "weapon") {
    return [
      { materialId: "104013", name: "仕上げ用魔鉱", exp: 10_000 },
      { materialId: "104012", name: "仕上げ用良鉱", exp: 2_000 },
      { materialId: "104011", name: "仕上げ用雑鉱", exp: 400 },
    ];
  }

  return EXP_BOOKS.map((b) => ({
    materialId: b.id,
    name: b.name,
    exp: b.exp,
  }));
}

export function suggestLevelUpMaterials(
  totalExp: number,
  kind: "character" | "weapon",
  cache?: UpgradeDataCache,
): LevelUpMaterialSuggestion[] {
  if (totalExp <= 0) return [];

  const items = getLevelUpItems(kind, cache);
  let remaining = totalExp;
  const result: LevelUpMaterialSuggestion[] = [];

  for (const item of items) {
    const count = Math.floor(remaining / item.exp);
    if (count > 0) {
      result.push({
        materialId: item.materialId,
        name: item.name,
        count,
      });
      remaining -= count * item.exp;
    }
  }

  if (remaining > 0) {
    const smallest = items.at(-1);
    if (smallest) {
      const extra = Math.ceil(remaining / smallest.exp);
      const existing = result.find((r) => r.materialId === smallest.materialId);
      if (existing) {
        existing.count += extra;
      } else {
        result.push({
          materialId: smallest.materialId,
          name: smallest.name,
          count: extra,
        });
      }
    }
  }

  return result;
}

/** @deprecated suggestLevelUpMaterials を使用 */
export function suggestExpBooks(totalExp: number): ExpBookSuggestion[] {
  return suggestLevelUpMaterials(totalExp, "character") as ExpBookSuggestion[];
}

export function getNextStageRequirements(
  currentLevel: number,
  promotes: PromoteStage[],
  kind: "character" | "weapon",
  weaponRarity = 5,
  cache?: UpgradeDataCache,
): NextStageRequirements | null {
  const fromLevel = snapToLevelMark(currentLevel);
  const toLevel = getNextMilestone(fromLevel);
  if (toLevel === null) return null;

  const currentPromote = getRequiredPromoteLevel(fromLevel, promotes);
  const targetPromote = getRequiredPromoteLevel(toLevel, promotes);
  const needsAscension = targetPromote > currentPromote;

  const materialMap = new Map<string, number>();
  let mora = 0;

  if (needsAscension) {
    for (let pl = currentPromote + 1; pl <= targetPromote; pl++) {
      const stage = promotes.find((p) => p.promoteLevel === pl);
      if (!stage) continue;
      mergeMaterials(materialMap, stage.costItems);
      mora += stage.coinCost;
    }
  }

  const expTotal = getExpBetweenMarks(
    fromLevel,
    toLevel,
    kind,
    weaponRarity,
    cache,
  );
  const levelUpMora = Math.round(expTotal / 10);
  const levelUpMaterials = suggestLevelUpMaterials(expTotal, kind, cache);

  return {
    fromLevel,
    toLevel,
    needsAscension,
    materials: [...materialMap.entries()].map(([materialId, count]) => ({
      materialId,
      count,
    })),
    mora: mora + levelUpMora,
    expTotal,
    levelUpMaterials,
    expBooks:
      kind === "character" ? (levelUpMaterials as ExpBookSuggestion[]) : [],
  };
}

export function getAscensionStageInfos(
  promotes: PromoteStage[],
): AscensionStageInfo[] {
  return promotes
    .filter((p) => p.promoteLevel > 0)
    .sort((a, b) => a.unlockMaxLevel - b.unlockMaxLevel)
    .map((p) => ({
      level: p.unlockMaxLevel,
      promoteLevel: p.promoteLevel,
      requiresAscension: true,
      materials: Object.entries(p.costItems).map(([materialId, count]) => ({
        materialId,
        count,
      })),
      mora: p.coinCost,
      requiredPlayerLevel: p.requiredPlayerLevel,
    }));
}

export function getAscensionForLevel(
  level: number,
  promotes: PromoteStage[],
): number {
  return getRequiredPromoteLevel(snapToLevelMark(level), promotes);
}
