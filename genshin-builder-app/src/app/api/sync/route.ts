/**
 * マスターデータ同期API
 *
 * POST /api/sync で外部APIからDBへマスターデータを同期する。
 * Body: { "fullUpgrade": false } — false=差分（既定）, true=突破データ全件再取得
 */

import { NextResponse } from "next/server";
import { syncMasterData } from "@/lib/sync";

export const maxDuration = 300;

export async function POST(request: Request) {
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
