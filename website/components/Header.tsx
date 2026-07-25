"use client";

import Image from "next/image";
import Link from "next/link";
import { useEffect, useState } from "react";
import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { appear, dismiss, easeOut } from "@/lib/motion";
import { cn } from "@/lib/utils";
import { navLinks, siteConfig } from "@/lib/site-config";
import { DownloadButton } from "./ui/DownloadButton";

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 16 16" fill="currentColor" aria-hidden>
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.18.82.63-.18 1.29-.27 1.96-.27.67 0 1.33.09 1.96.27 1.51-1.04 2.18-.82 2.18-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z" />
    </svg>
  );
}

export function Header() {
  const [open, setOpen] = useState(false);
  const [scrolled, setScrolled] = useState(false);
  const [active, setActive] = useState("");
  const reduced = useReducedMotion();

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 16);
    onScroll();
    window.addEventListener("scroll", onScroll, { passive: true });
    return () => window.removeEventListener("scroll", onScroll);
  }, []);

  useEffect(() => {
    const ids = navLinks.map((l) => l.href.slice(1));
    const sections = ids
      .map((id) => document.getElementById(id))
      .filter((el): el is HTMLElement => el !== null);

    if (!sections.length) return;

    const observer = new IntersectionObserver(
      (entries) => {
        const visible = entries
          .filter((e) => e.isIntersecting)
          .sort((a, b) => b.intersectionRatio - a.intersectionRatio);
        if (visible[0]?.target.id) {
          setActive(`#${visible[0].target.id}`);
        }
      },
      { rootMargin: "-42% 0px -48% 0px", threshold: [0, 0.25, 0.5] },
    );

    sections.forEach((s) => observer.observe(s));
    return () => observer.disconnect();
  }, []);

  useEffect(() => {
    document.body.style.overflow = open ? "hidden" : "";
    return () => {
      document.body.style.overflow = "";
    };
  }, [open]);

  return (
    <header className="pointer-events-none fixed inset-x-0 top-0 z-50 px-4 pt-[max(1rem,env(safe-area-inset-top))] md:pt-[max(1.25rem,env(safe-area-inset-top))]">
      <motion.div
        initial={reduced ? false : { opacity: 0, y: -10 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ duration: appear, ease: easeOut }}
        className={cn(
          "pointer-events-auto dock mx-auto flex h-[52px] max-w-[800px] items-center justify-between px-2 md:grid md:grid-cols-[auto_1fr_auto] md:gap-1 md:px-3",
          scrolled && "dock-scrolled",
        )}
      >
        <Link href="/" className="nav-brand flex shrink-0 items-center gap-2 pl-2 md:pl-3">
          <Image
            src="/dove-menubar.png"
            alt=""
            width={22}
            height={22}
            className="logo-invert h-[22px] w-[22px] object-contain"
            priority
          />
          <span className="text-[15px] font-semibold tracking-[-0.02em] text-ink">Dove</span>
        </Link>

        <nav className="hidden items-center justify-center gap-0.5 md:flex" aria-label="Main">
          {navLinks.map((l) => {
            const isActive = active === l.href;
            return (
              <a key={l.href} href={l.href} className={cn("nav-link", isActive && "text-ink")}>
                {isActive && (
                  <motion.span
                    layoutId="nav-active-pill"
                    className="nav-link-pill"
                    transition={{ duration: reduced ? 0 : 0.25, ease: easeOut }}
                  />
                )}
                <span className="relative z-10">{l.label}</span>
              </a>
            );
          })}
        </nav>

        <div className="flex items-center justify-end gap-1 pr-1 md:pr-1.5">
          <a
            href={siteConfig.githubUrl}
            target="_blank"
            rel="noopener noreferrer"
            aria-label="Star on GitHub"
            className="hidden h-8 w-8 items-center justify-center rounded-full text-ink-muted transition-colors duration-[250ms] hover:bg-black/[0.05] hover:text-ink sm:inline-flex"
          >
            <GitHubIcon className="h-4 w-4" />
          </a>

          <span className="nav-divider hidden sm:block" aria-hidden />

          <DownloadButton
            variant="dock"
            label="Download"
            className="hidden shadow-[0_1px_3px_rgba(0,102,204,0.25)] sm:inline-flex"
          />

          <button
            type="button"
            aria-label={open ? "Close menu" : "Open menu"}
            aria-expanded={open}
            className="inline-flex h-11 w-11 items-center justify-center rounded-full text-ink transition-colors hover:bg-black/[0.05] md:hidden"
            onClick={() => setOpen((v) => !v)}
          >
            <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden>
              {open ? (
                <path d="M4 4l12 12M16 4L4 16" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
              ) : (
                <path d="M3 6h14M3 10h14M3 14h14" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
              )}
            </svg>
          </button>
        </div>
      </motion.div>

      <AnimatePresence>
        {open && (
          <>
            <motion.button
              type="button"
              aria-label="Close menu"
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              transition={{ duration: reduced ? 0 : dismiss }}
              className="pointer-events-auto fixed inset-0 z-40 bg-black/20 backdrop-blur-[2px] md:hidden"
              onClick={() => setOpen(false)}
            />
            <motion.div
              initial={reduced ? false : { opacity: 0, y: -8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={reduced ? undefined : { opacity: 0, y: -8 }}
              transition={{ duration: reduced ? 0 : dismiss, ease: easeOut }}
              className="pointer-events-auto dock-panel relative z-50 mx-auto mt-2 w-full max-w-[800px] p-2 md:hidden"
            >
              <nav aria-label="Mobile">
                {navLinks.map((l) => {
                  const isActive = active === l.href;
                  return (
                    <a
                      key={l.href}
                      href={l.href}
                      className={cn(
                        "flex min-h-11 items-center justify-between rounded-xl px-4 py-3 text-[15px] transition-colors",
                        isActive
                          ? "bg-primary/8 font-medium text-primary"
                          : "text-ink hover:bg-black/[0.04]",
                      )}
                      onClick={() => setOpen(false)}
                    >
                      {l.label}
                      {isActive && (
                        <span className="h-1.5 w-1.5 rounded-full bg-primary" aria-hidden />
                      )}
                    </a>
                  );
                })}
              </nav>

              <div className="mt-1 flex items-center gap-2 border-t border-hairline-light p-2">
                <a
                  href={siteConfig.githubUrl}
                  target="_blank"
                  rel="noopener noreferrer"
                  className="flex min-h-11 flex-1 items-center justify-center gap-2 rounded-full border border-hairline-light py-2.5 text-[14px] font-medium text-ink transition-colors hover:bg-black/[0.04]"
                  onClick={() => setOpen(false)}
                >
                  <GitHubIcon className="h-4 w-4" />
                  GitHub
                </a>
                <DownloadButton className="min-h-11 flex-1" label="Download" />
              </div>
            </motion.div>
          </>
        )}
      </AnimatePresence>
    </header>
  );
}
