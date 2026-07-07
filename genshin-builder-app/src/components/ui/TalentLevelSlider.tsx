"use client";

import {
  TALENT_LEVEL_DISPLAY_MAX,
  TALENT_LEVEL_MAX,
  TALENT_MARKS,
} from "@/lib/level-config";
import MarkSlider from "./MarkSlider";

/** 天賦（スキル）レベル用スライダー */
export default function TalentLevelSlider({
  value,
  onChange,
  label,
  id,
  max = TALENT_LEVEL_MAX,
}: {
  value: number;
  onChange: (level: number) => void;
  label: string;
  id: string;
  max?: number;
}) {
  const marks = TALENT_MARKS.filter((m) => m <= max);

  return (
    <MarkSlider
      marks={marks}
      max={max}
      displayMax={TALENT_LEVEL_DISPLAY_MAX}
      value={value}
      onChange={onChange}
      label={label}
      id={id}
      showFutureZone={max < TALENT_LEVEL_DISPLAY_MAX}
      futureHint="Lv.11〜13 は命ノ星座+3 対応予定（未実装）"
      compactTicks
    />
  );
}
