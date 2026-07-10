/**
 * マスタ同期 API（POST /api/sync）の認証
 *
 * - 設定画面の手動同期は Server Action 経由（認証不要・同一オリジン）
 * - Vercel Cron 等の外部トリガーは Bearer トークンで保護
 */

/** POST /api/sync のリクエストが認可されているか */
export function verifySyncApiSecret(request: Request): boolean {
  const secret = process.env.SYNC_API_SECRET;

  if (!secret) {
    // 本番ではシークレット未設定時は API 経由の同期を拒否
    return process.env.NODE_ENV !== "production";
  }

  const auth = request.headers.get("authorization");
  return auth === `Bearer ${secret}`;
}
