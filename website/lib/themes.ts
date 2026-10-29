/** The app's themes. Colours live in globals.css (`[data-theme="…"]`, `.theme-…`); this is names and copy. */
export const THEMES = [
  { id: "forest", name: "Forest", scene: "A tree grows while the break runs." },
  { id: "earth", name: "Earth", scene: "Stones stack into a cairn." },
  { id: "ocean", name: "Ocean", scene: "Water rises inside a circle." },
  { id: "air", name: "Air", scene: "Dandelion seeds blow away on the wind." },
  { id: "night", name: "Night sky", scene: "A moon crosses a field of stars." },
  { id: "medito", name: "Medito", scene: "A gold ring fills as you breathe in and out." },
  { id: "mono", name: "Mono focus", scene: "One large, quiet title and nothing else." },
] as const;

export type ThemeId = (typeof THEMES)[number]["id"];
export const THEME_KEY = "gazewell-theme";
