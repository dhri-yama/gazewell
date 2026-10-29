import { readFileSync } from "node:fs";
import { join } from "node:path";

// The app's version lives in ../VERSION (single source of truth); the site reads it at build time.
export const version = readFileSync(join(process.cwd(), "..", "VERSION"), "utf8").trim();
export const repoUrl = "https://github.com/dhri-yama/gazewell";
export const dmgUrl = `${repoUrl}/releases/download/v${version}/Gazewell-${version}.dmg`;
export const coffeeUrl = "https://buymeacoffee.com/dhriyama";
