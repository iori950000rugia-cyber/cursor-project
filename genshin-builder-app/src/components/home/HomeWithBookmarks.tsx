"use client";

import type { ReactNode } from "react";
import BookmarkMaterialsSidebar from "@/components/bookmark/BookmarkMaterialsSidebar";

/** ホーム画面: メイン + ブックマークサイドバー */
export default function HomeWithBookmarks({ children }: { children: ReactNode }) {
  return (
    <div className="grid gap-8 lg:grid-cols-[1fr_280px] lg:items-start">
      <div className="min-w-0 space-y-8">{children}</div>
      <BookmarkMaterialsSidebar />
    </div>
  );
}
