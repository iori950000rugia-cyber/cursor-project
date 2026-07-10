/**
 * マスターデータ同期API（Cron / 外部トリガー専用）
 *
 * POST /api/sync で外部APIからDBへマスターデータを同期する。
 * Body: { "fullUpgrade": false } — false=差分（既定）, true=突破データ全件再取得
 *
 * 設定画面の手動同期は Server Action（syncMasterDataAction）を使用すること。
 * Authorization: Bearer <SYNC_API_SECRET> が必要（本番必須）。
 */

import { NextResponse } from "next/server";
import { syncMasterData } from "@/lib/sync";
import { verifySyncApiSecret } from "@/lib/sync-auth";

export const maxDuration = 300;

export async function POST(request: Request) {
  if (!verifySyncApiSecret(request)) {
    return NextResponse.json(
      { ok: false, message: "認証に失敗しました。" },
      { status: 401 },
    );
  }

  try {
    let fullUpgrade = false;
    try {
      const body = (await request.json()) as { fullUpgrade?: boolean };
      fullUpgrade = body.fullUpgrade === true;
    } catch {
      // body なしは差分同期
    }

    const result = await syncMasterData({ fullUpgrade });
    return NextResponse.json({ ok: result.errors.length === 0, ...result });
  } catch (error) {
    console.error("マスターデータ同期に失敗しました:", error);
    return NextResponse.json(
      { ok: false, message: "同期に失敗しました。時間をおいて再度お試しください。" },
      { status: 500 },
    );
  }
}
