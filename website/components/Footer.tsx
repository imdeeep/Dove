import Image from "next/image";
import Link from "next/link";
import { footerNavLinks, siteConfig } from "@/lib/site-config";
import { CreatorLink } from "./ui/CreatorLink";
import { DownloadButton } from "./ui/DownloadButton";

function FooterLink({
  href,
  children,
  external,
  accent,
}: {
  href: string;
  children: React.ReactNode;
  external?: boolean;
  accent?: boolean;
}) {
  const className = [
    "inline-block text-[14px] tracking-[-0.01em] transition-colors duration-200",
    accent
      ? "font-medium text-primary hover:text-primary-focus"
      : "text-ink-muted hover:text-ink",
  ].join(" ");

  if (external || href.startsWith("http") || href.startsWith("mailto:")) {
    return (
      <a
        href={href}
        className={className}
        target={href.startsWith("http") ? "_blank" : undefined}
        rel={href.startsWith("http") ? "noopener noreferrer" : undefined}
      >
        {children}
      </a>
    );
  }

  return (
    <Link href={href} className={className}>
      {children}
    </Link>
  );
}

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 16 16" fill="currentColor" aria-hidden>
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.18.82.63-.18 1.29-.27 1.96-.27.67 0 1.33.09 1.96.27 1.51-1.04 2.18-.82 2.18-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z" />
    </svg>
  );
}

export function Footer() {
  const year = new Date().getFullYear();

  return (
    <footer className="border-t border-hairline-light bg-canvas">
      <div className="mx-auto max-w-[980px] px-6 py-14 md:px-8 md:py-16">
        <div className="grid gap-12 md:grid-cols-[minmax(0,1.25fr)_minmax(0,1fr)_minmax(0,1fr)] md:gap-10 lg:gap-16">
          <div className="max-w-sm">
            <Link href="/" className="nav-brand inline-flex items-center gap-2">
              <Image
                src="/dove-menubar.png"
                alt=""
                width={22}
                height={22}
                className="logo-invert h-[22px] w-[22px] object-contain"
              />
              <span className="text-[16px] font-semibold tracking-[-0.02em] text-ink">Dove</span>
            </Link>

            <p className="mt-3 font-serif text-[16px] italic leading-snug text-ink-muted">
              {siteConfig.tagline}
            </p>

            <p className="mt-4 text-[13px] leading-relaxed text-ink-muted">
              Built by <CreatorLink />
              <span className="text-ink-muted/45"> · </span>
              Made for Mac
            </p>

            <div className="mt-6 flex flex-wrap items-center gap-2">
              <DownloadButton label="Download" className="min-h-11 px-4 py-2 text-[14px] sm:min-h-9" />
              <a
                href={siteConfig.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                aria-label="GitHub"
                className="inline-flex h-9 w-9 items-center justify-center rounded-full border border-hairline-light bg-canvas-elevated text-ink-muted shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-colors hover:text-ink"
              >
                <GitHubIcon className="h-4 w-4" />
              </a>
              <span className="rounded-full border border-hairline-light bg-canvas-elevated px-2.5 py-1 font-mono text-[10px] text-ink-muted">
                {siteConfig.version}
              </span>
            </div>
          </div>

          <div className="md:border-l md:border-hairline-light/70 md:pl-10 lg:pl-14">
            <p className="section-label mb-4">Product</p>
            <ul className="grid gap-2 sm:grid-cols-2 md:grid-cols-1">
              {footerNavLinks.map((link) => (
                <li key={link.href}>
                  <FooterLink href={link.href}>{link.label}</FooterLink>
                </li>
              ))}
              <li>
                <FooterLink href="/privacy">Privacy Policy</FooterLink>
              </li>
            </ul>
          </div>

          <div className="md:border-l md:border-hairline-light/70 md:pl-10 lg:pl-14">
            <p className="section-label mb-4">Contact</p>
            <ul className="space-y-2.5">
              <li>
                <FooterLink href={`mailto:${siteConfig.supportEmail}`} accent>
                  {siteConfig.supportEmail}
                </FooterLink>
              </li>
              <li>
                <FooterLink href={siteConfig.githubUrl} external>
                  GitHub · Issues
                </FooterLink>
              </li>
              <li>
                <FooterLink href="#contact">Get in touch</FooterLink>
              </li>
            </ul>
            <p className="mt-5 max-w-[220px] text-[12px] leading-relaxed text-ink-muted/80">
              Open source. No account. Local speech on your Mac.
            </p>
          </div>
        </div>
      </div>

      <div className="border-t border-hairline-light/80 bg-canvas/60">
        <div className="mx-auto flex max-w-[980px] flex-col items-start justify-between gap-2 px-6 py-4 text-[11px] tracking-[0.02em] text-ink-muted md:flex-row md:items-center md:px-8">
          <p>
            © {year} <CreatorLink /> · Dove is open source
          </p>
          <p className="text-ink-muted/65">Local speech. Your keys. Any app.</p>
        </div>
      </div>
    </footer>
  );
}
