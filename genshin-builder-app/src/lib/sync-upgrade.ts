/**
 * 突破・天賦・レベルEXPデータの同期
 *
 * 通常同期: マスタ一覧 + DB に未登録の突破データのみ API 取得（差分）
 * 完全同期: 全キャラ・武器の detail API を再取得
 */

import {
  buildLevelExpSegments,
  fetchCharacterUpgradeFromApi,
  fetchLevelUpMaterialsFromApi,
  fetchWeaponUpgradeFromApi,
  mapWithConcurrency,
} from "@/lib/api/amber-upgrade";
import { prisma } from "@/lib/db";

const EXP_MATERIAL_COUNT = 6;
const LEVEL_EXP_SEGMENT_COUNT = 32;
const CONCURRENCY = 4;
const REQUEST_DELAY_MS = 100;

export interface UpgradeSyncOptions {
  /** true なら全件 detail API を再取得 */
  fullUpgrade?: boolean;
}

export interface UpgradeSyncResult {
  characterUpgrades: number;
  weaponUpgrades: number;
  levelExpSegments: number;
  expMaterials: number;
  /** 今回 API を叩いた回数（目安） */
  apiCalls: number;
  skippedCharacterUpgrades: number;
  skippedWeaponUpgrades: number;
  errors: string[];
}

function trackApiCall(counter: { count: number }): void {
  counter.count += 1;
}

async function delay(ms: number): Promise<void> {
  if (ms <= 0) return;
  await new Promise((resolve) => setTimeout(resolve, ms));
}

/** 突破・天賦・EXPデータをAPIからDBへ同期 */
export async function syncUpgradeData(
  options: UpgradeSyncOptions = {},
): Promise<UpgradeSyncResult> {
  const fullUpgrade = options.fullUpgrade ?? false;
  const apiCounter = { count: 0 };

  const result: UpgradeSyncResult = {
    characterUpgrades: 0,
    weaponUpgrades: 0,
    levelExpSegments: 0,
    expMaterials: 0,
    apiCalls: 0,
    skippedCharacterUpgrades: 0,
    skippedWeaponUpgrades: 0,
    errors: [],
  };

  // 1. 経験値素材（API material detail）— 未設定時のみ
  try {
    const existingExpMaterials = await prisma.material.count({
      where: { expValue: { not: null }, expTarget: { not: null } },
    });

    if (fullUpgrade || existingExpMaterials < EXP_MATERIAL_COUNT) {
      const levelUpMaterials = await fetchLevelUpMaterialsFromApi(() =>
        trackApiCall(apiCounter),
      );
      for (const mat of levelUpMaterials) {
        await prisma.material.updateMany({
          where: { id: mat.materialId },
          data: {
            expValue: mat.exp,
            expTarget: mat.targetType,
          },
        });
      }
      result.expMaterials = levelUpMaterials.length;
    } else {
      result.expMaterials = existingExpMaterials;
    }
  } catch (error) {
    result.errors.push(`expMaterials: ${String(error)}`);
  }

  // 2. 目盛り間EXP（API なし・定数）— 未登録時のみ書き込み
  try {
    const existingSegments = await prisma.levelExpSegment.count();
    if (fullUpgrade || existingSegments < LEVEL_EXP_SEGMENT_COUNT) {
      const segments = buildLevelExpSegments();
      for (const seg of segments) {
        await prisma.levelExpSegment.upsert({
          where: { id: seg.id },
          create: seg,
          update: {
            expRequired: seg.expRequired,
            moraRequired: seg.moraRequired,
          },
        });
      }
      result.levelExpSegments = segments.length;
    } else {
      result.levelExpSegments = existingSegments;
    }
  } catch (error) {
    result.errors.push(`levelExpSegments: ${String(error)}`);
  }

  // 3. キャラクター突破・天賦
  try {
    const [allCharacters, existingUpgrades] = await Promise.all([
      prisma.character.findMany({ select: { id: true } }),
      prisma.characterUpgrade.findMany({ select: { characterId: true } }),
    ]);

    const existingIds = new Set(existingUpgrades.map((u) => u.characterId));
    const targetIds = fullUpgrade
      ? allCharacters.map((c) => c.id)
      : allCharacters.filter((c) => !existingIds.has(c.id)).map((c) => c.id);

    result.skippedCharacterUpgrades = allCharacters.length - targetIds.length;

    const upgrades = await mapWithConcurrency(
      targetIds,
      CONCURRENCY,
      async (characterId) => {
        await delay(REQUEST_DELAY_MS);
        trackApiCall(apiCounter);
        return fetchCharacterUpgradeFromApi(characterId);
      },
    );

    for (const upgrade of upgrades) {
      await prisma.characterUpgrade.upsert({
        where: { characterId: upgrade.characterId },
        create: {
          characterId: upgrade.characterId,
          promotes: JSON.stringify(upgrade.promotes),
          talents: JSON.stringify(upgrade.talents),
        },
        update: {
          promotes: JSON.stringify(upgrade.promotes),
          talents: JSON.stringify(upgrade.talents),
        },
      });
    }

    const syncedIds = upgrades.map((u) => u.characterId);

    if (fullUpgrade && syncedIds.length > 0) {
      await prisma.characterUpgrade.deleteMany({
        where: { characterId: { notIn: syncedIds } },
      });
    }

    result.characterUpgrades = await prisma.characterUpgrade.count();
  } catch (error) {
    result.errors.push(`characterUpgrades: ${String(error)}`);
  }

  // 4. 武器突破
  try {
    const [allWeapons, existingUpgrades] = await Promise.all([
      prisma.weapon.findMany({ select: { id: true } }),
      prisma.weaponUpgrade.findMany({ select: { weaponId: true } }),
    ]);

    const existingIds = new Set(existingUpgrades.map((u) => u.weaponId));
    const targetIds = fullUpgrade
      ? allWeapons.map((w) => w.id)
      : allWeapons.filter((w) => !existingIds.has(w.id)).map((w) => w.id);

    result.skippedWeaponUpgrades = allWeapons.length - targetIds.length;

    const upgrades = await mapWithConcurrency(
      targetIds,
      CONCURRENCY,
      async (weaponId) => {
        await delay(REQUEST_DELAY_MS);
        trackApiCall(apiCounter);
        return fetchWeaponUpgradeFromApi(weaponId);
      },
    );

    for (const upgrade of upgrades) {
      await prisma.weaponUpgrade.upsert({
        where: { weaponId: upgrade.weaponId },
        create: {
          weaponId: upgrade.weaponId,
          promotes: JSON.stringify(upgrade.promotes),
          levelUpItemIds: JSON.stringify(upgrade.levelUpItemIds),
        },
        update: {
          promotes: JSON.stringify(upgrade.promotes),
          levelUpItemIds: JSON.stringify(upgrade.levelUpItemIds),
        },
      });
    }

    const syncedWeaponIds = upgrades.map((u) => u.weaponId);

    if (fullUpgrade && syncedWeaponIds.length > 0) {
      await prisma.weaponUpgrade.deleteMany({
        where: { weaponId: { notIn: syncedWeaponIds } },
      });
    }

    result.weaponUpgrades = await prisma.weaponUpgrade.count();
  } catch (error) {
    result.errors.push(`weaponUpgrades: ${String(error)}`);
  }

  result.apiCalls = apiCounter.count;
  return result;
}
