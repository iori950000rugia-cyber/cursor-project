"use client";

import {
  LEVEL_DISPLAY_MAX,
  LEVEL_MARKS,
  LEVEL_MAX,
} from "@/lib/level-config";
import MarkSlider from "./MarkSlider";

/** キャラ/武器用レベルスライダー */
export default function LevelSlider({
  value,
  onChange,
  label,
  id,
  showFutureZone = true,
  headerExtra,
}: {
  value: number;
  onChange: (level: number) => void;
  label: string;
  id: string;
  showFutureZone?: boolean;
  headerExtra?: React.ReactNode;
}) {
  return (
    <MarkSlider
      marks={LEVEL_MARKS}
      max={LEVEL_MAX}
      displayMax={LEVEL_DISPLAY_MAX}
      value={value}
      onChange={onChange}
      label={label}
      id={id}
      showFutureZone={showFutureZone}
      displayEndMark={100}
      futureHint="Lv.90〜100 は将来対応予定（未実装）"
      headerExtra={headerExtra}
    />
  );
}
