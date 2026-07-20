export type TeamRole =
  | "mainDps"
  | "subDps"
  | "offFieldDps"
  | "buffer"
  | "debuffer"
  | "healer"
  | "shielder"
  | "battery"
  | "elementApplicator"
  | "crowdControl";

// 共通ルールを補う最小の事実レジストリ。性能値や固定チームは持たない。
const PROFILES: Readonly<Record<string, readonly TeamRole[]>> = {
  "10000020": ["mainDps"], // Razor (physical option)
  "10000023": ["offFieldDps", "elementApplicator"],
  "10000025": ["offFieldDps", "elementApplicator", "debuffer"],
  "10000030": ["shielder", "debuffer"],
  "10000031": ["offFieldDps", "battery", "elementApplicator"],
  "10000032": ["buffer", "healer", "battery"],
  "10000047": ["buffer", "debuffer", "crowdControl", "elementApplicator"],
  "10000051": ["mainDps"], // Eula (physical option)
  "10000054": ["healer", "elementApplicator"],
  "10000055": ["buffer", "battery"],
  "10000056": ["buffer", "battery"],
  "10000065": ["healer", "elementApplicator", "battery"],
  "10000070": ["elementApplicator"],
  "10000073": ["buffer", "offFieldDps", "elementApplicator"],
  "10000076": ["buffer", "battery"],
  "10000082": ["healer", "shielder", "elementApplicator"],
  "10000085": ["mainDps"], // Freminet (physical option)
  "10000089": ["buffer", "offFieldDps", "elementApplicator"],
  "10000090": ["buffer", "healer", "debuffer"],
};

export function rolesFor(characterId: string): readonly TeamRole[] {
  return PROFILES[characterId] ?? [];
}

export function hasRole(characterId: string, ...roles: TeamRole[]): boolean {
  return roles.some((role) => rolesFor(characterId).includes(role));
}

export function isKnownPhysicalAttacker(characterId: string): boolean {
  return characterId === "10000020" || characterId === "10000051" || characterId === "10000085";
}
