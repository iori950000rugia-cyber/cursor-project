/**
 * 武器マスターデータのリポジトリ（DB読み取り層）
 */

import { prisma } from "@/lib/db";

export interface WeaponOption {
  id: string;
  name: string;
  rarity: number;
  iconUrl: string;
}

/** 公開APIの境界で、同期済みマスターに存在する武器か確認する。 */
export async function isKnownWeapon(id: string): Promise<boolean> {
  const weapon = await prisma.weapon.findUnique({
    where: { id },
    select: { id: true },
  });
  return weapon !== null;
}

/**
 * 指定した武器種の武器一覧を取得する（育成フォームの選択肢用）。
 * レアリティの高い順・名前順で返す。
 */
export async function getWeaponsByType(
  weaponType: string,
): Promise<WeaponOption[]> {
  try {
    return await prisma.weapon.findMany({
      where: { weaponType, rarity: { gte: 3 } },
      select: { id: true, name: true, rarity: true, iconUrl: true },
      orderBy: [{ rarity: "desc" }, { name: "asc" }],
    });
  } catch (error) {
    console.error("武器のDB取得に失敗しました:", error);
    return [];
  }
}
