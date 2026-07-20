import type {
  Element,
  InputQuality,
  SimulationBuildSnapshot,
  TeamRecommendationRequest,
} from "./types";

const REQUEST_KEYS = new Set(["attackerId", "mode", "half", "ownedOnly", "enemy", "preference", "characters"]);
const BUILD_KEYS = new Set([
  "characterId", "element", "rarity", "isOwned", "level", "ascension",
  "constellation", "talents", "weapon", "artifacts", "inputQuality", "defaultedFields",
]);
const ELEMENTS = new Set<Element>(["anemo", "cryo", "dendro", "electro", "geo", "hydro", "pyro"]);
const QUALITIES = new Set<InputQuality>(["exact", "partial", "defaulted", "unsupported"]);

export function parseTeamRecommendationRequest(value: unknown): TeamRecommendationRequest {
  if (!isRecord(value) || !onlyKeys(value, REQUEST_KEYS)) throw new Error("invalidRequest");
  const attackerId = id(value.attackerId);
  if (value.mode !== "spiralAbyss" || (value.half !== "upper" && value.half !== "lower")) {
    throw new Error("invalidRequest");
  }
  if (typeof value.ownedOnly !== "boolean") throw new Error("invalidRequest");
  if (value.enemy !== "single" && value.enemy !== "multiple") throw new Error("invalidRequest");
  if (!["damage", "stability", "fourStar", "built"].includes(String(value.preference))) {
    throw new Error("invalidRequest");
  }
  if (!Array.isArray(value.characters) || value.characters.length < 1 || value.characters.length > 256) {
    throw new Error("invalidRequest");
  }
  const characters = value.characters.map(parseBuild);
  if (!characters.some((character) => character.characterId === attackerId)) {
    throw new Error("invalidRequest");
  }
  if (new Set(characters.map((character) => character.characterId)).size !== characters.length) {
    throw new Error("invalidRequest");
  }
  return {
    attackerId,
    mode: "spiralAbyss",
    half: value.half,
    ownedOnly: value.ownedOnly,
    enemy: value.enemy,
    preference: value.preference as TeamRecommendationRequest["preference"],
    characters,
  };
}

function parseBuild(value: unknown): SimulationBuildSnapshot {
  if (!isRecord(value) || !onlyKeys(value, BUILD_KEYS)) throw new Error("invalidRequest");
  const characterId = id(value.characterId);
  if (!ELEMENTS.has(value.element as Element) || (value.rarity !== 4 && value.rarity !== 5)) {
    throw new Error("invalidRequest");
  }
  if (typeof value.isOwned !== "boolean" || !int(value.level, 1, 90) || !int(value.ascension, 0, 6) || !int(value.constellation, 0, 6)) {
    throw new Error("invalidRequest");
  }
  if (!QUALITIES.has(value.inputQuality as InputQuality)) throw new Error("invalidRequest");
  if (!Array.isArray(value.defaultedFields) || value.defaultedFields.length > 32 || !value.defaultedFields.every(safeField)) {
    throw new Error("invalidRequest");
  }
  const talents = parseTalents(value.talents);
  const weapon = parseWeapon(value.weapon);
  const artifacts = parseArtifacts(value.artifacts);
  return {
    characterId,
    element: value.element as Element,
    rarity: value.rarity,
    isOwned: value.isOwned,
    level: value.level,
    ascension: value.ascension,
    constellation: value.constellation,
    ...(talents ? { talents } : {}),
    ...(weapon ? { weapon } : {}),
    ...(artifacts ? { artifacts } : {}),
    inputQuality: value.inputQuality as InputQuality,
    defaultedFields: [...value.defaultedFields] as string[],
  };
}

function parseTalents(value: unknown) {
  if (value === undefined) return undefined;
  if (!isRecord(value) || !onlyKeys(value, new Set(["normal", "skill", "burst"]))) throw new Error("invalidRequest");
  if (!int(value.normal, 1, 15) || !int(value.skill, 1, 15) || !int(value.burst, 1, 15)) throw new Error("invalidRequest");
  return { normal: value.normal, skill: value.skill, burst: value.burst };
}

function parseWeapon(value: unknown) {
  if (value === undefined) return undefined;
  if (!isRecord(value) || !onlyKeys(value, new Set(["weaponId", "level", "ascension", "refinement"]))) throw new Error("invalidRequest");
  if (!int(value.level, 1, 90) || !int(value.ascension, 0, 6) || !int(value.refinement, 1, 5)) throw new Error("invalidRequest");
  return { weaponId: id(value.weaponId), level: value.level, ascension: value.ascension, refinement: value.refinement };
}

function parseArtifacts(value: unknown) {
  if (value === undefined) return undefined;
  if (!isRecord(value) || !onlyKeys(value, new Set(["sets", "stats"])) || !Array.isArray(value.sets) || value.sets.length > 5 || !isRecord(value.stats)) {
    throw new Error("invalidRequest");
  }
  const sets = value.sets.map((entry) => {
    if (!isRecord(entry) || !onlyKeys(entry, new Set(["setId", "count"])) || !int(entry.count, 1, 5)) throw new Error("invalidRequest");
    return { setId: id(entry.setId), count: entry.count };
  });
  const allowedStats = new Set([
    "hpFlat", "hpPercent", "atkFlat", "atkPercent", "defFlat", "defPercent", "critRate", "critDamage",
    "energyRecharge", "elementalMastery", "anemoDamageBonus", "cryoDamageBonus", "dendroDamageBonus",
    "electroDamageBonus", "geoDamageBonus", "hydroDamageBonus", "pyroDamageBonus", "physicalDamageBonus",
  ]);
  if (!onlyKeys(value.stats, allowedStats)) throw new Error("invalidRequest");
  const stats: Record<string, number> = {};
  for (const [key, raw] of Object.entries(value.stats)) {
    if (typeof raw !== "number" || !Number.isFinite(raw) || raw < 0 || raw > 100_000) throw new Error("invalidRequest");
    stats[key] = raw;
  }
  return { sets, stats };
}

function id(value: unknown): string {
  const parsed = typeof value === "number" && Number.isSafeInteger(value) ? String(value) : value;
  if (typeof parsed !== "string" || !/^\d{5,12}$/.test(parsed)) throw new Error("invalidRequest");
  return parsed;
}

function int(value: unknown, min: number, max: number): value is number {
  return typeof value === "number" && Number.isInteger(value) && value >= min && value <= max;
}

function safeField(value: unknown): value is string {
  return typeof value === "string" && /^[A-Za-z][A-Za-z0-9.]{0,63}$/.test(value);
}

function onlyKeys(value: Record<string, unknown>, allowed: Set<string>): boolean {
  return Object.keys(value).every((key) => allowed.has(key));
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}
