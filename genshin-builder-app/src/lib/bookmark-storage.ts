import type {
  AggregatedMaterialBookmark,
  BookmarkCharacterSource,
  MaterialBookmarkEntry,
} from "@/types/bookmark";
import { BOOKMARK_STORAGE_KEY, MORA_MATERIAL_ID } from "@/types/bookmark";

function entryToCharacterSource(
  entry: MaterialBookmarkEntry,
): BookmarkCharacterSource | null {
  if (!entry.characterId) return null;
  return {
    characterId: entry.characterId,
    characterName: entry.characterName ?? "キャラ",
    characterIconUrl: entry.characterIconUrl ?? null,
    characterEmoji: entry.characterEmoji,
  };
}

function mergeCharacterSources(
  target: BookmarkCharacterSource[],
  source: BookmarkCharacterSource,
): void {
  if (target.some((c) => c.characterId === source.characterId)) return;
  target.push(source);
}

function isBrowser(): boolean {
  return typeof window !== "undefined";
}

export function loadBookmarkEntries(): MaterialBookmarkEntry[] {
  if (!isBrowser()) return [];
  try {
    const raw = localStorage.getItem(BOOKMARK_STORAGE_KEY);
    if (!raw) return [];
    const parsed = JSON.parse(raw) as MaterialBookmarkEntry[];
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function saveBookmarkEntries(entries: MaterialBookmarkEntry[]): void {
  if (!isBrowser()) return;
  localStorage.setItem(BOOKMARK_STORAGE_KEY, JSON.stringify(entries));
}

export function makeBookmarkId(sourceKey: string, materialId: string): string {
  return `${sourceKey}:${materialId}`;
}

/** materialId ごとに数量を合算 */
export function aggregateBookmarkEntries(
  entries: MaterialBookmarkEntry[],
): AggregatedMaterialBookmark[] {
  const map = new Map<string, AggregatedMaterialBookmark>();

  for (const entry of entries) {
    const character = entryToCharacterSource(entry);
    const existing = map.get(entry.materialId);
    if (existing) {
      existing.count += entry.count;
      if (!existing.sourceLabels.includes(entry.sourceLabel)) {
        existing.sourceLabels.push(entry.sourceLabel);
      }
      if (!existing.iconUrl && entry.iconUrl) {
        existing.iconUrl = entry.iconUrl;
      }
      if (character) {
        mergeCharacterSources(existing.characters, character);
      }
    } else {
      map.set(entry.materialId, {
        materialId: entry.materialId,
        name: entry.name,
        count: entry.count,
        iconUrl: entry.iconUrl,
        isMora: entry.materialId === MORA_MATERIAL_ID,
        sourceLabels: [entry.sourceLabel],
        characters: character ? [character] : [],
      });
    }
  }

  return [...map.values()].sort((a, b) => {
    if (a.isMora) return 1;
    if (b.isMora) return -1;
    return a.name.localeCompare(b.name, "ja");
  });
}

/** 同一 sourceKey の既存エントリを置き換えて追加 */
export function upsertBookmarkBatch(
  entries: MaterialBookmarkEntry[],
  batch: MaterialBookmarkEntry[],
): MaterialBookmarkEntry[] {
  if (batch.length === 0) return entries;
  const sourceKeys = new Set(batch.map((b) => b.sourceKey));
  const filtered = entries.filter((e) => !sourceKeys.has(e.sourceKey));
  return [...filtered, ...batch];
}

export function removeBookmarksByMaterialId(
  entries: MaterialBookmarkEntry[],
  materialId: string,
): MaterialBookmarkEntry[] {
  return entries.filter((e) => e.materialId !== materialId);
}

export function removeBookmarkEntry(
  entries: MaterialBookmarkEntry[],
  id: string,
): MaterialBookmarkEntry[] {
  return entries.filter((e) => e.id !== id);
}

export function toggleSingleBookmark(
  entries: MaterialBookmarkEntry[],
  entry: MaterialBookmarkEntry,
): MaterialBookmarkEntry[] {
  const existing = entries.find((e) => e.id === entry.id);
  if (existing) {
    return removeBookmarkEntry(entries, entry.id);
  }
  return [...entries, entry];
}

export function isMaterialBookmarked(
  entries: MaterialBookmarkEntry[],
  sourceKey: string,
  materialId: string,
): boolean {
  return entries.some(
    (e) => e.sourceKey === sourceKey && e.materialId === materialId,
  );
}
