import { NextResponse } from "next/server";
import { getTeamRecommendationService } from "@/lib/team-recommendations/runtime";
import type { TeamRecommendationJob } from "@/lib/team-recommendations/types";

export const runtime = "nodejs";
export const dynamic = "force-dynamic";
type LoadJob = (jobId: string) => Promise<TeamRecommendationJob | null>;

export function createTeamRecommendationGet(load: LoadJob) {
  return async function GET(_request: Request, context: { params: Promise<{ jobId: string }> }) {
    const { jobId } = await context.params;
    if (!/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(jobId)) {
      return NextResponse.json({ error: { code: "notFound", message: "Jobが見つかりません。" } }, { status: 404 });
    }
    const job = await load(jobId);
    return job
      ? NextResponse.json(job, { status: 200, headers: { "Cache-Control": "no-store" } })
      : NextResponse.json({ error: { code: "notFound", message: "Jobが見つかりません。" } }, { status: 404, headers: { "Cache-Control": "no-store" } });
  };
}

export const GET = createTeamRecommendationGet((jobId) => getTeamRecommendationService().get(jobId));
