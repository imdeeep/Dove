"use client";

import Image from "next/image";
import Link from "next/link";
import { AnimatePresence, motion } from "framer-motion";
import { dismiss, easeOut } from "@/lib/motion";
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

interface MobileNavProps {
  open: boolean;
  onClose: () => void;
  active: string;
  reduced: boolean | null;
}

export function MobileNav({ open, onClose, active, reduced }: MobileNavProps) {
  return (
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
            className="mobile-nav-backdrop fixed inset-0 z-40 md:hidden"
            onClick={onClose}
          />
          <motion.div
            initial={reduced ? false : { opacity: 0, y: -12, scale: 0.98 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            exit={reduced ? undefined : { opacity: 0, y: -12, scale: 0.98 }}
            transition={{ duration: reduced ? 0 : dismiss, ease: easeOut }}
            className="mobile-nav-sheet pointer-events-auto fixed inset-x-4 top-[max(1rem,env(safe-area-inset-top))] z-50 mx-auto max-w-[800px] overflow-hidden md:hidden"
          >
            <div className="flex h-[52px] items-center justify-between border-b border-hairline-light/80 px-3">
              <Link href="/" className="nav-brand flex items-center gap-2 pl-1" onClick={onClose}>
                <Image
                  src="/dove-menubar.png"
                  alt=""
                  width={22}
                  height={22}
                  className="logo-invert h-[22px] w-[22px] object-contain"
                />
                <span className="text-[15px] font-semibold tracking-[-0.02em] text-ink">Dove</span>
              </Link>
              <button
                type="button"
                aria-label="Close menu"
                className="inline-flex h-11 w-11 items-center justify-center rounded-full text-ink transition-colors hover:bg-black/[0.05]"
                onClick={onClose}
              >
                <svg width="18" height="18" viewBox="0 0 20 20" fill="none" aria-hidden>
                  <path
                    d="M4 4l12 12M16 4L4 16"
                    stroke="currentColor"
                    strokeWidth="1.5"
                    strokeLinecap="round"
                  />
                </svg>
              </button>
            </div>

            <nav aria-label="Mobile" className="px-2 py-2">
              <ul>
                {navLinks.map((link) => {
                  const isActive = active === link.href;
                  return (
                    <li key={link.href}>
                      <a
                        href={link.href}
                        className={cn(
                          "flex min-h-[48px] items-center justify-between rounded-xl px-3 text-[16px] tracking-[-0.02em] transition-colors",
                          isActive
                            ? "bg-canvas-subtle font-semibold text-primary"
                            : "text-ink active:bg-black/[0.04]",
                        )}
                        onClick={onClose}
                      >
                        {link.label}
                        <svg
                          className={cn(
                            "h-4 w-4 shrink-0 text-ink-muted/45",
                            isActive && "text-primary/60",
                          )}
                          viewBox="0 0 16 16"
                          fill="none"
                          aria-hidden
                        >
                          <path
                            d="M6 4l4 4-4 4"
                            stroke="currentColor"
                            strokeWidth="1.5"
                            strokeLinecap="round"
                            strokeLinejoin="round"
                          />
                        </svg>
                      </a>
                    </li>
                  );
                })}
              </ul>
            </nav>

            <div className="space-y-2 border-t border-hairline-light/80 p-3">
              <DownloadButton
                label="Download for macOS"
                className="min-h-12 w-full text-[15px]"
              />
              <a
                href={siteConfig.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="flex min-h-11 w-full items-center justify-center gap-2 rounded-full border border-hairline-light bg-canvas-elevated text-[14px] font-medium text-ink shadow-[0_1px_2px_rgba(0,0,0,0.03)] transition-colors hover:bg-canvas-subtle"
                onClick={onClose}
              >
                <GitHubIcon className="h-4 w-4" />
                Star on GitHub
              </a>
            </div>
          </motion.div>
        </>
      )}
    </AnimatePresence>
  );
}
