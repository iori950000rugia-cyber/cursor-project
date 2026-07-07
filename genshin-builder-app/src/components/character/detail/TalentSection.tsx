"use client";

import Image from "next/image";
import type { TalentInfo } from "@/lib/api/amber-details";
import type { ProgressPayload } from "@/lib/actions/progress";
import { getTalentLevelMax } from "@/lib/input-limits";
import type { MaterialInfo } from "@/lib/repository/materials";
import { snapTalentLevel } from "@/lib/talent-progression";
import Accordion from "@/components/ui/Accordion";
import TalentLevelSlider from "@/components/ui/TalentLevelSlider";
import TalentMaterialsPanel from "./TalentMaterialsPanel";

type Talents = ProgressPayload["talents"];
type ActiveTalentKey = keyof Talents;

/** アクティブスキルの種類 → 育成データのキーと表示名 */
const ACTIVE_TALENTS: Array<{
  kind: "normal" | "skill" | "burst";
  key: ActiveTalentKey;
  label: string;
}> = [
  { kind: "normal", key: "normalAttack", label: "通常攻撃" },
  { kind: "skill", key: "elementalSkill", label: "元素スキル" },
  { kind: "burst", key: "elementalBurst", label: "元素爆発" },
];

/**
 * スキル・天賦セクション（アコーディオン）
 * 概要: 通常攻撃・元素スキル・元素爆発のスキル名とレベル
 * 詳細: スライダー・必要素材・スキル説明・固有天賦一覧
 */
export default function TalentSection({
  talents,
  talentInfos,
  materialLookup,
  constellation = 0,
  onChange,
}: {
  talents: Talents;
  talentInfos: TalentInfo[];
  materialLookup: MaterialInfo[];
  constellation?: number;
  onChange: (talents: Talents) => void;
}) {
  const talentMax = getTalentLevelMax(constellation);

  const infoByKind = new Map(
    talentInfos
      .filter((t) => t.kind !== "passive")
      .map((t) => [t.kind, t] as const),
  );
  const passives = talentInfos.filter((t) => t.kind === "passive");

  const summary = (
    <div className="space-y-0.5 text-sm text-gray-300">
      {ACTIVE_TALENTS.map(({ kind, key, label }) => {
        const info = infoByKind.get(kind);
        return (
          <p key={key} className="truncate">
            <span className="text-xs text-gray-500">{label}:</span>{" "}
            {info?.name ?? label}{" "}
            <span className="text-accent">Lv.{talents[key]}</span>
          </p>
        );
      })}
    </div>
  );

  return (
    <Accordion title="スキル・天賦" summary={summary}>
      <div className="space-y-4">
        {ACTIVE_TALENTS.map(({ kind, key, label }) => {
          const info = infoByKind.get(kind);
          return (
            <div key={key} className="space-y-3 rounded-lg bg-[#151d2a] p-3">
              <div className="flex items-center gap-2">
                {info?.iconUrl && (
                  <Image
                    src={info.iconUrl}
                    alt=""
                    width={32}
                    height={32}
                    className="opacity-90"
                    unoptimized
                  />
                )}
                <div>
                  <p className="text-xs text-gray-500">{label}</p>
                  <h3 className="text-sm font-bold">{info?.name ?? label}</h3>
                </div>
              </div>

              <TalentLevelSlider
                id={`talent-${key}`}
                label={`${label}レベル`}
                value={talents[key]}
                max={talentMax}
                onChange={(level) =>
                  onChange({
                    ...talents,
                    [key]: snapTalentLevel(level, talentMax),
                  })
                }
              />

              <TalentMaterialsPanel
                currentLevel={talents[key]}
                maxLevel={talentMax}
                upgrades={info?.upgrades ?? []}
                materials={materialLookup}
              />

              {info?.description && (
                <details>
                  <summary className="cursor-pointer text-xs text-accent">
                    スキル説明を表示
                  </summary>
                  <p className="mt-2 whitespace-pre-line text-xs leading-relaxed text-gray-300">
                    {info.description}
                  </p>
                </details>
              )}
            </div>
          );
        })}

        {passives.length > 0 && (
          <div>
            <h3 className="mb-2 text-sm font-bold text-gray-400">
              固有天賦・パッシブ天賦
            </h3>
            <div className="space-y-2">
              {passives.map((p) => (
                <div key={p.name} className="rounded-lg bg-[#151d2a] p-3">
                  <div className="flex items-center gap-2">
                    {p.iconUrl && (
                      <Image
                        src={p.iconUrl}
                        alt=""
                        width={24}
                        height={24}
                        className="opacity-90"
                        unoptimized
                      />
                    )}
                    <h4 className="text-sm font-bold">{p.name}</h4>
                  </div>
                  <p className="mt-1 whitespace-pre-line text-xs leading-relaxed text-gray-300">
                    {p.description}
                  </p>
                </div>
              ))}
            </div>
          </div>
        )}
      </div>
    </Accordion>
  );
}
