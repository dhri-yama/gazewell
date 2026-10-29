"use client";

import { useSyncExternalStore } from "react";
import { THEME_KEY, THEMES, type ThemeId } from "@/lib/themes";

function subscribe(onChange: () => void) {
  const observer = new MutationObserver(onChange);
  observer.observe(document.documentElement, { attributes: true, attributeFilter: ["data-theme"] });
  return () => observer.disconnect();
}

const read = () => (document.documentElement.dataset.theme as ThemeId | undefined) ?? "forest";

/** The active theme. The server snapshot is "forest", which matches the static HTML, so hydration never mismatches. */
export function useTheme(): ThemeId {
  return useSyncExternalStore(subscribe, read, () => "forest");
}

export function setTheme(id: ThemeId) {
  if (!THEMES.some((t) => t.id === id)) return;
  const apply = () => {
    document.documentElement.dataset.theme = id;
    try {
      localStorage.setItem(THEME_KEY, id);
    } catch {}
  };
  const doc = document as Document & { startViewTransition?: (cb: () => void) => unknown };
  if (doc.startViewTransition && !matchMedia("(prefers-reduced-motion: reduce)").matches) doc.startViewTransition(apply);
  else apply();
}
