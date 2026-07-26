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
      className="relative mx-auto mt-8 max-w-[760px] px-3 md:mt-20 md:px-6"
    >
      <div
        className="pointer-events-none absolute inset-x-0 -top-10 h-10 bg-gradient-to-b from-transparent to-canvas md:-top-12 md:h-12"
        aria-hidden
      />

      <div className="hero-peek-window overflow-hidden rounded-t-2xl border border-b-0 border-white/10 shadow-[0_-20px_80px_rgba(0,0,0,0.14)] md:rounded-t-[20px]">
        <div className="flex items-center gap-2 border-b border-white/[0.08] bg-[#1a1a1c] px-3 py-2.5 md:gap-3 md:px-4 md:py-3">
          <div className="flex shrink-0 gap-1.5" aria-hidden>
            <span className="h-2.5 w-2.5 rounded-full bg-[#ff5f57] md:h-3 md:w-3" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#febc2e] md:h-3 md:w-3" />
            <span className="h-2.5 w-2.5 rounded-full bg-[#28c840] md:h-3 md:w-3" />
          </div>
          <span className="min-w-0 flex-1 truncate text-center text-[11px] font-medium text-white/45 md:text-[12px]">
            Compose - New Message
          </span>
          <span className="hidden w-[88px] shrink-0 items-center justify-end gap-2 sm:inline-flex">
            <HotkeyKeys dark size="xs" />
            <span className="text-[10px] text-white/35">to dictate</span>
          </span>
          <span className="w-14 shrink-0 sm:hidden" aria-hidden />
        </div>

        <div className="bg-gradient-to-b from-[#1e1e20] to-[#161618] px-4 py-5 md:px-10 md:py-10">
          <p className="text-left text-[14px] leading-[1.6] text-white/75 md:text-[16px] md:leading-[1.65]">
            Add a dark mode toggle that remembers the user&apos;s preference across sessions.
            <motion.span
              className="ml-0.5 inline-block h-4 w-[2px] bg-primary-on-dark align-middle md:h-[18px]"
              animate={reduced ? undefined : { opacity: [1, 0.2, 1] }}
              transition={{ duration: 1.1, repeat: Infinity, ease: "easeInOut" }}
              aria-hidden
            />
          </p>

          <div className="mt-5 flex items-center justify-between gap-2.5 rounded-xl border border-white/[0.08] bg-white/[0.04] px-3 py-2 shadow-[inset_0_1px_0_rgba(255,255,255,0.04)] md:mt-8 md:gap-3 md:px-3.5 md:py-2.5">
            <div className="flex min-w-0 items-center gap-2">
              <motion.div
                className="relative flex h-6 w-6 shrink-0 items-center justify-center rounded-md border border-white/10 bg-black/40 md:h-7 md:w-7 md:rounded-lg"
                animate={
                  reduced
                    ? undefined
                    : {
                        boxShadow: [
                          "0 0 0 0 rgba(41,151,255,0)",
                          "0 0 0 4px rgba(41,151,255,0.12)",
                          "0 0 0 0 rgba(41,151,255,0)",
                        ],
                      }
                }
                transition={{ duration: 2, repeat: Infinity, ease: "easeInOut" }}
              >
                <Image
                  src="/dove-menubar.png"
                  alt=""
                  width={18}
                  height={18}
                  className="h-4 w-4 object-contain md:h-[18px] md:w-[18px]"
                />
              </motion.div>
              <span className="truncate text-[11px] text-white/45 md:text-[12px]">Dove is listening…</span>
            </div>
            <div className="shrink-0">
              <HotkeyKeys dark size="xs" />
            </div>
          </div>
        </div>
      </div>
    </motion.div>
  );
}
