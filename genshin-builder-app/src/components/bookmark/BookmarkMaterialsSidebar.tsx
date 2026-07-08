"use client";

import Image from "next/image";
import { formatMora } from "@/lib/bookmark-utils";
import { useMaterialBookmarks } from "@/contexts/MaterialBookmarkContext";
import BookmarkSourceAvatars from "./BookmarkSourceAvatars";

/** ホーム画面用: ブックマーク素材一覧 */
export default function BookmarkMaterialsSidebar() {
  const { aggregated, removeByMaterialId, clearAll } = useMaterialBookmarks();

  return (
    <aside className="rounded-xl border border-white/10 bg-[#1e2a3a] p-4">
      <div className="mb-3 flex items-center justify-between gap-2">
        <h2 className="text-sm font-bold text-amber-100">ブックマーク素材</h2>
        {aggregated.length > 0 && (
          <button
            type="button"
            onClick={clearAll}
            className="text-[10px] text-gray-500 hover:text-red-400"
          >
            すべて解除
          </button>
        )}
      </div>

      {aggregated.length === 0 ? (
        <p className="text-xs text-gray-500">
          キャラ詳細の🔖から素材を登録できます
        </p>
      ) : (
        <ul className="space-y-2">
          {aggregated.map((item) => (
            <li
              key={item.materialId}
              className="flex items-center gap-2 rounded-lg bg-[#151d2a] p-2"
            >
              <BookmarkSourceAvatars characters={item.characters} />
              {item.isMora ? (
                <span className="flex size-8 shrink-0 items-center justify-center rounded bg-[#1e2a3a] text-sm">
                  🪙
                </span>
              ) : item.iconUrl ? (
                <Image
                  src={item.iconUrl}
                  alt=""
                  width={32}
                  height={32}
                  className="shrink-0 rounded bg-[#1e2a3a]"
                  unoptimized
                />
              ) : (
                <span className="flex size-8 shrink-0 items-center justify-center rounded bg-[#1e2a3a] text-[10px] text-gray-500">
                  ?
                </span>
              )}
              <div className="min-w-0 flex-1">
                <p className="truncate text-sm text-gray-200">{item.name}</p>
                {item.sourceLabels.length > 0 && (
                  <p className="truncate text-[10px] text-gray-500">
                    {item.sourceLabels.slice(0, 2).join(" / ")}
                    {item.sourceLabels.length > 2 ? " …" : ""}
                  </p>
                )}
              </div>
              <div className="flex shrink-0 flex-col items-end gap-1">
                <span className="tabular-nums text-sm text-accent">
                  ×
                  {item.isMora
                    ? formatMora(item.count)
                    : item.count.toLocaleString("ja-JP")}
                </span>
                <button
                  type="button"
                  onClick={() => removeByMaterialId(item.materialId)}
                  className="text-[10px] text-gray-500 hover:text-red-400"
                  title="登録解除"
                >
                  解除
                </button>
              </div>
            </li>
          ))}
        </ul>
      )}
    </aside>
  );
}
