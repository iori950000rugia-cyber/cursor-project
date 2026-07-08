"use client";

import { MaterialBookmarkProvider } from "@/contexts/MaterialBookmarkContext";
import type { ReactNode } from "react";

export default function BookmarkProvider({ children }: { children: ReactNode }) {
  return <MaterialBookmarkProvider>{children}</MaterialBookmarkProvider>;
}
