import { readFile } from "fs/promises";
import path from "path";
import { NextResponse } from "next/server";

type VersionManifest = {
  version?: string;
  dmgFileName?: string;
  dmgSizeBytes?: number;
};

type GitHubReleaseAsset = {
  name: string;
  browser_download_url: string;
  size?: number;
};

type GitHubRelease = {
  tag_name?: string;
  assets?: GitHubReleaseAsset[];
};

type DmgAsset = {
  url: string;
  fileName: string;
  sizeBytes?: number;
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

function githubHeaders(): Record<string, string> {
  const headers: Record<string, string> = {
    Accept: "application/vnd.github+json",
    "User-Agent": "Dove-Website-Download",
  };
  const token = process.env.GITHUB_TOKEN?.trim();
  if (token) headers.Authorization = `Bearer ${token}`;
  return headers;
}

async function headContentLength(url: string): Promise<number | undefined> {
  try {
    const response = await fetch(url, { method: "HEAD", redirect: "follow" });
    const value = response.headers.get("content-length");
    if (!value) return undefined;
    const parsed = Number.parseInt(value, 10);
    return Number.isFinite(parsed) && parsed > 0 ? parsed : undefined;
  } catch {
    return undefined;
  }
}

async function resolveDmgAsset(): Promise<DmgAsset | null> {
  const envUrl = process.env.NEXT_PUBLIC_DOWNLOAD_URL?.trim();
  if (envUrl) {
    const fileName = envUrl.split("/").pop() ?? "Dove.dmg";
    const sizeBytes = await headContentLength(envUrl);
    return { url: envUrl, fileName, sizeBytes };
  }

  const githubUrl = process.env.NEXT_PUBLIC_GITHUB_URL?.trim();
  if (!githubUrl || githubUrl === "#") return null;

  const repoPath = githubRepoPath(githubUrl);
  const manifest = await readVersionManifest();

  try {
    const response = await fetch(`https://api.github.com/repos/${repoPath}/releases/latest`, {
      headers: githubHeaders(),
      next: { revalidate: 300 },
    });

    if (response.ok) {
      const release = (await response.json()) as GitHubRelease;
      const dmg = release.assets?.find((asset) => asset.name.endsWith(".dmg"));
      if (dmg?.browser_download_url) {
        return {
          url: dmg.browser_download_url,
          fileName: dmg.name,
          sizeBytes: dmg.size,
        };
      }

      if (release.tag_name) {
        const version = release.tag_name.replace(/^v/, "");
        const fileName = `Dove-${version}.dmg`;
        const url = releaseAssetUrl(githubUrl, release.tag_name, fileName);
        return {
          url,
          fileName,
          sizeBytes: manifest?.dmgSizeBytes ?? (await headContentLength(url)),
        };
      }
    }
  } catch {
    // Fall through to version.json
  }

  if (manifest?.version) {
    const fileName = manifest.dmgFileName ?? `Dove-${manifest.version}.dmg`;
    const url = releaseAssetUrl(githubUrl, manifest.version, fileName);
    return {
      url,
      fileName,
      sizeBytes: manifest.dmgSizeBytes ?? (await headContentLength(url)),
    };
  }

  return null;
}

/** Streams the .dmg so the browser downloads immediately — no GitHub release page. */
export async function GET() {
  const asset = await resolveDmgAsset();
  if (!asset) {
    return NextResponse.redirect("/", 302);
  }

  const { url, fileName } = asset;
  let sizeBytes = asset.sizeBytes;

  try {
    const upstream = await fetch(url, { redirect: "follow" });
    if (!upstream.ok || !upstream.body) {
      return NextResponse.redirect(url, 302);
    }

    if (!sizeBytes) {
      const fromUpstream = upstream.headers.get("content-length");
      if (fromUpstream) {
        sizeBytes = Number.parseInt(fromUpstream, 10);
      }
    }
    if (!sizeBytes) {
      sizeBytes = await headContentLength(url);
    }

    const responseHeaders: Record<string, string> = {
      "Content-Type": "application/octet-stream",
      "Content-Disposition": `attachment; filename="${fileName}"`,
      "Cache-Control": "public, max-age=300",
      "Accept-Ranges": "bytes",
    };

    if (sizeBytes && sizeBytes > 0) {
      responseHeaders["Content-Length"] = String(sizeBytes);
    }

    return new NextResponse(upstream.body, { headers: responseHeaders });
  } catch {
    return NextResponse.redirect(url, 302);
  }
}

export const runtime = "nodejs";
export const maxDuration = 60;
