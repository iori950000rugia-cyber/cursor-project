"use client";

import Image from "next/image";
import { useMemo } from "react";
import { formatMora } from "@/lib/bookmark-utils";
import { MORA_MATERIAL_ID } from "@/types/bookmark";
import BookmarkIconButton from "./BookmarkIconButton";

/** 素材行 + ブックマークボタン */
export default function MaterialRowWithBookmark({
  materialId,
  name,
  iconUrl,
  count,
  isMora = materialId === MORA_MATERIAL_ID,
  bookmarked = false,
  onToggleBookmark,
}: {
  materialId: string;
  name: string;
  iconUrl: string | null;
  count: number;
  isMora?: boolean;
  bookmarked?: boolean;
  onToggleBookmark?: () => void;
}) {
  const countLabel = useMemo(
    () => (isMora ? formatMora(count) : String(count)),
    [isMora, count],
  );

  return (
    <li className="flex items-center gap-2 text-sm text-gray-200">
      {isMora ? (
        <span className="flex size-7 shrink-0 items-center justify-center rounded bg-[#151d2a] text-sm">
          🪙
        </span>
      ) : iconUrl ? (
        <Image
          src={iconUrl}
          alt=""
          width={28}
          height={28}
          className="shrink-0 rounded bg-[#151d2a]"
          unoptimized
        />
      ) : (
        <span className="flex size-7 shrink-0 items-center justify-center rounded bg-[#151d2a] text-[10px] text-gray-500">
          ?
        </span>
      )}
      <span className="min-w-0 flex-1 truncate">{name}</span>
      <span className="shrink-0 tabular-nums text-accent">×{countLabel}</span>
      {onToggleBookmark && (
        <BookmarkIconButton
          active={bookmarked}
          onClick={onToggleBookmark}
          title={bookmarked ? "ブックマークを解除" : "ブックマークに追加"}
          className="size-7"
        />
      )}
    </li>
  );
}
