"use client";

import { AnimatePresence, motion, useReducedMotion } from "framer-motion";
import { useState } from "react";
import { faqContent } from "@/lib/faq-content";
import { motionDismiss, motionEaseOut } from "@/lib/motion";
import { cn } from "@/lib/utils";
import { Reveal } from "./motion/Reveal";
import { CreatorLink } from "./ui/CreatorLink";
import { HotkeyKeys } from "./ui/HotkeyPill";
import { Section, SectionHeader } from "./ui/Section";

type FaqEntry = {
  q: string;
  a: React.ReactNode;
};

const faqs: FaqEntry[] = faqContent.map((item) => {
  if (item.q === "Default hotkey?") {
    return {
      q: item.q,
      a: (
        <>
          Default is <HotkeyKeys tone="inline" size="sm" className="mx-0.5 align-middle" /> - change
          it in Preferences → Hotkey.
        </>
      ),
    };
  }

  if (item.q === "Something broken?") {
    return {
      q: item.q,
      a: (
        <>
          Export diagnostics from Preferences → Contact, then contact <CreatorLink />.
        </>
      ),
    };
  }

  return item;
});

function FaqItem({
  q,
  a,
  open,
  onToggle,
  isLast,
}: {
  q: string;
  a: React.ReactNode;
  open: boolean;
  onToggle: () => void;
  isLast: boolean;
}) {
  const reducedMotion = useReducedMotion();
  const panelId = `faq-panel-${q.replace(/\s+/g, "-").toLowerCase()}`;

  return (
    <div className={cn(!isLast && "border-b border-hairline-light/80")}>
      <button
        type="button"
        className="group flex w-full items-start justify-between gap-4 px-5 py-4 text-left"
        aria-expanded={open}
        aria-controls={panelId}
        onClick={onToggle}
      >
        <span className="pt-0.5 text-[15px] font-semibold tracking-[-0.022em] text-ink">
          {q}
        </span>
        <span
          className={cn(
            "flex h-6 w-6 shrink-0 items-center justify-center rounded-full border text-[14px] leading-none text-ink-muted transition-colors duration-200",
            open
              ? "border-hairline-light bg-canvas-subtle"
              : "border-transparent group-hover:border-hairline-light group-hover:bg-canvas-subtle/80",
          )}
          aria-hidden
        >
          {open ? "−" : "+"}
        </span>
      </button>
      <AnimatePresence initial={false}>
        {open && (
          <motion.div
            id={panelId}
            initial={reducedMotion ? false : { height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            transition={{
              duration: reducedMotion ? 0 : motionDismiss,
              ease: motionEaseOut,
            }}
            className="overflow-hidden"
          >
            <div className="px-5 pb-4 pt-0 text-[14px] leading-relaxed text-ink-muted">{a}</div>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

export function FAQ() {
  const [openIndex, setOpenIndex] = useState<number | null>(null);

  return (
    <Section id="faq" variant="parchment">
      <Reveal>
        <SectionHeader
          centered
          label="FAQ"
          title="Questions."
          intro="Short answers."
          className="mb-10 md:mb-12"
        />
      </Reveal>

      <Reveal className="mx-auto w-full max-w-[560px]">
        <div className="overflow-hidden rounded-2xl border border-hairline-light bg-canvas-elevated shadow-[0_1px_3px_rgba(0,0,0,0.03)]">
          {faqs.map((item, index) => (
            <FaqItem
              key={item.q}
              q={item.q}
              a={item.a}
              open={openIndex === index}
              onToggle={() => setOpenIndex(openIndex === index ? null : index)}
              isLast={index === faqs.length - 1}
            />
          ))}
        </div>
      </Reveal>
    </Section>
  );
}
