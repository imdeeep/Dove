import { NextResponse } from "next/server";

export async function GET() {
  const directUrl = process.env.NEXT_PUBLIC_DOWNLOAD_URL;
  if (directUrl) {
    return NextResponse.redirect(directUrl, 302);
  }

  const githubUrl = process.env.NEXT_PUBLIC_GITHUB_URL;
  if (githubUrl && githubUrl !== "#") {
    try {
      const repoPath = githubUrl.replace("https://github.com/", "").replace(/\/$/, "");
      const response = await fetch(
        `https://api.github.com/repos/${repoPath}/releases/latest`,
        {
          headers: { Accept: "application/vnd.github+json" },
          next: { revalidate: 300 },
        },
      );

      if (response.ok) {
        const release = (await response.json()) as {
          assets?: { name: string; browser_download_url: string }[];
        };
        const dmg = release.assets?.find((asset) => asset.name.endsWith(".dmg"));
        if (dmg) {
          return NextResponse.redirect(dmg.browser_download_url, 302);
        }
      }

      return NextResponse.redirect(`${githubUrl}/releases/latest`, 302);
    } catch {
      return NextResponse.redirect(`${githubUrl}/releases/latest`, 302);
    }
  }

  return NextResponse.redirect("/", 302);
}
