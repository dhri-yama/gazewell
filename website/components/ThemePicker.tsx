"use client";

import { THEMES } from "@/lib/themes";
import { setTheme, useTheme } from "./use-theme";

/** Seven small dots in the header; each shows its own accent colour on its own backdrop. */
export function ThemeDots({ className = "flex" }: { className?: string }) {
  const current = useTheme();
  return (
    <div role="group" aria-label="Theme" className={`${className} items-center gap-1.5`}>
      {THEMES.map((t) => (
        <button
          key={t.id}
          type="button"
          onClick={() => setTheme(t.id)}
          aria-label={`${t.name} theme`}
          aria-pressed={current === t.id}
          title={t.name}
          className={`theme-${t.id} dot h-[18px] w-[18px] rounded-full border border-ink/30 transition-transform hover:scale-110 aria-pressed:ring-2 aria-pressed:ring-ink aria-pressed:ring-offset-2 aria-pressed:ring-offset-bg`}
        />
      ))}
    </div>
  );
}

/** Seven vertical bands that behave like paint chips: the chosen one opens up and the whole page takes its colours. */
export function ThemeBands() {
  const current = useTheme();
  return (
    <div role="group" aria-label="Choose a theme" className="band-row flex h-[560px] flex-col gap-2 md:h-[460px] md:flex-row">
      {THEMES.map((t) => (
        <button
          key={t.id}
          type="button"
          data-id={t.id}
          onClick={() => setTheme(t.id)}
          aria-pressed={current === t.id}
          className={`theme-${t.id} band paint relative min-h-0 min-w-0 overflow-hidden rounded-[22px] border border-ink/15 text-left`}
        >
          <span className="band-name font-display text-lg font-semibold">{t.name}</span>
          <span className="band-detail">
            <span className="font-display text-3xl font-semibold md:text-4xl">{t.name}</span>
            <span className="mt-2 block max-w-[28ch] text-base opacity-85">{t.scene}</span>
          </span>
        </button>
      ))}
    </div>
  );
}
