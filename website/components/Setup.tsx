import { Reveal, Stagger, StaggerItem } from "./motion/Reveal";
import { DownloadButton } from "./ui/DownloadButton";
import { HotkeyKeys } from "./ui/HotkeyPill";
import { Section, SectionHeader } from "./ui/Section";

const steps = [
  { n: "1", title: "Download", detail: "Open the .dmg, drag Dove to Applications." },
  { n: "2", title: "Permissions", detail: "Allow Microphone and Accessibility once." },
  { n: "3", title: "Speech model", detail: "Small English downloads on first use (~150 MB)." },
  {
    n: "4",
    title: "AI key (optional)",
    detail: "Preferences → AI Provider. Raw transcript works without a key.",
  },
  {
    n: "5",
    title: "Record",
    detail: (
      <>
        Press <HotkeyKeys tone="inline" size="sm" className="mx-0.5 align-middle" />, speak, press
        again. Text lands at your cursor.
      </>
    ),
  },
];

const requirements = ["macOS 14+", "Apple Silicon recommended", "11 AI providers"];

const stepCardClassName =
  "flex items-start gap-4 rounded-2xl border border-hairline-light bg-canvas-elevated px-5 py-4 shadow-[0_1px_3px_rgba(0,0,0,0.03)]";

export function Setup() {
  return (
    <Section id="setup" variant="parchment">
      <Reveal>
        <SectionHeader
          centered
          label="Setup"
          title="Up and running in minutes."
          intro="Download, two permissions, optional API key."
          className="mb-10 md:mb-12"
        />
      </Reveal>

      <Stagger className="mx-auto flex w-full max-w-[520px] flex-col gap-3">
        {steps.map((step) => (
          <StaggerItem key={step.n}>
            <div className={stepCardClassName}>
              <span
                className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full border border-hairline-light bg-canvas-subtle font-mono text-[11px] font-medium tabular-nums text-ink-muted"
                aria-hidden
              >
                {step.n}
              </span>
              <div className="min-w-0 pt-0.5">
                <h3 className="text-[15px] font-semibold tracking-[-0.02em] text-ink">
                  {step.title}
                </h3>
                <p className="mt-1 text-[14px] leading-relaxed text-ink-muted">{step.detail}</p>
              </div>
            </div>
          </StaggerItem>
        ))}
      </Stagger>

      <Reveal className="mx-auto mt-8 flex max-w-[520px] flex-wrap justify-center gap-2">
        {requirements.map((req) => (
          <span
            key={req}
            className="rounded-full border border-hairline-light bg-canvas-elevated px-3.5 py-1.5 font-mono text-[11px] tracking-[-0.01em] text-ink-muted"
          >
            {req}
          </span>
        ))}
      </Reveal>

      <Reveal className="mt-10 flex justify-center">
        <DownloadButton />
      </Reveal>
    </Section>
  );
}
