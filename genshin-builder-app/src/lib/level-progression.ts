/**
 * レベル・突破・必要素材の計算ロジック
 */

import {
  CHARACTER_EXP_BETWEEN_MARKS,
  EXP_BOOKS,
  LEVEL_MARKS,
  LEVEL_MAX,
  WEAPON_EXP_MULTIPLIER,
  type LevelMark,
} from "./level-config";

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

/** 次の育成段階までに必要な素材 */
export interface NextStageRequirements {
  fromLevel: number;
  toLevel: number;
  /** 突破が必要か */
  needsAscension: boolean;
  materials: MaterialCost[];
  mora: number;
  expTotal: number;
  expBooks: ExpBookSuggestion[];
}

/** 突破段階ごとの表示情報 */
export interface AscensionStageInfo {
  level: number;
  promoteLevel: number;
  /** この段階で突破が必要か（Lv.1 以外） */
  requiresAscension: boolean;
  materials: MaterialCost[];
  mora: number;
  requiredPlayerLevel?: number;
}

/** 整数を min〜max に収める */
export function clampInt(value: unknown, min: number, max: number): number {
  const n = Math.round(Number(value));
  if (Number.isNaN(n)) return min;
  return Math.min(max, Math.max(min, n));
}

/** レベルを最寄りの目盛りにスナップする */
export function snapToLevelMark(value: unknown): LevelMark {
  return snapToMarks(value, LEVEL_MARKS, LEVEL_MAX) as LevelMark;
}

/** 任意の目盛り配列にスナップする */
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

/** スライダー表示位置（0〜1）。LEVEL_DISPLAY_MAX 基準 */
export function levelToVisualRatio(level: number, displayMax: number): number {
  return clampInt(level, 1, displayMax) / displayMax;
}

/** 次の目盛りレベルを返す（最大時は null） */
export function getNextMilestone(level: number): number | null {
  const snapped = snapToLevelMark(level);
  const idx = LEVEL_MARKS.indexOf(snapped);
  if (idx < 0 || idx >= LEVEL_MARKS.length - 1) return null;
  return LEVEL_MARKS[idx + 1];
}

/** レベルに必要な突破段階（promoteLevel）を返す */
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

/** 素材リストをマージする */
function mergeMaterials(
  target: Map<string, number>,
  items: Record<string, number>,
): void {
  for (const [id, count] of Object.entries(items)) {
    target.set(id, (target.get(id) ?? 0) + count);
  }
}

/** 必要経験値を目盛り間で合算 */
function getExpBetweenMarks(
  from: number,
  to: number,
  kind: "character" | "weapon",
): number {
  const fromMark = snapToLevelMark(from);
  const toMark = snapToLevelMark(to);
  if (toMark <= fromMark) return 0;

  let total = 0;
  const startIdx = LEVEL_MARKS.indexOf(fromMark);
  for (let i = startIdx; i < LEVEL_MARKS.length - 1; i++) {
    const a = LEVEL_MARKS[i];
    const b = LEVEL_MARKS[i + 1];
    if (b <= fromMark) continue;
    if (a >= toMark) break;
    const key = `${a}-${b}`;
    const exp = CHARACTER_EXP_BETWEEN_MARKS[key] ?? 0;
    total += kind === "weapon" ? Math.round(exp * WEAPON_EXP_MULTIPLIER) : exp;
    if (b >= toMark) break;
  }
  return total;
}

/** 経験値書のおすすめ内訳（大→小の貪欲法） */
export function suggestExpBooks(totalExp: number): ExpBookSuggestion[] {
  if (totalExp <= 0) return [];
  let remaining = totalExp;
  const result: ExpBookSuggestion[] = [];

  for (const book of EXP_BOOKS) {
    const count = Math.floor(remaining / book.exp);
    if (count > 0) {
      result.push({ materialId: book.id, name: book.name, count });
      remaining -= count * book.exp;
    }
  }
  if (remaining > 0) {
    const wanderer = EXP_BOOKS[2];
    result.push({
      materialId: wanderer.id,
      name: wanderer.name,
      count: Math.ceil(remaining / wanderer.exp),
    });
  }
  return result;
}

/** 次の育成段階までに必要な素材を計算 */
export function getNextStageRequirements(
  currentLevel: number,
  promotes: PromoteStage[],
  kind: "character" | "weapon",
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

  const expTotal = getExpBetweenMarks(fromLevel, toLevel, kind);

  return {
    fromLevel,
    toLevel,
    needsAscension,
    materials: [...materialMap.entries()].map(([materialId, count]) => ({
      materialId,
      count,
    })),
    mora,
    expTotal,
    expBooks: suggestExpBooks(expTotal),
  };
}

/** 各突破段階の情報一覧 */
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

/** レベル変更時に同期する突破段階 */
export function getAscensionForLevel(
  level: number,
  promotes: PromoteStage[],
): number {
  return getRequiredPromoteLevel(snapToLevelMark(level), promotes);
}
