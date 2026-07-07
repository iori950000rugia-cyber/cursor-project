/**
 * 育成素材・突破データの正規化型（DB保存用）
 */

export interface PromoteStageData {
  promoteLevel: number;
  unlockMaxLevel: number;
  costItems: Record<string, number>;
  coinCost: number;
  requiredPlayerLevel?: number;
}

export interface TalentLevelUpgradeData {
  level: number;
  costItems: Record<string, number>;
  coinCost: number;
}

export interface TalentUpgradeData {
  kind: "normal" | "skill" | "burst";
  upgrades: TalentLevelUpgradeData[];
}

export interface CharacterUpgradeData {
  characterId: string;
  promotes: PromoteStageData[];
  talents: TalentUpgradeData[];
}

export interface WeaponUpgradeData {
  weaponId: string;
  promotes: PromoteStageData[];
  levelUpItemIds: string[];
}

export interface LevelExpSegmentData {
  id: string;
  targetType: "character" | "weapon";
  rarity: number;
  fromLevel: number;
  toLevel: number;
  expRequired: number;
  moraRequired: number;
}

export interface LevelUpMaterialData {
  materialId: string;
  name: string;
  exp: number;
  targetType: "character" | "weapon";
}
