"use client";

import Image from "next/image";
import type { BookmarkCharacterSource } from "@/types/bookmark";

/** ホーム用: ブックマーク元キャラのアイコン（複数可） */
export default function BookmarkSourceAvatars({
  characters,
  size = 28,
}: {
  characters: BookmarkCharacterSource[];
  size?: number;
}) {
  if (characters.length === 0) return null;

  const visible = characters.slice(0, 3);
  const overflow = characters.length - visible.length;

  return (
    <div className="flex shrink-0 -space-x-1.5">
      {visible.map((character) => (
        <div
          key={character.characterId}
          title={character.characterName}
          className="overflow-hidden rounded-full border border-white/20 bg-[#151d2a]"
          style={{ width: size, height: size }}
        >
          {character.characterIconUrl ? (
            <Image
              src={character.characterIconUrl}
              alt={character.characterName}
              width={size}
              height={size}
              className="size-full object-cover"
              unoptimized
            />
          ) : (
            <span
              className="flex size-full items-center justify-center text-gray-400"
              style={{ fontSize: size * 0.45 }}
            >
              {character.characterEmoji ?? "❔"}
            </span>
          )}
        </div>
      ))}
      {overflow > 0 && (
        <div
          className="flex items-center justify-center rounded-full border border-white/20 bg-[#1e2a3a] text-[9px] text-gray-400"
          style={{ width: size, height: size }}
          title={`他 ${overflow} キャラ`}
        >
          +{overflow}
        </div>
      )}
    </div>
  );
}
