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

## Deploying to Cloudflare
Cloudflare builds and deploys the site itself whenever `main` changes (Git integration, no GitHub workflow). It reads two files here: [`wrangler.jsonc`](wrangler.jsonc), which serves `out/` as static assets, and [`.node-version`](.node-version), which picks Node 22.

Set it up once in the Cloudflare dashboard:

1. **Workers & Pages → Create application → Import a repository**, and choose `dhri-yama/gazewell`.
2. Set the **Worker name** to `gazewell`. It must match `name` in `wrangler.jsonc`.
3. Set the **Root directory** to `website`, the **Build command** to `npm run build`, and keep the **Deploy command** as `npx wrangler deploy`. The production branch is `main`.
4. Save and deploy. After that, every push to `main` triggers a new build and deployment, and the dashboard shows the live address.

The build reads `../VERSION` (for the version and download link), so it needs the whole repository checked out. Cloudflare does this, and only uses the root directory as the working folder.

To check the config without deploying: `npm run build && npx wrangler deploy --dry-run`.
