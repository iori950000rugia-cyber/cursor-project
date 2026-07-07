/**
 * 育成素材・突破データのDB読み取り層
 */

import { prisma } from "@/lib/db";
import type {
  CharacterUpgradeData,
  LevelExpSegmentData,
  LevelUpMaterialData,
  PromoteStageData,
  TalentUpgradeData,
  WeaponUpgradeData,
} from "@/lib/api/upgrade-types";

export interface UpgradeDataCache {
  levelExpSegments: LevelExpSegmentData[];
  levelUpMaterials: LevelUpMaterialData[];
}

function parseJson<T>(raw: string, fallback: T): T {
  try {
    return JSON.parse(raw) as T;
  } catch {
    return fallback;
  }
}

/** キャラクター突破・天賦データを取得 */
export async function getCharacterUpgrade(
  characterId: string,
): Promise<CharacterUpgradeData | null> {
  try {
    const row = await prisma.characterUpgrade.findUnique({
      where: { characterId },
    });
    if (!row) return null;
    return {
      characterId,
      promotes: parseJson<PromoteStageData[]>(row.promotes, []),
      talents: parseJson<TalentUpgradeData[]>(row.talents, []),
    };
  } catch (error) {
    console.error("CharacterUpgrade DB取得失敗:", error);
    return null;
  }
}

/** 武器突破データを取得 */
export async function getWeaponUpgrade(
  weaponId: string,
): Promise<WeaponUpgradeData | null> {
  try {
    const row = await prisma.weaponUpgrade.findUnique({
      where: { weaponId },
    });
    if (!row) return null;
    return {
      weaponId,
      promotes: parseJson<PromoteStageData[]>(row.promotes, []),
      levelUpItemIds: parseJson<string[]>(row.levelUpItemIds, []),
    };
  } catch (error) {
    console.error("WeaponUpgrade DB取得失敗:", error);
    return null;
  }
}

/** 目盛り間EXP一覧 */
export async function getLevelExpSegments(): Promise<LevelExpSegmentData[]> {
  try {
    const rows = await prisma.levelExpSegment.findMany({
      orderBy: [{ targetType: "asc" }, { rarity: "asc" }, { fromLevel: "asc" }],
    });
    return rows.map((r) => ({
      id: r.id,
      targetType: r.targetType as "character" | "weapon",
      rarity: r.rarity,
      fromLevel: r.fromLevel,
      toLevel: r.toLevel,
      expRequired: r.expRequired,
      moraRequired: r.moraRequired,
    }));
  } catch (error) {
    console.error("LevelExpSegment DB取得失敗:", error);
    return [];
  }
}

/** レベルアップ素材（経験値書・魔鉱）一覧 */
export async function getLevelUpMaterials(): Promise<LevelUpMaterialData[]> {
  try {
    const rows = await prisma.material.findMany({
      where: { expValue: { not: null }, expTarget: { not: null } },
      select: {
        id: true,
        name: true,
        expValue: true,
        expTarget: true,
      },
      orderBy: { expValue: "desc" },
    });
    return rows
      .filter((r) => r.expValue != null && r.expTarget != null)
      .map((r) => ({
        materialId: r.id,
        name: r.name,
        exp: r.expValue!,
        targetType: r.expTarget as "character" | "weapon",
      }));
  } catch (error) {
    console.error("LevelUpMaterials DB取得失敗:", error);
    return [];
  }
}

/** 詳細画面用の育成データキャッシュをまとめて取得 */
export async function getUpgradeDataCache(): Promise<UpgradeDataCache> {
  const [levelExpSegments, levelUpMaterials] = await Promise.all([
    getLevelExpSegments(),
    getLevelUpMaterials(),
  ]);
  return { levelExpSegments, levelUpMaterials };
}
