"use client";

import { motion, useReducedMotion } from "framer-motion";
import { appear, easeOut, revealY } from "@/lib/motion";
import { Section, SectionHeader } from "./ui/Section";

const offers = [
  { title: "Menu bar app", detail: "One hotkey. No Dock icon." },
  { title: "Local Whisper", detail: "On-device. Offline after download." },
  { title: "AI polishing", detail: "11 providers. Your key." },
  { title: "Types anywhere", detail: "IDE, browser, Slack, Notion." },
  { title: "Open source", detail: "Full source on GitHub." },
  { title: "Free forever", detail: "No account. No subscription." },
];

function CheckIcon() {
  return (
    <svg width="10" height="10" viewBox="0 0 10 10" fill="currentColor" aria-hidden>
      <path d="M3.8 5.1 2.4 3.7l-.7.7 2.1 2.1 4.5-4.5-.7-.7-3.8 3.8z" />
    </svg>
  );
}

export function WhatWeOffer() {
  const reduced = useReducedMotion();

  return (
    <Section id="what-we-offer" variant="parchment">
      <SectionHeader
        centered
        label="What you get"
        title="Everything you need."
        intro="A focused menu bar app - voice in, polished text out."
        className="mb-10 md:mb-12"
      />

      <div className="mx-auto max-w-[760px] overflow-hidden rounded-2xl border border-hairline-light bg-canvas-elevated shadow-[0_1px_3px_rgba(0,0,0,0.03)]">
        <ul className="grid md:grid-cols-2">
          {offers.map((offer, index) => (
            <motion.li
              key={offer.title}
              initial={reduced ? false : { opacity: 0, y: revealY }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{ duration: appear, delay: index * 0.04, ease: easeOut }}
              className={`flex gap-3 px-5 py-4 md:px-6 md:py-5 ${
                index < offers.length - 1 ? "border-b border-hairline-light/70" : ""
              } ${index >= 4 ? "md:border-b-0" : ""} ${
                index % 2 === 0 ? "md:border-r md:border-hairline-light/70" : ""
              }`}
            >
              <span
                className="mt-0.5 flex h-[18px] w-[18px] shrink-0 items-center justify-center rounded-full bg-primary/[0.08] text-primary"
                aria-hidden
              >
                <CheckIcon />
              </span>
              <div className="min-w-0">
                <p className="text-[15px] font-semibold tracking-[-0.01em] text-ink">
                  {offer.title}
                </p>
                <p className="mt-0.5 text-[13px] leading-snug text-ink-muted">{offer.detail}</p>
              </div>
            </motion.li>
          ))}
        </ul>
      </div>
    </Section>
  );
}
