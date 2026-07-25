import { siteConfig } from "@/lib/site-config";
import { Reveal } from "./motion/Reveal";
import { Section, SectionHeader } from "./ui/Section";

const channels = [
  {
    title: "Email",
    detail: "Questions, bugs, or ideas.",
    href: `mailto:${siteConfig.supportEmail}`,
    label: siteConfig.supportEmail,
    external: false,
    icon: "mail",
  },
  {
    title: "GitHub",
    detail: "Issues and pull requests.",
    href: siteConfig.githubUrl,
    label: "Open GitHub →",
    external: true,
    icon: "github",
  },
] as const;

function ChannelIcon({ type }: { type: "mail" | "github" }) {
  if (type === "mail") {
    return (
      <svg className="h-4 w-4 text-white/35" viewBox="0 0 16 16" fill="none" aria-hidden>
        <rect x="1.5" y="3.5" width="13" height="9" rx="1.5" stroke="currentColor" strokeWidth="1.2" />
        <path d="M2.5 4.5 8 8.5l5.5-4" stroke="currentColor" strokeWidth="1.2" strokeLinecap="round" />
      </svg>
    );
  }

  return (
    <svg className="h-4 w-4 text-white/35" viewBox="0 0 16 16" fill="currentColor" aria-hidden>
      <path d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.18.82.63-.18 1.29-.27 1.96-.27.67 0 1.33.09 1.96.27 1.51-1.04 2.18-.82 2.18-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.01 8.01 0 0 0 16 8c0-4.42-3.58-8-8-8z" />
    </svg>
  );
}

export function Contact() {
  return (
    <Section id="contact" variant="dark" className="contact-band py-20 md:py-28">
      <div className="contact-band-glow" aria-hidden />
      <div className="contact-band-sheen" aria-hidden />

      <Reveal>
        <SectionHeader
          dark
          centered
          label="Contact"
          title="Get in touch."
          intro="Short note is enough."
          className="mb-10 md:mb-12"
        />
      </Reveal>

      <Reveal className="relative mx-auto w-full max-w-[540px]">
        <div className="contact-card overflow-hidden rounded-2xl border border-hairline-dark bg-[var(--hero-dark-surface)] shadow-[0_12px_48px_rgba(0,0,0,0.35)]">
          <div className="grid gap-px bg-hairline-dark sm:grid-cols-2">
            {channels.map((channel) => (
              <a
                key={channel.title}
                href={channel.href}
                target={channel.external ? "_blank" : undefined}
                rel={channel.external ? "noopener noreferrer" : undefined}
                className="group flex min-h-[148px] flex-col bg-[var(--hero-dark-surface)] px-5 py-5 transition-colors duration-200 hover:bg-white/[0.04] md:px-6 md:py-6"
              >
                <div className="flex items-center gap-2.5">
                  <ChannelIcon type={channel.icon} />
                  <p className="text-[11px] font-semibold tracking-[0.14em] text-white/40 uppercase">
                    {channel.title}
                  </p>
                </div>

                <p className="mt-3 text-[13px] leading-relaxed text-white/50">{channel.detail}</p>

                <p
                  className={[
                    "mt-auto pt-5 text-[13px] font-medium text-primary-on-dark transition-all duration-200 group-hover:text-white",
                    channel.icon === "mail" ? "break-all font-mono text-[12px] leading-snug" : "",
                  ]
                    .filter(Boolean)
                    .join(" ")}
                >
                  {channel.label}
                </p>
              </a>
            ))}
          </div>

          <div className="border-t border-hairline-dark px-5 py-5 text-center md:px-6 md:py-6">
            <p className="text-[13px] leading-relaxed text-white/50">
              Attach a diagnostic report if something broke - it never includes transcripts or keys.
            </p>
            <p className="mt-2.5 font-mono text-[11px] tracking-[-0.01em] text-white/32">
              Preferences → Contact → Export Report
            </p>
          </div>
        </div>
      </Reveal>
    </Section>
  );
}
