"use server";

/**
 * マスターデータ同期 Server Action
 *
 * 設定画面の同期ボタンから呼ばれる。サーバー内で syncMasterData() を実行するため、
 * 外部から /api/sync を叩く必要がない（Cron 用 API とは経路を分離）。
 */

import { revalidatePath } from "next/cache";
import { syncMasterData, type SyncResult } from "@/lib/sync";

export type SyncActionResult = SyncResult & {
  ok: boolean;
  message?: string;
};

/** マスターデータを外部 API から DB へ同期する */
export async function syncMasterDataAction(
  fullUpgrade = false,
): Promise<SyncActionResult> {
  try {
    const result = await syncMasterData({ fullUpgrade });
    revalidatePath("/characters");
    revalidatePath("/settings");
    return {
      ok: result.errors.length === 0,
      ...result,
    };
  } catch (error) {
    console.error("マスターデータ同期に失敗しました:", error);
    return {
      ok: false,
      message: "同期に失敗しました。時間をおいて再度お試しください。",
      provider: "",
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
  }
}
