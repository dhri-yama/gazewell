# Gazewell website

The marketing page for Gazewell: Next.js (App Router) and Tailwind CSS, exported as a static site. It uses the app's own themes, and picking one re-themes the whole page.

```sh
cd website
npm install
npm run dev      # http://localhost:3000
npm run build    # static site in out/
```

- **Version and download link** come from `../VERSION`, read at build time, so rebuild the site after cutting a release.
- **Themes** are CSS variables in `app/globals.css` (`[data-theme="…"]`). The picker sets `data-theme` on `<html>` and saves it in `localStorage`; an inline script in `app/layout.tsx` restores it before first paint.
- **Images** are in `public/images`. Regenerate the break-screen and reminder renders with `Gazewell --snapshot <folder>` from the app.
- **Hosting:** upload `out/` to any static host. For a sub-path such as GitHub Pages, build with `NEXT_PUBLIC_BASE_PATH=/gazewell npm run build`.

This folder is not part of the macOS app. `bundle.sh` and `dmg.sh` build only the Swift sources, so nothing in here ends up in `Gazewell.app` or the DMG.
