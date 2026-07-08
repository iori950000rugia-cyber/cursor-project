<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# Genshin Builder — Agent Entry Point

**コード変更前に必読（順番どおり）:**

1. [`docs/AGENT_MEMORY.md`](./docs/AGENT_MEMORY.md) — 最新セッションの決定事項・未完了タスク
2. [`AI_AGENT_RULES.md`](./AI_AGENT_RULES.md) — 禁止事項・変更前手順・影響範囲の説明義務
3. [`ARCHITECTURE.md`](./ARCHITECTURE.md) — レイヤー・データフロー・API 利用
4. [`DEVELOPMENT_GUIDE.md`](./DEVELOPMENT_GUIDE.md) — 命名・フォルダ・実装規約

## クイックリファレンス

- **マスタ読取:** `src/lib/repository/*`
- **マスタ同期:** `src/lib/sync.ts`, `src/lib/sync-upgrade.ts`
- **ユーザー保存:** `src/lib/actions/progress.ts`
- **外部 API:** `src/lib/api/`（Project Amber / gi.yatta.moe）
- **詳細 UI:** `src/components/character/detail/DetailEditor.tsx`

## 鉄則

- 既存設計を確認してから変更する
- 大規模変更前に影響範囲を説明する
- 依頼範囲外のリファクタを混ぜない
- Client から Prisma / 外部 API を直接呼ばない
