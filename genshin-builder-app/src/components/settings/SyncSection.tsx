import type { SyncStatus } from "@/lib/repository/characters";
import SyncButton from "@/components/settings/SyncButton";

/** 同期の使い方と状態に応じた案内 */
export default function SyncSection({ status }: { status: SyncStatus }) {
  return (
    <div className="space-y-4">
      <SyncStatusBanner status={status} />

      <SyncButton status={status} />

      <details className="rounded-lg bg-[#151d2a] p-3 text-sm text-gray-300">
        <summary className="cursor-pointer font-medium text-gray-200">
          同期の使い分け
        </summary>
        <div className="mt-3 space-y-3 text-xs leading-relaxed text-gray-400">
          <div>
            <p className="font-medium text-accent">ゲームデータを同期（通常）</p>
            <ul className="mt-1 list-inside list-disc space-y-0.5">
              <li>キャラ・武器・素材の一覧を更新</li>
              <li>
                <strong className="text-gray-300">未登録分だけ</strong>
                突破・天賦の必要素材を取得（API 約3回＋差分）
              </li>
              <li>普段はこれだけでOK</li>
            </ul>
          </div>
          <div>
            <p className="font-medium text-gray-300">突破データを完全同期</p>
            <ul className="mt-1 list-inside list-disc space-y-0.5">
              <li>全キャラ・武器の突破データを API から再取得（数百回）</li>
              <li>
                素材数がおかしい・パッチ後に古いデータが残っているときのみ
              </li>
            </ul>
          </div>
          <div>
            <p className="font-medium text-gray-300">こんなとき</p>
            <ul className="mt-1 list-inside list-disc space-y-0.5">
              <li>初回利用 → 通常同期（初回のみ数分かかることがあります）</li>
              <li>新キャラ実装後 → 通常同期</li>
              <li>詳細画面で「突破・素材データを取得できませんでした」→ 通常同期</li>
              <li>それでも直らない → 完全同期</li>
            </ul>
          </div>
        </div>
      </details>
    </div>
  );
}

function SyncStatusBanner({ status }: { status: SyncStatus }) {
  if (status.isUnsynced) {
    return (
      <div className="rounded-lg border border-amber-400/30 bg-amber-400/10 px-3 py-2 text-sm text-amber-100">
        ゲームデータが未同期です。「ゲームデータを同期」を実行してください。
        初回は突破データの取得に数分かかることがあります。
      </div>
    );
  }

  if (status.needsInitialUpgradeSync) {
    return (
      <div className="rounded-lg border border-amber-400/30 bg-amber-400/10 px-3 py-2 text-sm text-amber-100">
        一覧は同期済みですが、突破・天賦データが未登録です。
        「ゲームデータを同期」で必要素材が取得されます（初回のみ時間がかかります）。
      </div>
    );
  }

  if (
    status.missingCharacterUpgrades > 0 ||
    status.missingWeaponUpgrades > 0
  ) {
    return (
      <div className="rounded-lg border border-amber-400/30 bg-amber-400/10 px-3 py-2 text-sm text-amber-100">
        突破データが不足しています（キャラ {status.missingCharacterUpgrades}{" "}
        件 / 武器 {status.missingWeaponUpgrades} 件）。
        「ゲームデータを同期」で不足分だけ取得できます。
      </div>
    );
  }

  if (status.upgradeComplete) {
    return (
      <div className="rounded-lg border border-emerald-400/20 bg-emerald-400/5 px-3 py-2 text-sm text-emerald-200/90">
        突破・EXPデータは揃っています。ゲーム更新後は「ゲームデータを同期」で十分です。
      </div>
    );
  }

  return null;
}
