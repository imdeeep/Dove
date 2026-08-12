# Deploying the Dove website

The marketing site lives in `website/` and is deployed to **[dove.imdeeep.in](https://dove.imdeeep.in)** (Vercel). It serves the landing page, redirects `/download` to the latest `.dmg`, and hosts `/version.json` for in-app update checks.

---

## Vercel environment variables

Set these in **Vercel → Project → Settings → Environment Variables** (Production, Preview, and Development):

| Variable | Required | Example | Purpose |
|----------|----------|---------|---------|
| `NEXT_PUBLIC_SITE_URL` | ✅ | `https://dove.imdeeep.in` | Canonical URL for SEO, sitemap, Open Graph |
| `NEXT_PUBLIC_GITHUB_URL` | ✅ | `https://github.com/imdeeep/Dove` | GitHub links on site; `/download` uses GitHub API to find latest `.dmg` |
| `NEXT_PUBLIC_LINKEDIN_URL` | Optional | `https://www.linkedin.com/in/mandeep7yadav` | Creator link in footer |
| `NEXT_PUBLIC_DOWNLOAD_URL` | Optional | *(leave unset)* | Pin a specific DMG URL; normally `/download` streams the latest release automatically |
| `GITHUB_TOKEN` | Optional | *(unset)* | Server-only GitHub PAT — avoids API rate limits on Vercel when resolving latest release |

### Recommended production setup

```env
NEXT_PUBLIC_SITE_URL=https://dove.imdeeep.in
NEXT_PUBLIC_GITHUB_URL=https://github.com/imdeeep/Dove
NEXT_PUBLIC_LINKEDIN_URL=https://www.linkedin.com/in/mandeep7yadav
```

**Leave `NEXT_PUBLIC_DOWNLOAD_URL` unset.** `/download` fetches the latest `.dmg` from GitHub and **streams it to the browser** — users get a one-click download without visiting GitHub.

---

## Local development

```bash
cd website
cp .env.example .env.local
npm install
npm run dev
```

Edit `.env.local` if you need different URLs locally. Defaults in code fall back to production URLs where noted in `.env.example`.

---

## After a macOS release

1. Ensure `website/public/version.json` matches the app version (bumped by `scripts/release.sh`):

```json
{
  "version": "1.0.0",
  "build": "1",
  "downloadUrl": "https://dove.imdeeep.in/download",
  "releaseNotesUrl": "https://github.com/imdeeep/Dove/releases/latest"
}
```

2. Commit and push (or merge) to the branch Vercel deploys from (usually `main`).

3. Verify after deploy:
   - [https://dove.imdeeep.in](https://dove.imdeeep.in)
   - [https://dove.imdeeep.in/version.json](https://dove.imdeeep.in/version.json)
   - [https://dove.imdeeep.in/download](https://dove.imdeeep.in/download) → should redirect to the latest `.dmg` on GitHub

4. In the macOS app: **Check for Updates** should report up to date (or offer the new version if you bumped the version).

---

## How `/download` works

1. Resolves the latest `.dmg` URL (GitHub API → fallback to `public/version.json` + release naming).
2. **Streams the file** to the browser with `Content-Disposition: attachment` — one-click download, no GitHub page.
3. Optional `NEXT_PUBLIC_DOWNLOAD_URL` pins a specific asset URL instead of “latest”.
4. Optional server-only `GITHUB_TOKEN` helps GitHub API rate limits on Vercel.

Users stay on `dove.imdeeep.in/download`; the file saves as `Dove-1.0.0.dmg` (or whatever the release asset is named).

---

## Related

- [website/README.md](../website/README.md) — Local dev and routes
- [release.md](./release.md) — Building and publishing the macOS app
- [docs/README.md](./README.md) — Documentation index
