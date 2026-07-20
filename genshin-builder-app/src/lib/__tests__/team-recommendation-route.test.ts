import { NextRequest } from "next/server";
import { describe, expect, it, vi } from "vitest";
import { createTeamRecommendationPost } from "@/app/api/team-recommendations/route";
import { createTeamRecommendationGet } from "@/app/api/team-recommendations/jobs/[jobId]/route";

const jobId = "123e4567-e89b-42d3-a456-426614174000";
const body = {
  attackerId: "10000089", mode: "spiralAbyss", half: "upper", ownedOnly: true, enemy: "single", preference: "damage",
  characters: [{ characterId: "10000089", element: "hydro", rarity: 5, isOwned: true, level: 90, ascension: 6, constellation: 0, inputQuality: "partial", defaultedFields: ["weapon"] }],
};

describe("team recommendation routes", () => {
  it("POST returns 202 for a queued job", async () => {
    const enqueue = vi.fn(async () => ({ jobId, status: "queued" as const }));
    const response = await createTeamRecommendationPost(enqueue)(request(body));
    expect(response.status).toBe(202);
    expect(await response.json()).toEqual({ jobId, status: "queued" });
    expect(response.headers.get("cache-control")).toBe("no-store");
  });
  it.each(["config", "command", "path", "cookie", "uid"])("POST rejects %s before enqueue", async (key) => {
    const enqueue = vi.fn();
    const response = await createTeamRecommendationPost(enqueue)(request({ ...body, [key]: "malicious" }));
    expect(response.status).toBe(400);
    expect(enqueue).not.toHaveBeenCalled();
  });
  it("POST hides internal enqueue errors", async () => {
    const response = await createTeamRecommendationPost(async () => { throw new Error("DATABASE_URL=secret"); })(request(body));
    expect(response.status).toBe(503);
    expect(JSON.stringify(await response.json())).not.toContain("DATABASE_URL");
  });
  it("GET distinguishes found and missing jobs", async () => {
    const found = await createTeamRecommendationGet(async () => ({ jobId, status: "running" }))(
      new Request("https://builder.example.com/api/team-recommendations/jobs/" + jobId), { params: Promise.resolve({ jobId }) },
    );
    expect(found.status).toBe(200);
    const missing = await createTeamRecommendationGet(async () => null)(
      new Request("https://builder.example.com/api/team-recommendations/jobs/" + jobId), { params: Promise.resolve({ jobId }) },
    );
    expect(missing.status).toBe(404);
  });
});

function request(value: unknown) {
  return new NextRequest("https://builder.example.com/api/team-recommendations", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(value) });
}
