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
Cloudflare builds and deploys the site itself whenever `main` changes (Git integration, no GitHub workflow). Set it up once in the dashboard under **Workers & Pages → Create → Pages → Import an existing Git repository**, choose `dhri-yama/gazewell`, then fill in:

| Field | Value |
| --- | --- |
| Production branch | `main` |
| Framework preset | Next.js (Static HTML Export) |
| Build command | `npm run build` |
| Build output directory | `out` |
| Root directory (advanced) → Path | `website` |
| Environment variables | none needed |

After **Save and Deploy**, every push to `main` triggers a new build and deployment, and the project shows its `*.pages.dev` address.

- **Node version:** [`.node-version`](.node-version) (22) lives in the root directory, which Pages reads. If a build ever picks the wrong Node, add an environment variable `NODE_VERSION` = `22`.
- **`wrangler.jsonc`:** this is the Cloudflare Workers (static assets) config. Pages ignores it for production (it may print a warning about a missing `pages_build_output_dir`). It is there for moving to Workers later. Delete it if a Pages build complains about it.
- **`../VERSION`:** the build reads it for the version and download link, so it needs the whole repository, which Cloudflare checks out. The root directory only sets the working folder.
- **`public/_headers`** sets caching and security headers.

Check the output locally with `npm run build`, then serve `out/`.
