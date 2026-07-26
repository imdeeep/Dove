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
    <Section id="how-it-works" variant="warm" className="max-md:py-16">
      <SectionHeader
        centered
        label="How it works"
        title="Four steps. Two seconds. Done."
        intro="From thought to polished text - without leaving the app you're in."
        className="max-md:mb-8"
        titleClassName="max-md:text-[28px] max-md:leading-[1.12]"
        introClassName="max-md:mt-3 max-md:max-w-[18rem] max-md:text-[15px] max-md:leading-relaxed"
      />

      <div className="relative">
        <div
          className="pointer-events-none absolute top-8 right-[10%] left-[10%] hidden h-px md:block"
          aria-hidden
        >
          <div className="h-full w-full bg-gradient-to-r from-transparent via-primary/20 to-transparent" />
        </div>

        <ol className="grid grid-cols-1 gap-0 sm:grid-cols-2 sm:gap-5 md:grid-cols-4 md:gap-6">
          {steps.map((step, index) => (
            <motion.li
              key={step.number}
              initial={reduced ? false : { opacity: 0, y: 14 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: appear, delay: index * 0.05, ease: easeOut }}
              className="how-it-works-step group relative flex flex-col items-center border-b border-hairline-light py-4 text-center last:border-b-0 max-sm:py-3.5 sm:border-b-0 sm:py-0 md:flex-col md:items-center md:text-center"
            >
              <div className="relative z-10 flex h-11 w-11 shrink-0 items-center justify-center rounded-xl border border-hairline-light bg-canvas-elevated text-[18px] text-ink shadow-[0_2px_12px_rgba(0,0,0,0.04)] transition-shadow duration-300 group-hover:shadow-[0_4px_20px_rgba(0,0,0,0.07)] sm:h-[60px] sm:w-[60px] sm:rounded-2xl sm:text-[22px] md:mx-auto">
                {step.icon}
              </div>

              <div className="how-it-works-step-copy mt-3 min-w-0 sm:mt-5 md:contents">
                <span className="text-[10px] font-medium tracking-[0.1em] text-primary/80 uppercase sm:text-[11px]">
                  Step {step.number}
                </span>

                <h3 className="mt-0.5 text-[17px] font-semibold tracking-[-0.02em] text-ink sm:mt-1.5 sm:text-[19px]">
                  {step.label}
                </h3>

                <p className="mt-1.5 max-w-none text-[13px] leading-relaxed text-ink-muted sm:mt-2 sm:max-w-[15rem] sm:text-[14px]">
                  {step.detail}
                </p>
              </div>
            </motion.li>
          ))}
        </ol>
      </div>

      <motion.p
        initial={reduced ? false : { opacity: 0, y: 10 }}
        whileInView={{ opacity: 1, y: 0 }}
        viewport={{ once: true }}
        transition={{ duration: appear, delay: 0.2, ease: easeOut }}
        className="pull-quote mx-auto mt-8 max-w-md text-center text-[15px] md:mt-16 md:text-[16px]"
      >
        Audio stays on your Mac. Only text goes to your AI - and only if you add a key.
      </motion.p>
    </Section>
  );
}
