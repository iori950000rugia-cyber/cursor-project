"use client";

/**
 * ブックマーク localStorage のクライアントストア
 *
 * useSyncExternalStore で SSR 安全に読み込み、
 * effect 内 setState による lint 違反を避ける。
 */

import { useCallback, useSyncExternalStore } from "react";
import {
  loadBookmarkEntries,
  saveBookmarkEntries,
} from "@/lib/bookmark-storage";
import type { MaterialBookmarkEntry } from "@/types/bookmark";

type Listener = () => void;

const listeners = new Set<Listener>();
let cachedEntries: MaterialBookmarkEntry[] | null = null;

function getClientSnapshot(): MaterialBookmarkEntry[] {
  cachedEntries ??= loadBookmarkEntries();
  return cachedEntries;
}

function getServerSnapshot(): MaterialBookmarkEntry[] {
  return [];
}

function subscribe(listener: Listener): () => void {
  listeners.add(listener);
  return () => listeners.delete(listener);
}

function emit(): void {
  listeners.forEach((listener) => listener());
}

export function getBookmarkEntriesSnapshot(): MaterialBookmarkEntry[] {
  if (typeof window === "undefined") return [];
  return getClientSnapshot();
}

export function setBookmarkEntriesSnapshot(
  entries: MaterialBookmarkEntry[],
): void {
  cachedEntries = entries;
  saveBookmarkEntries(entries);
  emit();
}

export function useBookmarkEntriesSnapshot(): MaterialBookmarkEntry[] {
  return useSyncExternalStore(
    subscribe,
    getClientSnapshot,
    getServerSnapshot,
  );
}

export function useBookmarkEntriesMutation() {
  return useCallback(
    (
      updater: (prev: MaterialBookmarkEntry[]) => MaterialBookmarkEntry[],
    ) => {
      setBookmarkEntriesSnapshot(updater(getBookmarkEntriesSnapshot()));
    },
    [],
  );
}
