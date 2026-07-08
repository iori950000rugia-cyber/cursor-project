#!/usr/bin/env node
/**
 * Agent ターン終了時: コード変更があれば Memory 追記を自動トリガーする。
 * followup_message で次ターンを起動（loop_limit: 2）。
 */
import { existsSync, unlinkSync } from "fs";
import { join } from "path";

async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  return Buffer.concat(chunks).toString("utf8");
}

function noop() {
  process.stdout.write("{}\n");
  process.exit(0);
}

async function main() {
  const raw = await readStdin();
  let input = {};
  try {
    input = raw ? JSON.parse(raw) : {};
  } catch {
    noop();
  }

  const flagPath = join(
    process.cwd(),
    "genshin-builder-app",
    ".cursor",
    ".memory-pending",
  );

  if (input.status !== "completed") {
    noop();
  }

  const loopCount = Number(input.loop_count ?? 0);

  if (loopCount >= 1) {
    if (existsSync(flagPath)) {
      try {
        unlinkSync(flagPath);
      } catch {
        /* ignore */
      }
    }
    noop();
  }

  if (!existsSync(flagPath)) {
    noop();
  }

  const prompt =
    "[自動保存] このセッションで行ったコード変更の要点を genshin-builder-app/docs/AGENT_MEMORY.md の先頭（テンプレート直後）に追記してください。会話全文は不要。追記のみ。完了したら「Memory 更新完了」とだけ返答してください。";

  process.stdout.write(JSON.stringify({ followup_message: prompt }) + "\n");
  process.exit(0);
}

main().catch(() => noop());
