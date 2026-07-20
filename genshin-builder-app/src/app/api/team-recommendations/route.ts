import { NextRequest, NextResponse } from "next/server";
import { getTeamRecommendationService } from "@/lib/team-recommendations/runtime";
import type { TeamRecommendationJob } from "@/lib/team-recommendations/types";
import type { TeamRecommendationRequest } from "@/lib/team-recommendations/types";
import { parseTeamRecommendationRequest } from "@/lib/team-recommendations/validation";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
const MAX_REQUEST_BYTES = 524_288;

type Enqueue = (value: TeamRecommendationRequest) => Promise<TeamRecommendationJob>;
export function createTeamRecommendationPost(enqueue: Enqueue) {
  return async function POST(request: NextRequest) {
    const length = Number(request.headers.get("content-length") ?? 0);
    if (Number.isFinite(length) && length > MAX_REQUEST_BYTES) return error(413, "invalidRequest", "送信データが大きすぎます。");
    let parsed: TeamRecommendationRequest;
    try {
      const raw = await request.text();
      if (Buffer.byteLength(raw, "utf8") > MAX_REQUEST_BYTES) return error(413, "invalidRequest", "送信データが大きすぎます。");
      const value: unknown = JSON.parse(raw);
      parsed = parseTeamRecommendationRequest(value);
    } catch {
      return error(400, "invalidRequest", "シミュレーション入力を確認できませんでした。");
    }
    try {
      const job = await enqueue(parsed);
      return NextResponse.json(job, { status: job.status === "queued" ? 202 : 200, headers: { "Cache-Control": "no-store" } });
    } catch {
      return error(503, "temporarilyUnavailable", "おすすめ編成を開始できませんでした。");
    }
  };
}

export const POST = createTeamRecommendationPost((request) => getTeamRecommendationService().enqueue(request));

function error(status: number, code: string, message: string) {
  return NextResponse.json({ error: { code, message } }, { status, headers: { "Cache-Control": "no-store" } });
}
