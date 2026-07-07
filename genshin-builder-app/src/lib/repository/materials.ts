/**
 * 素材マスターデータのリポジトリ（DB読み取り層）
 */

import { prisma } from "@/lib/db";

export interface MaterialInfo {
  id: string;
  name: string;
  iconUrl: string;
}

/** 指定IDの素材情報を取得（存在しないIDは除外） */
export async function getMaterialsByIds(
  ids: string[],
): Promise<MaterialInfo[]> {
  if (ids.length === 0) return [];
  try {
    return await prisma.material.findMany({
      where: { id: { in: ids } },
      select: { id: true, name: true, iconUrl: true },
    });
  } catch (error) {
    console.error("素材のDB取得に失敗しました:", error);
    return [];
  }
}

/** 素材ID → 表示情報のルックアップ用一覧 */
export async function getAllMaterialLookup(): Promise<MaterialInfo[]> {
  try {
    return await prisma.material.findMany({
      select: { id: true, name: true, iconUrl: true },
      orderBy: { name: "asc" },
    });
  } catch (error) {
    console.error("素材一覧のDB取得に失敗しました:", error);
    return [];
  }
}
