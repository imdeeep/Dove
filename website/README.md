# Dove website

Next.js marketing site for [Dove](https://dove.imdeeep.in) — landing page, download redirect, and `version.json` for in-app update checks.

Part of the open-source [Dove repository](../README.md). App docs: **[docs/README.md](../docs/README.md)**.

---

## Local development

```bash
cd website
npm install
cp .env.example .env.local   # set NEXT_PUBLIC_* URLs if needed
npm run dev
```

Open [http://localhost:3000](http://localhost:3000).

---

## Key routes

| Route | Purpose |
|-------|---------|
| `/` | Landing page |
| `/download` | Redirects to latest `.dmg` (GitHub Releases or configured URL) |
| `/version.json` | Version + build for `UpdateChecker` in the macOS app |
| `/privacy` | Privacy policy |

Site config: `lib/site-config.ts`. Version file: `public/version.json` (also bumped by `scripts/release.sh`).

---

## Deploy

Production: [dove.imdeeep.in](https://dove.imdeeep.in) (Vercel). After a macOS release, deploy with updated `version.json` so **Check for Updates** and `/download` stay in sync.

**Vercel env vars:** see **[docs/deploy-website.md](../docs/deploy-website.md)** and **[.env.example](./.env.example)**.

---

## Stack

Next.js App Router, TypeScript, Tailwind CSS. See `package.json` for versions.
