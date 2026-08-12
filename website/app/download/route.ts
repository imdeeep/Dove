import { readFile } from "fs/promises";
import path from "path";
import { NextResponse } from "next/server";

type VersionManifest = {
  version?: string;
  dmgFileName?: string;
};

type GitHubRelease = {
  tag_name?: string;
  assets?: { name: string; browser_download_url: string }[];
};

async function readVersionManifest(): Promise<VersionManifest | null> {
  try {
    const versionPath = path.join(process.cwd(), "public", "version.json");
    const raw = await readFile(versionPath, "utf8");
    return JSON.parse(raw) as VersionManifest;
  } catch {
    return null;
  }
}

function githubRepoPath(githubUrl: string): string {
  return githubUrl.replace("https://github.com/", "").replace(/\/$/, "");
}

function releaseAssetUrl(githubUrl: string, tag: string, fileName: string): string {
  const base = githubUrl.replace(/\/$/, "");
  const normalizedTag = tag.startsWith("v") ? tag : `v${tag}`;
  return `${base}/releases/download/${normalizedTag}/${fileName}`;
}

async function resolveDmgUrl(): Promise<string | null> {
  const envUrl = process.env.NEXT_PUBLIC_DOWNLOAD_URL?.trim();
  if (envUrl) return envUrl;

  const githubUrl = process.env.NEXT_PUBLIC_GITHUB_URL?.trim();
  if (!githubUrl || githubUrl === "#") return null;

  const repoPath = githubRepoPath(githubUrl);
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "Dove-Website-Download",
  };
  const token = process.env.GITHUB_TOKEN?.trim();
  if (token) headers.Authorization = `Bearer ${token}`;

  try {
    const response = await fetch(`https://api.github.com/repos/${repoPath}/releases/latest`, {
      headers,
      next: { revalidate: 300 },
    });

    if (response.ok) {
      const release = (await response.json()) as GitHubRelease;
      const dmg = release.assets?.find((asset) => asset.name.endsWith(".dmg"));
      if (dmg?.browser_download_url) return dmg.browser_download_url;

      if (release.tag_name) {
        const version = release.tag_name.replace(/^v/, "");
        return releaseAssetUrl(githubUrl, release.tag_name, `Dove-${version}.dmg`);
      }
    }
  } catch {
    // Fall through to version.json
  }

  const manifest = await readVersionManifest();
  if (manifest?.version) {
    const fileName = manifest.dmgFileName ?? `Dove-${manifest.version}.dmg`;
    return releaseAssetUrl(githubUrl, manifest.version, fileName);
  }

  return null;
}

/** Streams the .dmg so the browser downloads immediately — no GitHub release page. */
export async function GET() {
  const dmgUrl = await resolveDmgUrl();
  if (!dmgUrl) {
    return NextResponse.redirect("/", 302);
  }

  const fileName = dmgUrl.split("/").pop() ?? "Dove.dmg";

  try {
    const upstream = await fetch(dmgUrl, { redirect: "follow" });
    if (!upstream.ok || !upstream.body) {
      return NextResponse.redirect(dmgUrl, 302);
    }

    const responseHeaders: Record<string, string> = {
      "Content-Type": "application/octet-stream",
      "Content-Disposition": `attachment; filename="${fileName}"`,
      "Cache-Control": "public, max-age=300",
    };

    const contentLength = upstream.headers.get("content-length");
    if (contentLength) responseHeaders["Content-Length"] = contentLength;

    return new NextResponse(upstream.body, { headers: responseHeaders });
  } catch {
    return NextResponse.redirect(dmgUrl, 302);
  }
}

// Large DMG proxy needs Node runtime (not Edge).
export const runtime = "nodejs";
export const maxDuration = 60;
