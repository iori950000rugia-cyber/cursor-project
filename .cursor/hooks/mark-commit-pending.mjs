#!/usr/bin/env node
/**
 * Agent がコードファイルを編集したら自動コミット用フラグを立てる。
 * 触ったファイルパスを `{ files: [...] }` として蓄積する。
 */
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "fs";
import { dirname, join, relative } from "path";
import { fileURLToPath } from "url";

const REPO_ROOT = join(dirname(fileURLToPath(import.meta.url)), "..", "..");
const FLAG_PATH = join(REPO_ROOT, ".cursor", ".commit-pending");

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

const SKIP_PATTERNS = [
  "docs/agent_memory.md",
  ".cursor/hooks/",
  ".cursor/.memory-pending",
  ".cursor/.commit-pending",
  "/.next/",
  "/node_modules/",
  "/.dart_tool/",
  "/build/",
  "prisma/dev.db",
  "scripts/auto-commit/",
];

const CODE_EXTENSIONS = new Set([
  "dart",
  "ts",
  "tsx",
  "js",
  "mjs",
  "json",
  "sql",
  "prisma",
  "yaml",
  "yml",
  "md",
  "mdc",
]);

function extractFilePath(input) {
  if (input.file_path) return String(input.file_path);
  const toolInput = input.tool_input ?? input.arguments ?? input.input ?? {};
  if (typeof toolInput === "string") {
    try {
      const parsed = JSON.parse(toolInput);
      return parsed.path ?? parsed.file_path ?? parsed.target_notebook ?? "";
    } catch {
      return "";
    }
  }
  return (
    toolInput.path ??
    toolInput.file_path ??
    toolInput.target_notebook ??
    ""
  );
}

/**
 * @param {string} absOrRel
 * @returns {string}
 */
function toRepoRelative(absOrRel) {
  const normalized = String(absOrRel).replace(/\\/g, "/");
  if (!normalized) return "";
  try {
    const abs = normalized.match(/^[a-zA-Z]:/) || normalized.startsWith("/")
      ? normalized
      : join(REPO_ROOT, normalized);
    return relative(REPO_ROOT, abs).replace(/\\/g, "/");
  } catch {
    return normalized;
  }
}

/**
 * @returns {{ at?: string, file?: string, files?: string[], reason?: string }}
 */
function readPending() {
  if (!existsSync(FLAG_PATH)) return {};
  try {
    const raw = readFileSync(FLAG_PATH, "utf8");
    const parsed = JSON.parse(raw);
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

async function main() {
  const raw = await readStdin();
  let input = {};
  try {
    input = raw ? JSON.parse(raw) : {};
  } catch {
    noop();
  }

  const filePathRaw = String(extractFilePath(input));
  const filePathLower = filePathRaw.replace(/\\/g, "/").toLowerCase();

  if (!filePathRaw) noop();

  if (SKIP_PATTERNS.some((p) => filePathLower.includes(p))) {
    noop();
  }

  const ext = filePathLower.split(".").pop() ?? "";
  if (!CODE_EXTENSIONS.has(ext)) {
    noop();
  }

  const rel = toRepoRelative(filePathRaw);
  if (!rel || rel.startsWith("..")) noop();

  const prev = readPending();
  const files = Array.isArray(prev.files) ? [...prev.files] : [];
  if (prev.file && !files.includes(prev.file)) {
    files.push(String(prev.file).replace(/\\/g, "/"));
  }
  if (!files.includes(rel)) {
    files.push(rel);
  }

  mkdirSync(dirname(FLAG_PATH), { recursive: true });
  writeFileSync(
    FLAG_PATH,
    JSON.stringify(
      {
        at: new Date().toISOString(),
        file: rel,
        files,
      },
      null,
      2,
    ),
  );

  noop();
}

main().catch(() => noop());
