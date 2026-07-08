"use client";

import { useCallback, useEffect, useRef, useState, type ReactNode } from "react";
import { levelToVisualRatio, snapToMarks } from "@/lib/level-progression";

/**
 * 原神風マークスライダー（汎用）
 * キャラ/武器レベル・天賦レベルなど、目盛りスナップ式の入力に使う。
 */
export default function MarkSlider({
  marks,
  max,
  displayMax,
  value,
  onChange,
  label,
  id,
  showFutureZone = false,
  futureHint,
  displayEndMark,
  compactTicks = false,
  headerExtra,
}: {
  marks: readonly number[];
  max: number;
  displayMax: number;
  value: number;
  onChange: (level: number) => void;
  label: string;
  id: string;
  showFutureZone?: boolean;
  futureHint?: string;
  /** 表示上の右端目盛り（例: 100）。marks に含まれない場合に使用 */
  displayEndMark?: number;
  /** 天賦など目盛りが多い場合にラベルを間引く */
  compactTicks?: boolean;
  /** Lv表記横に表示する追加UI（ブックマークボタン等） */
  headerExtra?: ReactNode;
}) {
  const trackRef = useRef<HTMLDivElement>(null);
  const [dragging, setDragging] = useState(false);
  const snapped = snapToMarks(value, marks, max);
  const [displayLevel, setDisplayLevel] = useState(snapped);

  const fillRatio = levelToVisualRatio(snapped, displayMax);
  const playableEndRatio = levelToVisualRatio(max, displayMax);

  useEffect(() => {
    setDisplayLevel(snapped);
  }, [snapped]);

  const pickFromClientX = useCallback(
    (clientX: number) => {
      const track = trackRef.current;
      if (!track) return;
      const rect = track.getBoundingClientRect();
      const ratio = Math.min(1, Math.max(0, (clientX - rect.left) / rect.width));
      const rawLevel = Math.round(ratio * displayMax);
      const level = snapToMarks(rawLevel, marks, max);
      setDisplayLevel(level);
      onChange(level);
    },
    [displayMax, marks, max, onChange],
  );

  const onPointerDown = (e: React.PointerEvent) => {
    setDragging(true);
    (e.target as HTMLElement).setPointerCapture?.(e.pointerId);
    pickFromClientX(e.clientX);
  };

  const onPointerMove = (e: React.PointerEvent) => {
    if (!dragging) return;
    pickFromClientX(e.clientX);
  };

  const onPointerUp = () => setDragging(false);

  const markIndex = marks.indexOf(snapped);
  const tickMarks = displayEndMark
    ? [...marks, ...(marks.includes(displayEndMark) ? [] : [displayEndMark])]
    : [...marks];

  return (
    <div className="space-y-3">
      <div className="flex items-end justify-between gap-3">
        <label htmlFor={id} className="text-xs text-gray-400">
          {label}
        </label>
        <div className="flex items-center gap-2">
          <p
            className={`font-serif text-2xl font-bold tabular-nums transition-all duration-200 ${
              dragging ? "scale-110 text-accent" : "text-amber-100"
            }`}
            aria-live="polite"
          >
            Lv.{displayLevel}
          </p>
          {headerExtra}
        </div>
      </div>

      <div
        id={id}
        role="slider"
        aria-valuemin={marks[0]}
        aria-valuemax={max}
        aria-valuenow={snapped}
        aria-label={label}
        tabIndex={0}
        className="relative select-none px-1 pt-2 pb-8 outline-none focus-visible:ring-2 focus-visible:ring-accent/60 rounded-lg"
        onKeyDown={(e) => {
          if (e.key === "ArrowRight" || e.key === "ArrowUp") {
            e.preventDefault();
            if (markIndex >= 0 && markIndex < marks.length - 1) {
              onChange(marks[Math.min(markIndex + 1, marks.length - 1)]);
            }
          } else if (e.key === "ArrowLeft" || e.key === "ArrowDown") {
            e.preventDefault();
            if (markIndex > 0) onChange(marks[markIndex - 1]);
          }
        }}
      >
        <div
          ref={trackRef}
          className="relative h-3 cursor-pointer rounded-full bg-[#0d1118] shadow-inner"
          onPointerDown={onPointerDown}
          onPointerMove={onPointerMove}
          onPointerUp={onPointerUp}
          onPointerCancel={onPointerUp}
        >
          {showFutureZone && (
            <div
              className="absolute inset-y-0 rounded-r-full border-l border-dashed border-violet-400/30 bg-gradient-to-r from-transparent to-violet-950/40"
              style={{ left: `${playableEndRatio * 100}%`, right: 0 }}
              aria-hidden
            />
          )}

          <div
            className="absolute inset-y-0 left-0 rounded-full bg-gradient-to-r from-[#8b6914] via-accent to-[#f0d890] shadow-[0_0_12px_rgba(212,168,83,0.45)] transition-[width] duration-200 ease-out"
            style={{ width: `${fillRatio * 100}%` }}
          />

          {showFutureZone && fillRatio > playableEndRatio && (
            <div
              className="absolute inset-y-0 rounded-r-full bg-violet-500/25 transition-[width] duration-200"
              style={{
                left: `${playableEndRatio * 100}%`,
                width: `${(fillRatio - playableEndRatio) * 100}%`,
              }}
            />
          )}

          <div
            className={`absolute top-1/2 z-10 size-5 -translate-x-1/2 -translate-y-1/2 rounded-full border-2 border-[#f0d890] bg-accent shadow-[0_0_10px_rgba(212,168,83,0.8)] transition-transform duration-150 ${
              dragging ? "scale-125" : "scale-100"
            }`}
            style={{ left: `${fillRatio * 100}%` }}
          />
        </div>

        <div className="pointer-events-none absolute inset-x-1 bottom-0 h-8">
          {tickMarks.map((mark) => {
            const ratio = levelToVisualRatio(mark, displayMax);
            const isActive = mark === snapped;
            const isFuture = mark > max;
            const showLabel =
              !compactTicks || isActive || mark === marks[0] || mark === max;
            return (
              <div
                key={mark}
                className="absolute bottom-0 -translate-x-1/2"
                style={{ left: `${ratio * 100}%` }}
              >
                <div
                  className={`mx-auto w-px transition-all duration-200 ${
                    isActive
                      ? "h-4 bg-accent"
                      : isFuture
                        ? "h-2 bg-violet-400/40"
                        : "h-2.5 bg-white/25"
                  }`}
                />
                {showLabel && (
                  <span
                    className={`mt-0.5 block text-center text-[10px] leading-none transition-colors duration-200 ${
                      isActive
                        ? "font-bold text-accent"
                        : isFuture
                          ? "text-violet-400/50"
                          : "text-gray-500"
                    }`}
                  >
                    {mark}
                  </span>
                )}
              </div>
            );
          })}
        </div>
      </div>

      {showFutureZone && futureHint && (
        <p className="text-[10px] text-violet-400/60">{futureHint}</p>
      )}
    </div>
  );
}
