import { DownloadButton } from "./ui/DownloadButton";
import { Section, SectionHeader } from "./ui/Section";
import { FeatureTheaterLoader } from "./FeatureTheaterLoader";
import { FEATURE_THEATER_CRITICAL_CSS } from "./feature-theater-shared";

const rails = [
  {
    label: "Fillers",
    title: "Gone before they land",
    detail: "um, uh, false starts - stripped. Your point stays.",
  },
  {
    label: "Punctuation",
    title: "Sentences, not streams",
    detail: "Commas, periods, capitalization - ready to send.",
  },
  {
    label: "Typing",
    title: "Word by word",
    detail: "Inserted at your cursor like you typed it yourself.",
  },
];

export function Features() {
  return (
    <Section id="features" variant="warm">
      <style dangerouslySetInnerHTML={{ __html: FEATURE_THEATER_CRITICAL_CSS }} />
      <SectionHeader
        centered
        label="Features"
        title="Speak how you actually speak."
        intro="Watch Dove turn messy speech into text you'd send - live."
      />

      <FeatureTheaterLoader />

      <ul className="feature-rails">
        {rails.map((rail) => (
          <li key={rail.label} className="feature-rail">
            <p className="text-[11px] font-semibold uppercase tracking-widest text-primary">
              {rail.label}
            </p>
            <h3 className="mt-2 text-[16px] font-semibold tracking-[-0.02em] text-ink">
              {rail.title}
            </h3>
            <p className="mt-1.5 text-[13px] leading-relaxed text-ink-muted">{rail.detail}</p>
          </li>
        ))}
      </ul>

      <p className="pull-quote mx-auto mt-14 max-w-md text-center text-[16px] md:mt-16">
        You stay the author. Dove is the editor - not the ghostwriter.
      </p>

      <div className="mt-12 flex justify-center">
        <DownloadButton />
      </div>
    </Section>
  );
}
