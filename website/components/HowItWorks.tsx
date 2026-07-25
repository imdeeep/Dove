"use client";

import { motion, useReducedMotion } from "framer-motion";
import { appear, easeOut } from "@/lib/motion";
import { Section, SectionHeader } from "./ui/Section";
import { HotkeyKeys } from "./ui/HotkeyPill";

const steps = [
  {
    number: "01",
    label: "Press",
    detail: (
      <>
        Hold <HotkeyKeys tone="inline" size="sm" className="mx-0.5" /> to start. Press again when
        you&apos;re done.
      </>
    ),
    icon: "⌘",
  },
  {
    number: "02",
    label: "Speak",
    detail: "Talk naturally - fillers and all. Dove listens from your menu bar.",
    icon: "◎",
  },
  {
    number: "03",
    label: "Polish",
    detail: "Whisper transcribes on your Mac. Your AI refines it - if you add a key.",
    icon: "✦",
  },
  {
    number: "04",
    label: "Insert",
    detail: "Polished text lands at your cursor - in any app you're already in.",
    icon: "↵",
  },
];

export function HowItWorks() {
  const reduced = useReducedMotion();

  return (
    <Section id="how-it-works" variant="warm">
      <SectionHeader
        centered
        label="How it works"
        title="Four steps. Two seconds. Done."
        intro="From thought to polished text - without leaving the app you're in."
      />

      <div className="relative">
        <div
          className="pointer-events-none absolute top-8 right-[10%] left-[10%] hidden h-px md:block"
          aria-hidden
        >
          <div className="h-full w-full bg-gradient-to-r from-transparent via-primary/20 to-transparent" />
        </div>

        <ol className="grid gap-10 sm:grid-cols-2 md:grid-cols-4 md:gap-6">
          {steps.map((step, index) => (
            <motion.li
              key={step.number}
              initial={reduced ? false : { opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: appear, delay: index * 0.05, ease: easeOut }}
              className="group relative flex flex-col items-center text-center"
            >
              <div className="relative z-10 flex h-[60px] w-[60px] items-center justify-center rounded-2xl border border-hairline-light bg-canvas-elevated text-[22px] text-ink shadow-[0_2px_12px_rgba(0,0,0,0.04)] transition-shadow duration-300 group-hover:shadow-[0_4px_20px_rgba(0,0,0,0.07)]">
                {step.icon}
              </div>

              <span className="mt-5 text-[11px] font-medium tracking-[0.1em] text-primary/80 uppercase">
                Step {step.number}
              </span>

              <h3 className="mt-1.5 text-[19px] font-semibold tracking-[-0.02em] text-ink">
                {step.label}
              </h3>

              <p className="mt-2 max-w-[15rem] text-[14px] leading-relaxed text-ink-muted">
                {step.detail}
              </p>
            </motion.li>
          ))}
        </ol>
      </div>

      <motion.p
        initial={reduced ? false : { opacity: 0, y: 10 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: appear, delay: 0.2, ease: easeOut }}
        className="pull-quote mx-auto mt-14 max-w-md text-center text-[16px] md:mt-16"
      >
        Audio stays on your Mac. Only text goes to your AI - and only if you add a key.
      </motion.p>
    </Section>
  );
}
