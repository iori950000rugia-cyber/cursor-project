const CHARACTER_KEYS: Readonly<Record<string, string>> = {
  "10000023": "xiangling",
  "10000025": "xingqiu",
  "10000030": "zhongli",
  "10000031": "fischl",
  "10000032": "bennett",
  "10000047": "kazuha",
  "10000054": "kokomi",
  "10000055": "gorou",
  "10000056": "kujousara",
  "10000065": "kukishinobu",
  "10000070": "nilou",
  "10000073": "nahida",
  "10000076": "faruzan",
  "10000082": "baizhu",
  "10000087": "neuvillette",
  "10000089": "furina",
  "10000090": "chevreuse",
};

const WEAPON_KEYS: Readonly<Record<string, string>> = {
  "11401": "favoniussword",
  "11511": "keyofkhajnisut",
  "11513": "splendoroftranquilwaters",
  "12401": "favoniusgreatsword",
  "13407": "favoniuslance",
  "14401": "favoniuscodex",
  "14514": "tomeoftheeternalflow",
  "15401": "favoniuswarbow",
};

const ARTIFACT_KEYS: Readonly<Record<string, string>> = {
  "15025": "deepwoodmemories",
  "15030": "vourukashasglow",
  "15031": "marechausseehunter",
  "15032": "goldentroupe",
};

export class GcsimCharacterMapper {
  map(characterId: string): string | null {
    return CHARACTER_KEYS[characterId] ?? null;
  }
}

export class GcsimWeaponMapper {
  map(weaponId: string): string | null {
    return WEAPON_KEYS[weaponId] ?? null;
  }
}

export class GcsimArtifactMapper {
  map(artifactSetId: string): string | null {
    return ARTIFACT_KEYS[artifactSetId] ?? null;
  }
}
