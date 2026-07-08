import type { MaterialInfo } from "@/lib/repository/materials";
import { makeBookmarkId } from "@/lib/bookmark-storage";
import type {
  CultivationBookmarkContext,
  MaterialBookmarkEntry,
  RequirementLine,
} from "@/types/bookmark";

export function makeRangeSourceKey(
  ctx: CultivationBookmarkContext,
  from: number,
  to: number,
): string {
  const sub = ctx.subLabel ? `:${ctx.subLabel}` : "";
  return `range:${ctx.kind}:${ctx.targetId}${sub}:${from}-${to}`;
}

export function makeItemSourceKey(
  ctx: CultivationBookmarkContext,
  scope: "next" | "stage",
  materialId: string,
): string {
  const sub = ctx.subLabel ? `:${ctx.subLabel}` : "";
  return `item:${ctx.kind}:${ctx.targetId}${sub}:${scope}:${materialId}`;
}

export function makeRangeSourceLabel(
  ctx: CultivationBookmarkContext,
  from: number,
  to: number,
): string {
  const prefix =
    ctx.kind === "character-level"
      ? "キャラLv"
      : ctx.kind === "weapon-level"
        ? "武器Lv"
        : "天賦";
  const sub = ctx.subLabel ? ` ${ctx.subLabel}` : "";
  return `${ctx.targetName} ${prefix}${sub} ${from}→${to}`;
}

export function makeItemSourceLabel(
  ctx: CultivationBookmarkContext,
  materialName: string,
): string {
  const prefix =
    ctx.kind === "character-level"
      ? "キャラ"
      : ctx.kind === "weapon-level"
        ? "武器"
        : "天賦";
  const sub = ctx.subLabel ? ` ${ctx.subLabel}` : "";
  return `${ctx.targetName} ${prefix}${sub} · ${materialName}`;
}

function entryCharacterFields(
  character: CultivationBookmarkContext["character"],
): Pick<
  MaterialBookmarkEntry,
  "characterId" | "characterName" | "characterIconUrl" | "characterEmoji"
> {
  return {
    characterId: character.characterId,
    characterName: character.characterName,
    characterIconUrl: character.characterIconUrl,
    characterEmoji: character.characterEmoji,
  };
}

export function buildBookmarkEntries(
  lines: RequirementLine[],
  sourceKey: string,
  sourceLabel: string,
  materialLookup: MaterialInfo[],
  character: CultivationBookmarkContext["character"],
): MaterialBookmarkEntry[] {
  const map = new Map(materialLookup.map((m) => [m.id, m]));
  const now = Date.now();
  const characterFields = entryCharacterFields(character);

  return lines.map((line) => ({
    id: makeBookmarkId(sourceKey, line.materialId),
    sourceKey,
    sourceLabel,
    materialId: line.materialId,
    name: line.name,
    count: line.count,
    iconUrl:
      line.iconUrl ??
      (line.isMora ? null : (map.get(line.materialId)?.iconUrl ?? null)),
    ...characterFields,
    addedAt: now,
  }));
}

export function formatMora(value: number): string {
  return value.toLocaleString("ja-JP");
}
