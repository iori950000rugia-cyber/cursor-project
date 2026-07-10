"use client";

import {
  createContext,
  useCallback,
  useContext,
  useMemo,
  type ReactNode,
} from "react";
import {
  aggregateBookmarkEntries,
  isMaterialBookmarked,
  removeBookmarkEntry,
  removeBookmarksByMaterialId,
  toggleSingleBookmark,
  upsertBookmarkBatch,
} from "@/lib/bookmark-storage";
import {
  useBookmarkEntriesMutation,
  useBookmarkEntriesSnapshot,
} from "@/lib/bookmark-store";
import type {
  AggregatedMaterialBookmark,
  MaterialBookmarkEntry,
} from "@/types/bookmark";

interface MaterialBookmarkContextValue {
  entries: MaterialBookmarkEntry[];
  aggregated: AggregatedMaterialBookmark[];
  addBatch: (batch: MaterialBookmarkEntry[]) => void;
  toggleEntry: (entry: MaterialBookmarkEntry) => void;
  removeByMaterialId: (materialId: string) => void;
  removeEntry: (id: string) => void;
  isBookmarked: (sourceKey: string, materialId: string) => boolean;
  clearAll: () => void;
}

const MaterialBookmarkContext =
  createContext<MaterialBookmarkContextValue | null>(null);

export function MaterialBookmarkProvider({ children }: { children: ReactNode }) {
  const entries = useBookmarkEntriesSnapshot();
  const mutateEntries = useBookmarkEntriesMutation();

  const aggregated = useMemo(
    () => aggregateBookmarkEntries(entries),
    [entries],
  );

  const addBatch = useCallback(
    (batch: MaterialBookmarkEntry[]) => {
      mutateEntries((prev) => upsertBookmarkBatch(prev, batch));
    },
    [mutateEntries],
  );

  const toggleEntry = useCallback(
    (entry: MaterialBookmarkEntry) => {
      mutateEntries((prev) => toggleSingleBookmark(prev, entry));
    },
    [mutateEntries],
  );

  const removeByMaterialId = useCallback(
    (materialId: string) => {
      mutateEntries((prev) => removeBookmarksByMaterialId(prev, materialId));
    },
    [mutateEntries],
  );

  const removeEntry = useCallback(
    (id: string) => {
      mutateEntries((prev) => removeBookmarkEntry(prev, id));
    },
    [mutateEntries],
  );

  const isBookmarked = useCallback(
    (sourceKey: string, materialId: string) =>
      isMaterialBookmarked(entries, sourceKey, materialId),
    [entries],
  );

  const clearAll = useCallback(() => {
    mutateEntries(() => []);
  }, [mutateEntries]);

  const value = useMemo(
    () => ({
      entries,
      aggregated,
      addBatch,
      toggleEntry,
      removeByMaterialId,
      removeEntry,
      isBookmarked,
      clearAll,
    }),
    [
      entries,
      aggregated,
      addBatch,
      toggleEntry,
      removeByMaterialId,
      removeEntry,
      isBookmarked,
      clearAll,
    ],
  );

  return (
    <MaterialBookmarkContext.Provider value={value}>
      {children}
    </MaterialBookmarkContext.Provider>
  );
}

export function useMaterialBookmarks(): MaterialBookmarkContextValue {
  const ctx = useContext(MaterialBookmarkContext);
  if (!ctx) {
    throw new Error(
      "useMaterialBookmarks must be used within MaterialBookmarkProvider",
    );
  }
  return ctx;
}
