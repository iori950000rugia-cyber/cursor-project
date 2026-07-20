import type { AbyssTeamStatistic } from "@/lib/abyss/types";
import type {
  CandidateGenerationContext,
  Element,
  SimulationBuildSnapshot,
  TeamCandidate,
} from "./types";
import { hasRole, isKnownPhysicalAttacker } from "./role-profiles";

const MAX_AZA = 10;
const MAX_CO_OCCURRENCE = 20;
const MAX_RULE = 20;

export class TeamCandidateGenerator {
  generate({ request, abyssTeams }: CandidateGenerationContext): TeamCandidate[] {
    const byId = new Map(request.characters.map((character) => [character.characterId, character]));
    const candidates: TeamCandidate[] = [];
    const seen = new Set<string>();
    const add = (candidate: TeamCandidate) => {
      const key = teamKey(candidate.attackerId, candidate.members);
      if (candidate.members.length !== 4 || new Set(candidate.members).size !== 4 || seen.has(key)) return;
      if (!candidate.members.includes(request.attackerId) || !satisfiesConstraints(candidate.members, byId)) return;
      if (request.ownedOnly && candidate.members.some((member) => !byId.get(member)?.isOwned)) return;
      seen.add(key);
      candidates.push(candidate);
    };

    for (const team of abyssTeams
      .filter((value) => value.half === request.half && value.members.includes(request.attackerId))
      .sort((a, b) => b.usageRate - a.usageRate)
      .slice(0, MAX_AZA)) {
      add(this.toCandidate(request.attackerId, team.members, ["aza"], team.usageRate, byId));
    }

    const partnerScores = coOccurrenceScores(request.attackerId, abyssTeams);
    const coPool = partnerScores.filter(([id]) => byId.has(id)).slice(0, 12).map(([id]) => id);
    for (let index = 0; index < Math.min(MAX_CO_OCCURRENCE, coPool.length * 2); index += 1) {
      const members = deterministicTeam(request.attackerId, coPool, index);
      if (members) add(this.toCandidate(request.attackerId, members, ["coOccurrence"], 0, byId));
    }

    const rulePool = request.characters
      .filter((character) => character.characterId !== request.attackerId)
      .filter((character) => !request.ownedOnly || character.isOwned)
      .sort((a, b) => compatibility(byId.get(request.attackerId), b) - compatibility(byId.get(request.attackerId), a))
      .slice(0, 16)
      .map((character) => character.characterId);
    for (let index = 0; index < Math.min(MAX_RULE, rulePool.length * 2); index += 1) {
      const members = deterministicTeam(request.attackerId, rulePool, index);
      if (members) add(this.toCandidate(request.attackerId, members, ["ruleBased"], 0, byId));
    }
    return candidates.slice(0, 50);
  }

  private toCandidate(
    attackerId: string,
    members: string[],
    sourceTypes: TeamCandidate["sourceTypes"],
    usageRate: number,
    byId: Map<string, SimulationBuildSnapshot>,
  ): TeamCandidate {
    const elements = members.map((id) => byId.get(id)?.element).filter(isElement);
    const reactionType = detectReaction(elements, attackerId, byId.get(attackerId)?.element);
    const hasSustain = members.some((id) => hasRole(id, "healer", "shielder"));
    const batteryCount = members.filter((id) => hasRole(id, "battery")).length;
    return {
      attackerId,
      members: [...members],
      sourceTypes,
      observedByAza: sourceTypes.includes("aza"),
      azaUsageRate: usageRate,
      reactionType,
      hasSustain,
      energyStability: Math.min(1, 0.45 + batteryCount * 0.2 + (hasSustain ? 0.1 : 0)),
      rotationConfidence: sourceTypes.includes("aza") ? "medium" : "low",
    };
  }
}

export function teamKey(attackerId: string, members: string[]): string {
  const partners = members.filter((id) => id !== attackerId).sort();
  return `${attackerId}:${partners.join(",")}`;
}

function coOccurrenceScores(attackerId: string, teams: AbyssTeamStatistic[]): Array<[string, number]> {
  const scores = new Map<string, number>();
  for (const team of teams) {
    if (!team.members.includes(attackerId)) continue;
    for (const member of team.members) {
      if (member === attackerId) continue;
      scores.set(member, (scores.get(member) ?? 0) + Math.max(team.usageRate, 0.0001));
    }
  }
  return [...scores.entries()].sort((a, b) => b[1] - a[1] || a[0].localeCompare(b[0]));
}

function deterministicTeam(attackerId: string, pool: string[], index: number): string[] | null {
  if (pool.length < 3) return null;
  const result = [attackerId];
  for (let offset = 0; offset < pool.length && result.length < 4; offset += 1) {
    const id = pool[(index + offset * (index % 3 + 1)) % pool.length];
    if (!result.includes(id)) result.push(id);
  }
  return result.length === 4 ? result : null;
}

function compatibility(attacker: SimulationBuildSnapshot | undefined, partner: SimulationBuildSnapshot): number {
  if (!attacker) return 0;
  let score = partner.isOwned ? 3 : 0;
  if (partner.level >= 80) score += 2;
  if (hasRole(partner.characterId, "healer", "shielder")) score += 2;
  if (hasRole(partner.characterId, "battery")) score += 1;
  if (partner.element !== attacker.element) score += reacts(attacker.element, partner.element) ? 2 : 0.5;
  return score;
}

function satisfiesConstraints(members: string[], byId: Map<string, SimulationBuildSnapshot>): boolean {
  const elements = members.map((id) => byId.get(id)?.element).filter(isElement);
  if (elements.length !== 4) return false;
  if (members.includes("10000070") && elements.some((element) => element !== "hydro" && element !== "dendro")) return false;
  if (members.includes("10000090") && elements.some((element) => element !== "pyro" && element !== "electro")) return false;
  if (members.includes("10000055") && elements.filter((element) => element === "geo").length < 2) return false;
  if (members.includes("10000076") && !elements.includes("anemo")) return false;
  if (members.includes("10000056") && !elements.includes("electro")) return false;
  return new Set(elements).size === 1 || elements.some((left, index) => elements.slice(index + 1).some((right) => reacts(left, right)));
}

function reacts(left: Element, right: Element): boolean {
  if (left === right) return false;
  if (left === "anemo" || right === "anemo") return left !== "geo" && right !== "geo";
  if (left === "geo" || right === "geo") return left !== "dendro" && right !== "dendro";
  if (left === "dendro" || right === "dendro") return !["cryo", "anemo", "geo"].includes(left === "dendro" ? right : left);
  return true;
}

function detectReaction(elements: Element[], attackerId: string, attackerElement: Element | undefined): string {
  const has = (...values: Element[]) => values.every((value) => elements.includes(value));
  if (isKnownPhysicalAttacker(attackerId) && has("cryo", "electro")) return "physical";
  if (has("dendro", "hydro", "electro")) return "hyperbloom";
  if (has("dendro", "hydro", "pyro")) return "burgeon";
  if (has("dendro", "hydro")) return "bloom";
  if (has("dendro", "electro")) return attackerElement === "dendro" ? "spread" : attackerElement === "electro" ? "aggravate" : "quicken";
  if (has("hydro", "pyro")) return "vaporize";
  if (has("cryo", "pyro")) return "melt";
  if (has("cryo", "hydro")) return "freeze";
  if (has("electro", "pyro")) return "overload";
  if (elements.includes("anemo")) return "swirl";
  if (elements.includes("geo")) return "crystallize";
  return "mono";
}

function isElement(value: Element | undefined): value is Element {
  return value !== undefined;
}
