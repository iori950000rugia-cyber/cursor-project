/** ブックマーク素材の materialId（モラ用） */
export const MORA_MATERIAL_ID = "__mora__";

export const BOOKMARK_STORAGE_KEY = "gb_material_bookmarks";

/** ブックマーク元キャラクター（ホーム表示用） */
export interface BookmarkCharacterSource {
  characterId: string;
  characterName: string;
  characterIconUrl: string | null;
  characterEmoji?: string;
}

/** 個別ブックマークエントリ（localStorage） */
export interface MaterialBookmarkEntry {
  /** `${sourceKey}:${materialId}` */
  id: string;
  /** 同一育成範囲を識別（上書き用） */
  sourceKey: string;
  sourceLabel: string;
  materialId: string;
  name: string;
  count: number;
  iconUrl: string | null;
  /** ブックマーク元キャラ（旧データ互換のため optional） */
  characterId?: string;
  characterName?: string;
  characterIconUrl?: string | null;
  characterEmoji?: string;
  addedAt: number;
}

/** ホーム表示用（materialId ごとに合算） */
export interface AggregatedMaterialBookmark {
  materialId: string;
  name: string;
  count: number;
  iconUrl: string | null;
  isMora: boolean;
  sourceLabels: string[];
  characters: BookmarkCharacterSource[];
}

export interface RequirementLine {
  materialId: string;
  name: string;
  count: number;
  iconUrl?: string | null;
  isMora?: boolean;
}

export type CultivationKind = "character-level" | "weapon-level" | "talent";

export interface CultivationBookmarkContext {
  kind: CultivationKind;
  /** キャラID / 武器ID / talent key */
  targetId: string;
  targetName: string;
  /** 天賦のみ: スキル種別ラベル */
  subLabel?: string;
  /** ブックマーク元キャラ（ホームのアイコン表示用） */
  character: BookmarkCharacterSource;
}
