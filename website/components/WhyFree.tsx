import { siteConfig } from "@/lib/site-config";
import { Reveal, Stagger, StaggerItem } from "./motion/Reveal";
import { Section, SectionHeader } from "./ui/Section";

const reasons = [
  {
    title: "Open source",
    explanation: "Public on GitHub. Inspect, fork, improve.",
  },
  {
    title: "Bring your own key",
    explanation: "You pay your AI provider - not Dove.",
  },
  {
    title: "Local speech",
    explanation: "Whisper runs on your Mac. No Dove server.",
  },
  {
    title: "Built to share",
    explanation: "A personal tool, shared free on purpose.",
  },
  {
    title: "Community-powered",
    explanation: "Stars, bugs, and PRs - not paywalls.",
  },
];

const cardClassName =
  "h-full rounded-2xl border border-hairline-light bg-canvas-elevated px-6 py-5 shadow-[0_1px_3px_rgba(0,0,0,0.03)] transition-shadow duration-300 hover:shadow-soft";

/** Same width at every breakpoint - 1 col → 2 col → 3 col, last row centers via flex. */
const tileClassName =
  "w-full sm:w-[calc(50%-0.5rem)] lg:w-[calc(33.333%-0.667rem)]";

export function WhyFree() {
  return (
    <Section id="why-free" variant="warm">
      <Reveal>
        <SectionHeader
          centered
          title="Free on purpose."
          intro="No subscription. No account. No server billing you."
          className="mb-10 md:mb-12"
        />
      </Reveal>

      <Stagger className="mx-auto flex max-w-[780px] flex-wrap justify-center gap-4">
        {reasons.map((reason) => (
          <StaggerItem key={reason.title} className={tileClassName}>
            <div className={cardClassName}>
              <h3 className="text-[15px] font-semibold tracking-[-0.02em] text-ink">
                {reason.title}
              </h3>
              <p className="mt-1.5 text-[14px] leading-relaxed text-ink-muted">
                {reason.explanation}
              </p>
            </div>
          </StaggerItem>
        ))}
      </Stagger>

      <Reveal className="mx-auto mt-12 max-w-md text-center md:mt-14">
        <p className="pull-quote text-[16px]">
          Optional API costs go to your provider - raw transcript works without a key.
        </p>
        <p className="mt-4 text-[14px] text-ink-muted">
          If Dove saves you time,{" "}
          <a href={siteConfig.githubUrl} className="link-accent font-medium">
            star the repo
          </a>
          .
        </p>
      </Reveal>
    </Section>
  );
}
