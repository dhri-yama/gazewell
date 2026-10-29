import type { NextConfig } from "next";

// Static export: the site is plain HTML/CSS/JS in `out/`, hostable anywhere.
// Set NEXT_PUBLIC_BASE_PATH (e.g. "/gazewell") when serving from a sub-path such as GitHub Pages.
const basePath = process.env.NEXT_PUBLIC_BASE_PATH || undefined;

const nextConfig: NextConfig = {
  output: "export",
  basePath,
  images: { unoptimized: true },
  turbopack: {
    rules: {
      "*.css": {
        loaders: ["@tailwindcss/turbopack"],
        as: "*.css",
      },
    },
  },
};

export default nextConfig;
