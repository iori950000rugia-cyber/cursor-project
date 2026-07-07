"use client";

import { useState } from "react";
import { useRouter } from "next/navigation";
import type { SyncStatus } from "@/lib/repository/characters";

type SyncState =
  | { status: "idle" }
  | { status: "loading"; mode: "incremental" | "full" }
  | { status: "done"; message: string }
  | { status: "error"; message: string };

interface SyncResponse {
  ok: boolean;
  characters?: number;
  weapons?: number;
  materials?: number;
  characterUpgrades?: number;
  weaponUpgrades?: number;
  levelExpSegments?: number;
  expMaterials?: number;
  upgradeApiCalls?: number;
  skippedCharacterUpgrades?: number;
  skippedWeaponUpgrades?: number;
  errors?: string[];
  message?: string;
}

export default function SyncButton({ status }: { status: SyncStatus }) {
  const [state, setState] = useState<SyncState>({ status: "idle" });
  const router = useRouter();

  const suggestFullSync =
    status.upgradeComplete &&
    !status.needsInitialUpgradeSync &&
    status.missingCharacterUpgrades === 0;

  async function handleSync(fullUpgrade: boolean) {
    setState({ status: "loading", mode: fullUpgrade ? "full" : "incremental" });
    try {
      const res = await fetch("/api/sync", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ fullUpgrade }),
      });
      const data: SyncResponse = await res.json();

      if (!res.ok || !data.ok) {
        const detail =
          data.errors?.join(" / ") ?? data.message ?? "不明なエラー";
        setState({ status: "error", message: `同期に失敗しました: ${detail}` });
        return;
      }

      const apiInfo =
        data.upgradeApiCalls != null
          ? ` / 突破API ${data.upgradeApiCalls}回`
          : "";

      setState({
        status: "done",
        message: `同期完了：キャラ ${data.characters} / 武器 ${data.weapons} / 素材 ${data.materials} / 突破 ${data.characterUpgrades}+${data.weaponUpgrades}${apiInfo}`,
      });
      router.refresh();
    } catch {
      setState({
        status: "error",
        message: "同期に失敗しました。ネットワーク接続を確認してください。",
      });
    }
  }

  const loading = state.status === "loading";

  return (
    <div className="space-y-3">
      <div className="flex flex-wrap gap-2">
        <button
          type="button"
          onClick={() => handleSync(false)}
          disabled={loading}
          className="rounded-lg bg-gradient-to-r from-[#d4a853] to-[#b8923f] px-5 py-2 text-sm font-medium text-gray-900 transition-transform hover:-translate-y-0.5 disabled:cursor-not-allowed disabled:opacity-50"
        >
          {state.status === "loading" && state.mode === "incremental"
            ? status.needsInitialUpgradeSync
              ? "初回同期中...（数分）"
              : "同期中..."
            : "ゲームデータを同期"}
        </button>
        {suggestFullSync && (
          <button
            type="button"
            onClick={() => handleSync(true)}
            disabled={loading}
            className="rounded-lg border border-white/20 px-4 py-2 text-sm text-gray-400 transition-colors hover:border-accent hover:text-accent disabled:cursor-not-allowed disabled:opacity-50"
          >
            {state.status === "loading" && state.mode === "full"
              ? "完全同期中...（数分）"
              : "突破データを完全同期（上級）"}
          </button>
        )}
      </div>

      {!suggestFullSync && !status.isUnsynced && (
        <p className="text-xs text-gray-500">
          完全同期ボタンは、通常同期で突破データが揃ってから表示されます。
        </p>
      )}

      {state.status === "done" && (
        <p className="text-sm text-emerald-400">{state.message}</p>
      )}
      {state.status === "error" && (
        <p className="text-sm text-red-400">{state.message}</p>
      )}
    </div>
  );
}
