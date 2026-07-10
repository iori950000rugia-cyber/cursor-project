import { describe, expect, it } from "vitest";
import {
  clampInt,
  getNextStageRequirements,
  snapToLevelMark,
  type PromoteStage,
} from "@/lib/level-progression";
import { CHARACTER_EXP_BETWEEN_MARKS } from "@/lib/level-config";
import { getWeaponExpBetweenMarks } from "@/lib/weapon-exp";
import { getRangeLevelRequirements } from "@/lib/material-requirements";
import { MORA_MATERIAL_ID } from "@/types/bookmark";

describe("clampInt / snapToLevelMark", () => {
  it("clampInt bounds", () => {
    expect(clampInt(5.7, 1, 10)).toBe(6);
    expect(clampInt("bad", 1, 10)).toBe(1);
    expect(clampInt(100, 1, 90)).toBe(90);
  });

  it("snapToLevelMark picks nearest mark", () => {
    expect(snapToLevelMark(22)).toBe(20);
    expect(snapToLevelMark(28)).toBe(30);
    expect(snapToLevelMark(90)).toBe(90);
  });
});

describe("getNextStageRequirements", () => {
  it("returns exp books for character level segment", () => {
    const promotes: PromoteStage[] = [
      {
        promoteLevel: 1,
        unlockMaxLevel: 20,
        costItems: { "100001": 1 },
        coinCost: 20_000,
      },
    ];

    const stage = getNextStageRequirements(1, promotes, "character", 5);
    expect(stage).not.toBeNull();
    expect(stage!.fromLevel).toBe(1);
    expect(stage!.toLevel).toBe(20);
    expect(stage!.expTotal).toBe(CHARACTER_EXP_BETWEEN_MARKS["1-20"]);
    expect(stage!.levelUpMaterials.length).toBeGreaterThan(0);
    expect(stage!.levelUpMaterials[0].materialId).toBe("104002");
  });
});

describe("getWeaponExpBetweenMarks", () => {
  it("5-star weapon exp table", () => {
    expect(getWeaponExpBetweenMarks(1, 20, 5)).toBe(121_550);
    expect(getWeaponExpBetweenMarks(80, 90, 5)).toBe(3_714_775);
  });
});

describe("getRangeLevelRequirements", () => {
  it("aggregates mora as __mora__", () => {
    const lines = getRangeLevelRequirements(1, 20, [], "character");
    expect(lines.some((l) => l.materialId === MORA_MATERIAL_ID)).toBe(true);
    const mora = lines.find((l) => l.isMora);
    expect(mora?.count).toBeGreaterThan(0);
  });

  it("empty when to <= from", () => {
    expect(getRangeLevelRequirements(50, 40, [], "character")).toEqual([]);
  });
});
