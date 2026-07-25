"use client";

import { motion, useReducedMotion } from "framer-motion";
import Image from "next/image";
import { easeOut } from "@/lib/motion";
import { HotkeyKeys } from "../ui/HotkeyPill";

export function HeroPeek() {
  const reduced = useReducedMotion();

  return (
    <motion.div
      initial={reduced ? false : { opacity: 0, y: 48 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.55, delay: 0.32, ease: easeOut }}
      className="relative mx-auto mt-14 max-w-[760px] px-4 md:mt-20 md:px-6"
    >
      <div
        className="pointer-events-none absolute inset-x-0 -top-12 h-12 bg-gradient-to-b from-transparent to-canvas"
        aria-hidden
      />

      <div className="hero-peek-window overflow-hidden rounded-t-[20px] border border-b-0 border-white/10 shadow-[0_-20px_80px_rgba(0,0,0,0.14)]">
        <div className="flex items-center gap-3 border-b border-white/[0.08] bg-[#1a1a1c] px-4 py-3">
          <div className="flex gap-1.5" aria-hidden>
            <span className="h-3 w-3 rounded-full bg-[#ff5f57]" />
            <span className="h-3 w-3 rounded-full bg-[#febc2e]" />
            <span className="h-3 w-3 rounded-full bg-[#28c840]" />
          </div>
          <span className="min-w-0 flex-1 text-center text-[12px] font-medium text-white/45 max-sm:truncate">
            Compose - New Message
          </span>
          <span className="hidden items-center justify-center gap-2 sm:inline-flex">
            <HotkeyKeys dark size="xs" />
            <span className="text-[10px] text-white/35">to dictate</span>
          </span>
        </div>

        <div className="bg-gradient-to-b from-[#1e1e20] to-[#161618] px-6 py-8 md:px-10 md:py-10">
          <p className="text-left text-[15px] leading-[1.65] text-white/75 md:text-[16px]">
            Add a dark mode toggle that remembers the user&apos;s preference across sessions.
            <motion.span
              className="ml-0.5 inline-block h-[18px] w-[2px] bg-primary-on-dark align-middle"
              animate={reduced ? undefined : { opacity: [1, 0.2, 1] }}
              transition={{ duration: 1.1, repeat: Infinity, ease: "easeInOut" }}
              aria-hidden
            />
          </p>

          <div className="mt-8 flex items-center justify-between gap-3 rounded-xl border border-white/[0.08] bg-white/[0.04] px-3.5 py-2.5 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] max-sm:flex-col max-sm:items-start max-sm:gap-2">
            <div className="flex min-w-0 items-center gap-2.5">
              <motion.div
                className="relative flex h-7 w-7 shrink-0 items-center justify-center rounded-lg border border-white/10 bg-black/40"
                animate={reduced ? undefined : { boxShadow: ["0 0 0 0 rgba(41,151,255,0)", "0 0 0 4px rgba(41,151,255,0.12)", "0 0 0 0 rgba(41,151,255,0)"] }}
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              >
                <Image
                  src="/dove-menubar.png"
                  alt=""
                  width={18}
                  height={18}
                  className="h-[18px] w-[18px] object-contain"
                />
              </motion.div>
              <span className="truncate text-[12px] text-white/45">Dove is listening…</span>
            </div>
            <HotkeyKeys dark size="xs" />
          </div>
        </div>
      </div>
    </motion.div>
  );
}
