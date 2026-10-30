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
- **Hosting:** `out/` is plain static files, so any static host works. For a sub-path such as GitHub Pages, build with `NEXT_PUBLIC_BASE_PATH=/gazewell npm run build`.
- **`public/_headers`** sets caching and security headers on Cloudflare Pages.

## Deploying to Cloudflare Pages
Every push to `main` builds the site and deploys it through [`.github/workflows/website.yml`](../.github/workflows/website.yml). It needs two repository secrets, set once:

1. In Cloudflare, go to **My Profile → API Tokens → Create Token → Create Custom Token**, give it the permission **Account → Cloudflare Pages → Edit**, and copy the token.
2. Copy your **Account ID** from the Workers & Pages page of the dashboard.
3. Add both as secrets (each command prompts for the value, so nothing lands in your shell history):

   ```sh
   gh secret set CLOUDFLARE_API_TOKEN
   gh secret set CLOUDFLARE_ACCOUNT_ID
   ```

4. Push to `main`, or run **Actions → Deploy website → Run workflow**. The first run creates the Pages project and prints the `*.pages.dev` address.

Until the secrets exist, the workflow runs, shows a warning and deploys nothing. The Pages project is named `gazewell` (so `gazewell.pages.dev`); if that name is taken, set a repository variable `CLOUDFLARE_PAGES_PROJECT` to another name. Add a custom domain later under the project's **Custom domains** tab.

This folder is not part of the macOS app. `bundle.sh` and `dmg.sh` build only the Swift sources, so nothing in here ends up in `Gazewell.app` or the DMG.
