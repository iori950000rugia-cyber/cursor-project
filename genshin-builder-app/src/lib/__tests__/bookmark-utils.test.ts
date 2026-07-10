import { describe, expect, it } from "vitest";
import {
  buildBookmarkEntries,
  makeItemSourceKey,
  makeRangeSourceKey,
} from "@/lib/bookmark-utils";
import { isMaterialBookmarked, makeBookmarkId } from "@/lib/bookmark-storage";
import type {
  CultivationBookmarkContext,
  MaterialBookmarkEntry,
} from "@/types/bookmark";

const character = {
  characterId: "hu-tao",
  characterName: "胡桃",
  characterIconUrl: "https://example.com/hu-tao.png",
};

const ctx: CultivationBookmarkContext = {
  kind: "character-level",
  targetId: "hu-tao",
  targetName: "胡桃",
  character,
};

describe("makeRangeSourceKey", () => {
  it("matches mobile format", () => {
    expect(makeRangeSourceKey(ctx, 1, 90)).toBe(
      "range:character-level:hu-tao:1-90",
    );
  });

  it("includes subLabel for talent", () => {
    const talentCtx: CultivationBookmarkContext = {
      kind: "talent",
      targetId: "hu-tao",
      targetName: "胡桃",
      subLabel: "元素スキル",
      character,
    };
    expect(makeRangeSourceKey(talentCtx, 1, 10)).toBe(
      "range:talent:hu-tao:元素スキル:1-10",
    );
  });
});

describe("makeItemSourceKey", () => {
  it("matches mobile format for next scope", () => {
    expect(makeItemSourceKey(ctx, "next", "100001")).toBe(
      "item:character-level:hu-tao:next:100001",
    );
  });
});

describe("makeBookmarkId", () => {
  it("concatenates sourceKey and materialId", () => {
    expect(
      makeBookmarkId("item:character-level:hu-tao:next:100001", "100001"),
    ).toBe("item:character-level:hu-tao:next:100001:100001");
  });
});

describe("buildBookmarkEntries", () => {
  it("creates entries with character fields", () => {
    const entries = buildBookmarkEntries(
      [
        {
          materialId: "100001",
          name: "テスト素材",
          count: 3,
        },
      ],
      "range:character-level:hu-tao:1-90",
      "胡桃 キャラLv 1→90",
      [],
      character,
    );
    expect(entries).toHaveLength(1);
    expect(entries[0].id).toBe("range:character-level:hu-tao:1-90:100001");
    expect(entries[0].characterId).toBe("hu-tao");
    expect(entries[0].count).toBe(3);
  });
});

describe("isMaterialBookmarked", () => {
  it("detects existing entry by sourceKey and materialId", () => {
    const entry: MaterialBookmarkEntry = {
      id: "item:character-level:hu-tao:next:100001:100001",
      sourceKey: "item:character-level:hu-tao:next:100001",
      sourceLabel: "label",
      materialId: "100001",
      name: "素材",
      count: 1,
      iconUrl: null,
      addedAt: 0,
    };
    expect(isMaterialBookmarked([entry], entry.sourceKey, "100001")).toBe(true);
    expect(isMaterialBookmarked([entry], entry.sourceKey, "999")).toBe(false);
  });
});
