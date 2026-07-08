"use client";

import type { ReactNode } from "react";

/** ブックマークアイコンボタン（🔖） */
export default function BookmarkIconButton({
  active = false,
  onClick,
  title,
  className = "",
}: {
  active?: boolean;
  onClick: () => void;
  title: string;
  className?: string;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      title={title}
      aria-label={title}
      aria-pressed={active}
      className={`inline-flex size-8 shrink-0 items-center justify-center rounded-lg border transition-colors ${
        active
          ? "border-accent/60 bg-accent/20 text-accent"
          : "border-white/10 bg-[#151d2a] text-gray-400 hover:border-accent/40 hover:text-accent"
      } ${className}`}
    >
      <span className="text-base leading-none" aria-hidden>
        🔖
      </span>
    </button>
  );
}

export function BookmarkDialogShell({
  open,
  onClose,
  title,
  children,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
}) {
  if (!open) return null;

  return (
    <div
      className="fixed inset-0 z-50 flex items-end justify-center bg-black/60 p-4 sm:items-center"
      role="dialog"
      aria-modal="true"
      aria-labelledby="bookmark-dialog-title"
      onClick={onClose}
    >
      <div
        className="max-h-[85vh] w-full max-w-md overflow-y-auto rounded-xl border border-white/10 bg-[#1e2a3a] p-4 shadow-xl"
        onClick={(e) => e.stopPropagation()}
      >
        <div className="mb-4 flex items-start justify-between gap-3">
          <h2 id="bookmark-dialog-title" className="text-sm font-bold text-amber-100">
            {title}
          </h2>
          <button
            type="button"
            onClick={onClose}
            className="rounded-lg px-2 py-1 text-xs text-gray-400 hover:bg-white/5 hover:text-gray-200"
          >
            閉じる
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
