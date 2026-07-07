"use client";

import Image from "next/image";
import Link from "next/link";
import { useMemo } from "react";
import type { MaterialInfo } from "@/lib/repository/materials";
import type { UpgradeDataCache } from "@/lib/repository/upgrade-data";
import {
  getAscensionStageInfos,
  getNextStageRequirements,
  type PromoteStage,
} from "@/lib/level-progression";

function formatMora(value: number): string {
  return value.toLocaleString("ja-JP");
}

function MaterialRow({
  materialId,
  name,
  iconUrl,
  count,
}: {
  materialId: string;
  name: string;
  iconUrl: string | null;
  count: number;
}) {
  return (
    <li className="flex items-center gap-2 text-sm text-gray-200">
      {iconUrl ? (
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
      <span className="shrink-0 tabular-nums text-accent">×{count}</span>
    </li>
  );
}

/**
 * レベルスライダー下の素材表示パネル
 */
export default function LevelMaterialsPanel({
  currentLevel,
  promotes,
  materials,
  kind,
  weaponRarity = 5,
  upgradeCache,
}: {
  currentLevel: number;
  promotes: PromoteStage[];
  materials: MaterialInfo[];
  kind: "character" | "weapon";
  /** 武器レベルアップEXP計算用（kind=weapon のとき） */
  weaponRarity?: number;
  /** DB同期済みのEXP・素材データ */
  upgradeCache?: UpgradeDataCache;
}) {
  const materialMap = useMemo(
    () => new Map(materials.map((m) => [m.id, m])),
    [materials],
  );

  const nextStage = useMemo(
    () =>
      getNextStageRequirements(
        currentLevel,
        promotes,
        kind,
        weaponRarity,
        upgradeCache,
      ),
    [currentLevel, promotes, kind, weaponRarity, upgradeCache],
  );

  const ascensionInfos = useMemo(
    () => getAscensionStageInfos(promotes),
    [promotes],
  );

  if (promotes.length === 0) {
    return (
      <div className="rounded-lg bg-[#151d2a] px-3 py-2 text-xs text-amber-200/80">
        <p>突破・素材データがありません。</p>
        <p className="mt-1 text-gray-500">
          <Link href="/settings" className="text-accent hover:underline">
            設定
          </Link>
          で「ゲームデータを同期」を実行してください。
        </p>
      </div>
    );
  }

  return (
    <div className="space-y-4">
      {/* 次の育成段階 */}
      {nextStage ? (
        <div className="rounded-lg bg-[#151d2a] p-3">
          <h4 className="text-xs font-bold text-accent">
            Lv.{nextStage.fromLevel} → Lv.{nextStage.toLevel} に必要な素材
          </h4>
          {nextStage.needsAscension && (
            <p className="mt-1 text-[11px] text-amber-200/70">
              突破が必要です
            </p>
          )}
          <ul className="mt-2 space-y-1.5">
            {nextStage.materials.map(({ materialId, count }) => {
              const mat = materialMap.get(materialId);
              return (
                <MaterialRow
                  key={materialId}
                  materialId={materialId}
                  name={mat?.name ?? `素材 #${materialId}`}
                  iconUrl={mat?.iconUrl ?? null}
                  count={count}
                />
              );
            })}
            {nextStage.levelUpMaterials.map(({ materialId, name, count }) => {
              const mat = materialMap.get(materialId);
              return (
                <MaterialRow
                  key={`levelup-${materialId}`}
                  materialId={materialId}
                  name={mat?.name ?? name}
                  iconUrl={mat?.iconUrl ?? null}
                  count={count}
                />
              );
            })}
            {nextStage.mora > 0 && (
              <li className="flex items-center gap-2 text-sm text-gray-200">
                <span className="flex size-7 shrink-0 items-center justify-center rounded bg-[#151d2a] text-sm">
                  🪙
                </span>
                <span className="flex-1">モラ</span>
                <span className="tabular-nums text-accent">
                  ×{formatMora(nextStage.mora)}
                </span>
              </li>
            )}
            {nextStage.materials.length === 0 &&
              nextStage.levelUpMaterials.length === 0 &&
              nextStage.mora === 0 && (
                <li className="text-xs text-gray-500">追加素材は不要です</li>
              )}
          </ul>
        </div>
      ) : (
        <div className="rounded-lg bg-[#151d2a] p-3">
          <p className="text-xs text-emerald-400/80">最大レベルに到達しています</p>
        </div>
      )}

      {/* 突破情報一覧 */}
      {ascensionInfos.length > 0 && (
        <details className="rounded-lg bg-[#151d2a] p-3">
          <summary className="cursor-pointer text-xs font-bold text-gray-300">
            突破段階ごとの必要素材
          </summary>
          <div className="mt-3 space-y-3">
            {ascensionInfos.map((info) => (
              <div
                key={info.promoteLevel}
                className="border-t border-white/5 pt-3 first:border-0 first:pt-0"
              >
                <p className="text-xs font-medium text-gray-300">
                  突破 {info.promoteLevel}（Lv.{info.level}まで）
                  {info.requiredPlayerLevel != null && (
                    <span className="ml-2 text-gray-500">
                      必要AR {info.requiredPlayerLevel}
                    </span>
                  )}
                </p>
                <ul className="mt-1.5 space-y-1">
                  {info.materials.map(({ materialId, count }) => {
                    const mat = materialMap.get(materialId);
                    return (
                      <MaterialRow
                        key={materialId}
                        materialId={materialId}
                        name={mat?.name ?? `素材 #${materialId}`}
                        iconUrl={mat?.iconUrl ?? null}
                        count={count}
                      />
                    );
                  })}
                  <li className="flex items-center gap-2 text-sm text-gray-200">
                    <span className="flex size-7 shrink-0 items-center justify-center rounded bg-[#1e2a3a] text-sm">
                      🪙
                    </span>
                    <span className="flex-1">モラ</span>
                    <span className="tabular-nums text-accent">
                      ×{formatMora(info.mora)}
                    </span>
                  </li>
                </ul>
              </div>
            ))}
          </div>
        </details>
      )}
    </div>
  );
}
