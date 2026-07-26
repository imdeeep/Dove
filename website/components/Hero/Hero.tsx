"use client";

import { motion, useReducedMotion } from "framer-motion";
import Image from "next/image";
import { appear, easeOut, revealY } from "@/lib/motion";
import { siteConfig } from "@/lib/site-config";
import { Button } from "../ui/Button";
import { DownloadButton } from "../ui/DownloadButton";
import { HotkeyPill } from "../ui/HotkeyPill";
import { CreatorLink } from "../ui/CreatorLink";
import { HeroPeek } from "./HeroPeek";

const trust = ["Apple Silicon", "Local Whisper", "Free forever", "No account"];

function GitHubIcon({ className }: { className?: string }) {
  return (
    <svg className={className} viewBox="0 0 16 16" fill="currentColor" aria-hidden>
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.18.82.63-.18 1.29-.27 1.96-.27.67 0 1.33.09 1.96.27 1.51-1.04 2.18-.82 2.18-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z" />
    </svg>
  );
}

export function Hero() {
  const reduced = useReducedMotion();

  return (
    <section className="hero relative overflow-hidden pb-0 pt-24 md:pt-36">
      <div className="pointer-events-none absolute inset-0" aria-hidden>
        <div className="hero-glow" />
        <div className="hero-glow-subtle" />
      </div>

      <div className="relative mx-auto max-w-[680px] px-5 text-center md:px-8">
        <motion.div
          initial={reduced ? false : { opacity: 0, y: revealY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: appear, ease: easeOut }}
          className="mb-6 flex justify-center md:mb-8"
        >
          <a
            href={siteConfig.githubUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hero-badge group"
          >
            <span className="hero-badge-dot" aria-hidden />
            <span className="font-mono text-[10px] uppercase tracking-[0.04em]">
              {siteConfig.version}
            </span>
            <span className="text-ink-muted/40" aria-hidden>
              ·
            </span>
            <span>macOS</span>
            <span className="text-ink-muted/40" aria-hidden>
              ·
            </span>
            <span className="text-primary transition-colors group-hover:text-primary-focus">
              Star on GitHub
            </span>
          </a>
        </motion.div>

        <motion.h1
          initial={reduced ? false : { opacity: 0, y: revealY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: appear, delay: 0.05, ease: easeOut }}
          className="text-[50px] font-semibold leading-[1.02] tracking-[-0.038em] text-ink max-md:text-balance md:text-[68px] md:leading-[1.06] md:tracking-[-0.035em]"
        >
          <span className="block">Speak it.</span>
          <span className="mt-2 block font-serif text-[0.94em] font-normal italic text-primary md:mt-0 md:inline md:text-[0.92em]">
            Dove writes it.
          </span>
        </motion.h1>

        <motion.p
          initial={reduced ? false : { opacity: 0, y: revealY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: appear, delay: 0.1, ease: easeOut }}
          className="mx-auto mt-5 max-w-[20rem] text-[15px] leading-[1.55] text-ink-muted max-md:text-balance md:mt-6 md:max-w-[34rem] md:text-[20px] md:leading-[1.55]"
        >
          Hold <HotkeyPill tone="inline" size="sm" className="mx-0.5 align-middle" />.
          Say what you want. Release. Dove transcribes on your Mac, polishes with your AI, and
          types it where you&apos;re already working.
        </motion.p>

        <motion.div
          initial={reduced ? false : { opacity: 0, y: revealY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: appear, delay: 0.15, ease: easeOut }}
          className="mt-8 flex flex-col items-center justify-center gap-3.5 sm:flex-row md:mt-10 md:gap-3"
        >
          <DownloadButton
            label="Download for macOS"
            className="min-h-[54px] w-full px-8 text-[16px] shadow-[0_4px_14px_rgba(0,102,204,0.28)] max-md:shadow-[0_6px_20px_rgba(0,102,204,0.32)] sm:w-auto md:min-h-[52px] md:text-[17px]"
          />
          <Button
            href={siteConfig.githubUrl}
            variant="ghost"
            className="min-h-[54px] w-full gap-2 text-[15px] sm:w-auto md:min-h-[52px]"
          >
            <GitHubIcon className="h-4 w-4" />
            Star on GitHub
          </Button>
        </motion.div>

        <motion.p
          initial={reduced ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: appear, delay: 0.18, ease: easeOut }}
          className="mt-4 md:mt-5"
        >
          <a
            href="#setup"
            className="inline-flex min-h-11 items-center justify-center gap-1.5 px-2 text-[12px] font-medium uppercase tracking-[0.06em] text-ink-muted transition-colors hover:text-primary md:min-h-0 md:text-[11px] md:tracking-[0.07em]"
          >
            <span className="text-ink-muted/50" aria-hidden>
              -
            </span>
            First time? See install steps
          </a>
        </motion.p>

        <motion.div
          initial={reduced ? false : { opacity: 0, y: revealY }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ duration: appear, delay: 0.22, ease: easeOut }}
          className="mt-8 flex justify-center md:mt-10"
        >
          <div className="hero-trust-bar">
            {trust.map((t) => (
              <span key={t} className="trust-check">
                <svg width="12" height="12" viewBox="0 0 12 12" fill="currentColor" aria-hidden>
                  <path d="M4.5 6.2 2.8 4.5l-.9.9 2.6 2.6 5.4-5.4-.9-.9-4.5 4.5z" />
                </svg>
                {t}
              </span>
            ))}
          </div>
        </motion.div>

        <motion.div
          initial={reduced ? false : { opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ duration: appear, delay: 0.26, ease: easeOut }}
          className="mt-8 flex items-center justify-center gap-2 md:mt-10"
        >
          <Image
            src="/dove-menubar.png"
            alt=""
            width={18}
            height={18}
            className="logo-invert h-[18px] w-[18px] opacity-40 max-md:h-5 max-md:w-5"
          />
          <p className="pull-quote text-[16px] max-md:text-[15px]">
            Built by <CreatorLink className="not-italic" />
          </p>
        </motion.div>
      </div>

      <HeroPeek />
    </section>
  );
}
