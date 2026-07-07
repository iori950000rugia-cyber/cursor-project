import type { StatPromote } from "@/lib/api/amber-details";
import type { PromoteStageData } from "@/lib/api/upgrade-types";

/** DB同期の突破データとAPI詳細の addProps をマージする */
export function mergePromotesWithApiStats(
  dbPromotes: PromoteStageData[],
  apiPromotes: StatPromote[],
): StatPromote[] {
  if (dbPromotes.length === 0) return apiPromotes;

  return dbPromotes.map((p) => {
    const fromApi = apiPromotes.find((d) => d.promoteLevel === p.promoteLevel);
    return {
      promoteLevel: p.promoteLevel,
      unlockMaxLevel: p.unlockMaxLevel,
      costItems: p.costItems,
      coinCost: p.coinCost,
      requiredPlayerLevel: p.requiredPlayerLevel ?? fromApi?.requiredPlayerLevel,
      addProps: fromApi?.addProps ?? {},
    };
  });
}
