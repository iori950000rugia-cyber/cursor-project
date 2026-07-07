/**
 * マスターデータ同期処理
 *
 * 外部API → DB へキャラクター・武器・素材を登録・更新（upsert）する。
 * APIが一時的に落ちていてもDB内の既存データはそのまま残るため、
 * アプリはDBのデータで動作し続けられる。
 *
 * 将来的には Vercel Cron などからこの関数を定期実行する想定。
 */

import { gameDataProvider } from "@/lib/api";
import { prisma } from "@/lib/db";
import { syncUpgradeData, type UpgradeSyncOptions } from "@/lib/sync-upgrade";
import { idsForNotIn } from "@/lib/sync-utils";

export interface SyncOptions extends UpgradeSyncOptions {}

export interface SyncResult {
  provider: string;
  characters: number;
  weapons: number;
  materials: number;
  characterUpgrades: number;
  weaponUpgrades: number;
  levelExpSegments: number;
  expMaterials: number;
  upgradeApiCalls: number;
  skippedCharacterUpgrades: number;
  skippedWeaponUpgrades: number;
  errors: string[];
}

/** マスターデータを外部APIからDBへ同期する */
export async function syncMasterData(
  options: SyncOptions = {},
): Promise<SyncResult> {
  const result: SyncResult = {
    provider: gameDataProvider.name,
    characters: 0,
    weapons: 0,
    materials: 0,
    characterUpgrades: 0,
    weaponUpgrades: 0,
    levelExpSegments: 0,
    expMaterials: 0,
    upgradeApiCalls: 0,
    skippedCharacterUpgrades: 0,
    skippedWeaponUpgrades: 0,
    errors: [],
  };

  // 3種類のデータを並列取得。1種類が失敗しても他は同期を続行する
  const [charactersRes, weaponsRes, materialsRes] = await Promise.allSettled([
    gameDataProvider.fetchCharacters(),
    gameDataProvider.fetchWeapons(),
    gameDataProvider.fetchMaterials(),
  ]);

  if (charactersRes.status === "fulfilled") {
    for (const c of charactersRes.value) {
      await prisma.character.upsert({
        where: { id: c.id },
        create: c,
        update: c,
      });
    }
    // プロバイダー変更などでAPIに存在しなくなったデータを削除する。
    // ただしユーザーの育成データが紐づいているキャラは残す（データ保護）
    const characterIds = charactersRes.value.map((c) => c.id);
    const excludeIds = idsForNotIn(characterIds);
    if (excludeIds) {
      await prisma.character.deleteMany({
        where: {
          id: { notIn: excludeIds },
          progresses: { none: {} },
        },
      });
    }
    result.characters = charactersRes.value.length;
  } else {
    result.errors.push(`characters: ${String(charactersRes.reason)}`);
  }

  if (weaponsRes.status === "fulfilled") {
    for (const w of weaponsRes.value) {
      await prisma.weapon.upsert({
        where: { id: w.id },
        create: w,
        update: w,
      });
    }
    const weaponIds = weaponsRes.value.map((w) => w.id);
    const excludeWeaponIds = idsForNotIn(weaponIds);
    if (excludeWeaponIds) {
      await prisma.weapon.deleteMany({
        where: { id: { notIn: excludeWeaponIds } },
      });
    }
    result.weapons = weaponsRes.value.length;
  } else {
    result.errors.push(`weapons: ${String(weaponsRes.reason)}`);
  }

  if (materialsRes.status === "fulfilled") {
    for (const m of materialsRes.value) {
      await prisma.material.upsert({
        where: { id: m.id },
        create: m,
        update: m,
      });
    }
    const materialIds = materialsRes.value.map((m) => m.id);
    const excludeMaterialIds = idsForNotIn(materialIds);
    if (excludeMaterialIds) {
      await prisma.material.deleteMany({
        where: { id: { notIn: excludeMaterialIds } },
      });
    }
    result.materials = materialsRes.value.length;
  } else {
    result.errors.push(`materials: ${String(materialsRes.reason)}`);
  }

  // 突破・天賦・EXP（差分同期。fullUpgrade で全件再取得）
  const upgradeRes = await syncUpgradeData(options);
  result.characterUpgrades = upgradeRes.characterUpgrades;
  result.weaponUpgrades = upgradeRes.weaponUpgrades;
  result.levelExpSegments = upgradeRes.levelExpSegments;
  result.expMaterials = upgradeRes.expMaterials;
  result.upgradeApiCalls = upgradeRes.apiCalls;
  result.skippedCharacterUpgrades = upgradeRes.skippedCharacterUpgrades;
  result.skippedWeaponUpgrades = upgradeRes.skippedWeaponUpgrades;
  result.errors.push(...upgradeRes.errors);

  // 同期履歴を残す（Cron監視・デバッグ用）
  await prisma.syncLog.create({
    data: {
      status: result.errors.length === 0 ? "success" : "error",
      detail: JSON.stringify(result),
    },
  });

  return result;
}
