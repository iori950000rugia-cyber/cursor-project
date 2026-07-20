import { GcsimArtifactMapper, GcsimCharacterMapper, GcsimWeaponMapper } from "./mappers";
import { RotationTemplateRepository } from "./rotation-templates";
import type { SimulationBuildSnapshot, TeamCandidate } from "./types";

export class UnsupportedGcsimInputError extends Error {
  constructor(readonly code: "unsupportedCharacter" | "unsupportedWeapon" | "unsupportedArtifact" | "incompleteBuild") {
    super(code);
  }
}

export class GcsimConfigGenerator {
  constructor(
    private readonly characters = new GcsimCharacterMapper(),
    private readonly weapons = new GcsimWeaponMapper(),
    private readonly artifacts = new GcsimArtifactMapper(),
    private readonly rotations = new RotationTemplateRepository(),
  ) {}

  generate(input: {
    candidate: TeamCandidate;
    builds: SimulationBuildSnapshot[];
    iterations: number;
    durationSeconds: number;
    enemy: "single" | "multiple";
  }): { config: string; rotationConfidence: "high" | "medium" | "low"; rotationVersion: string } {
    const byId = new Map(input.builds.map((build) => [build.characterId, build]));
    const keys = input.candidate.members.map((id) => {
      const key = this.characters.map(id);
      if (!key) throw new UnsupportedGcsimInputError("unsupportedCharacter");
      return key;
    });
    const lines = [`options iteration=${input.iterations} duration=${input.durationSeconds} workers=1 frame_defaults=human;`, "energy every interval=480,720 amount=1;"];
    for (let index = 0; index < input.candidate.members.length; index += 1) {
      const id = input.candidate.members[index];
      const build = byId.get(id);
      if (!build?.talents || !build.weapon) throw new UnsupportedGcsimInputError("incompleteBuild");
      const key = keys[index];
      const weaponKey = this.weapons.map(build.weapon.weaponId);
      if (!weaponKey) throw new UnsupportedGcsimInputError("unsupportedWeapon");
      const maxLevel = ascensionCap(build.ascension);
      const weaponMaxLevel = ascensionCap(build.weapon.ascension);
      if (build.level > maxLevel || build.weapon.level > weaponMaxLevel) throw new UnsupportedGcsimInputError("incompleteBuild");
      lines.push(`${key} char lvl=${build.level}/${maxLevel} cons=${build.constellation} talent=${build.talents.normal},${build.talents.skill},${build.talents.burst};`);
      lines.push(`${key} add weapon="${weaponKey}" refine=${build.weapon.refinement} lvl=${build.weapon.level}/${weaponMaxLevel};`);
      for (const set of build.artifacts?.sets ?? []) {
        const setKey = this.artifacts.map(set.setId);
        if (!setKey) throw new UnsupportedGcsimInputError("unsupportedArtifact");
        lines.push(`${key} add set="${setKey}" count=${set.count};`);
      }
      const stats = renderStats(build.artifacts?.stats ?? {});
      if (stats) lines.push(`${key} add stats ${stats};`);
    }
    lines.push("target lvl=100 resist=0.1 pos=0,0 radius=2;");
    if (input.enemy === "multiple") {
      lines.push("target lvl=100 resist=0.1 pos=0,2.5 radius=2;");
      lines.push("target lvl=100 resist=0.1 pos=0,-2.5 radius=2;");
    }
    const attackerKey = this.characters.map(input.candidate.attackerId);
    if (!attackerKey) throw new UnsupportedGcsimInputError("unsupportedCharacter");
    lines.push(`active ${attackerKey};`);
    const rotation = this.rotations.select(input.candidate);
    lines.push(rotation.render(keys, attackerKey));
    return { config: `${lines.join("\n")}\n`, rotationConfidence: rotation.confidence, rotationVersion: rotation.version };
  }
}

function ascensionCap(ascension: number): number {
  return [20, 40, 50, 60, 70, 80, 90][ascension] ?? 20;
}

const STAT_KEYS: Readonly<Record<string, string>> = {
  hpFlat: "hp", hpPercent: "hp%", atkFlat: "atk", atkPercent: "atk%", defFlat: "def", defPercent: "def%",
  critRate: "cr", critDamage: "cd", energyRecharge: "er", elementalMastery: "em", anemoDamageBonus: "anemo%",
  cryoDamageBonus: "cryo%", dendroDamageBonus: "dendro%", electroDamageBonus: "electro%", geoDamageBonus: "geo%",
  hydroDamageBonus: "hydro%", pyroDamageBonus: "pyro%", physicalDamageBonus: "physical%",
};

function renderStats(stats: object): string {
  const values = stats as Record<string, number | undefined>;
  return Object.entries(STAT_KEYS)
    .filter(([key]) => values[key] !== undefined)
    .map(([key, gcsimKey]) => `${gcsimKey}=${formatStat(key, values[key]!)}`)
    .join(" ");
}

function formatStat(key: string, value: number): string {
  const decimal = key.endsWith("Percent") || key.includes("crit") || key === "energyRecharge" || key.endsWith("DamageBonus");
  return String(decimal ? value / 100 : value);
}
