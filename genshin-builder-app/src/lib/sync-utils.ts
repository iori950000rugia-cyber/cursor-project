/**
 * 同期時の API 呼び出しを抑えるヘルパー
 */

/** Prisma の notIn に空配列を渡すと例外になるためガードする */
export function idsForNotIn(ids: string[]): string[] | undefined {
  return ids.length > 0 ? ids : undefined;
}
