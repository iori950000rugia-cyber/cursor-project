"use client";

import { useMemo, useState } from "react";
import type { MaterialInfo } from "@/lib/repository/materials";
import {
  buildBookmarkEntries,
  makeRangeSourceKey,
  makeRangeSourceLabel,
} from "@/lib/bookmark-utils";
import type {
  CultivationBookmarkContext,
  RequirementLine,
} from "@/types/bookmark";
import { useMaterialBookmarks } from "@/contexts/MaterialBookmarkContext";
import BookmarkIconButton, { BookmarkDialogShell } from "./BookmarkIconButton";
import MaterialRowWithBookmark from "./MaterialRowWithBookmark";

/**
 * 育成範囲選択ダイアログ + スライダー横のブックマークボタン
 */
export default function CultivationBookmarkButton({
  ctx,
  marks,
  max,
  currentLevel,
  getRequirements,
  materialLookup,
}: {
  ctx: CultivationBookmarkContext;
  marks: readonly number[];
  max: number;
  currentLevel: number;
  getRequirements: (from: number, to: number) => RequirementLine[];
  materialLookup: MaterialInfo[];
}) {
  const { addBatch, toggleEntry, isBookmarked } = useMaterialBookmarks();
  const [open, setOpen] = useState(false);
  const [fromLevel, setFromLevel] = useState(currentLevel);
  const [toLevel, setToLevel] = useState(max);
  const [showResults, setShowResults] = useState(false);

  const availableMarks = useMemo(
    () => marks.filter((m) => m <= max),
    [marks, max],
  );

  const requirements = useMemo(() => {
    if (!showResults) return [];
    return getRequirements(fromLevel, toLevel);
  }, [showResults, fromLevel, toLevel, getRequirements]);

  const rangeSourceKey = makeRangeSourceKey(ctx, fromLevel, toLevel);
  const rangeSourceLabel = makeRangeSourceLabel(ctx, fromLevel, toLevel);

  function openDialog() {
    setFromLevel(currentLevel);
    setToLevel(max);
    setShowResults(false);
    setOpen(true);
  }

  function handleShowRequirements() {
    if (toLevel <= fromLevel) return;
    setShowResults(true);
  }

  function handleBookmarkAll() {
    if (requirements.length === 0) return;
    addBatch(
      buildBookmarkEntries(
        requirements,
        rangeSourceKey,
        rangeSourceLabel,
        materialLookup,
        ctx.character,
      ),
    );
  }

  const selectClass =
    "rounded-lg border border-white/10 bg-[#151d2a] px-2 py-1.5 text-sm text-gray-200 focus:border-accent focus:outline-none";

  return (
    <>
      <BookmarkIconButton
        active={false}
        onClick={openDialog}
        title="育成範囲をブックマーク"
        className="size-7"
      />

      <BookmarkDialogShell
        open={open}
        onClose={() => setOpen(false)}
        title="育成範囲の必要素材"
      >
        <p className="mb-3 text-xs text-gray-400">{ctx.targetName}</p>

        <div className="space-y-3">
          <div>
            <label htmlFor="bookmark-from" className="mb-1 block text-xs text-gray-400">
              開始レベル
            </label>
            <select
              id="bookmark-from"
              value={fromLevel}
              onChange={(e) => {
                setFromLevel(Number(e.target.value));
                setShowResults(false);
              }}
              className={`w-full ${selectClass}`}
            >
              {availableMarks.map((m) => (
                <option key={m} value={m}>
                  {m}
                </option>
              ))}
            </select>
          </div>

          <div>
            <label htmlFor="bookmark-to" className="mb-1 block text-xs text-gray-400">
              終了レベル
            </label>
            <select
              id="bookmark-to"
              value={toLevel}
              onChange={(e) => {
                setToLevel(Number(e.target.value));
                setShowResults(false);
              }}
              className={`w-full ${selectClass}`}
            >
              {availableMarks.map((m) => (
                <option key={m} value={m} disabled={m <= fromLevel}>
                  {m}
                </option>
              ))}
            </select>
          </div>

          <button
            type="button"
            onClick={handleShowRequirements}
            disabled={toLevel <= fromLevel}
            className="w-full rounded-lg bg-gradient-to-r from-[#d4a853] to-[#b8923f] px-4 py-2 text-sm font-medium text-gray-900 disabled:cursor-not-allowed disabled:opacity-40"
          >
            必要素材を表示
          </button>
        </div>

        {showResults && (
          <div className="mt-4 space-y-3 border-t border-white/10 pt-4">
            <div className="flex items-center justify-between gap-2">
              <p className="text-xs font-bold text-accent">
                Lv.{fromLevel} → Lv.{toLevel}
              </p>
              {requirements.length > 0 && (
                <button
                  type="button"
                  onClick={handleBookmarkAll}
                  className="text-xs text-accent hover:underline"
                >
                  すべてブックマーク
                </button>
              )}
            </div>

            {requirements.length === 0 ? (
              <p className="text-xs text-gray-500">追加素材は不要です</p>
            ) : (
              <ul className="space-y-1.5">
                {requirements.map((line) => {
                  const entry = buildBookmarkEntries(
                    [line],
                    rangeSourceKey,
                    rangeSourceLabel,
                    materialLookup,
                    ctx.character,
                  )[0];
                  return (
                    <MaterialRowWithBookmark
                      key={line.materialId}
                      materialId={line.materialId}
                      name={line.name}
                      iconUrl={entry.iconUrl}
                      count={line.count}
                      isMora={line.isMora}
                      bookmarked={isBookmarked(
                        rangeSourceKey,
                        line.materialId,
                      )}
                      onToggleBookmark={() => toggleEntry(entry)}
                    />
                  );
                })}
              </ul>
            )}
          </div>
        )}
      </BookmarkDialogShell>
    </>
  );
}
