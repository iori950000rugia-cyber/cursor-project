import { createHash } from "node:crypto";
import { GCSIM_VERSION, ROTATION_TEMPLATE_VERSION } from "./settings";
import type { TeamCandidate, TeamRecommendationRequest } from "./types";

export function stableHash(value: unknown): string {
  return createHash("sha256").update(canonicalJson(value)).digest("hex");
}

export function simulationCacheKey(input: {
  request: TeamRecommendationRequest;
  candidate: TeamCandidate;
  iterations: number;
}): string {
  return stableHash({
    gcsimVersion: GCSIM_VERSION,
    attackerId: input.request.attackerId,
    teamCharacterIds: [input.request.attackerId, ...input.candidate.members.filter((id) => id !== input.request.attackerId).sort()],
    normalizedBuildHash: stableHash(input.request.characters.filter((build) => input.candidate.members.includes(build.characterId))),
    enemyConfigHash: stableHash({ enemy: input.request.enemy, mode: input.request.mode, half: input.request.half }),
    rotationTemplateVersion: ROTATION_TEMPLATE_VERSION,
    iterations: input.iterations,
  });
}

function canonicalJson(value: unknown): string {
  if (Array.isArray(value)) return `[${value.map(canonicalJson).join(",")}]`;
  if (value && typeof value === "object") {
    const record = value as Record<string, unknown>;
    return `{${Object.keys(record).sort().map((key) => `${JSON.stringify(key)}:${canonicalJson(record[key])}`).join(",")}}`;
  }
  return JSON.stringify(value);
}
