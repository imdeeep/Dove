import Link from "next/link";
import { siteConfig } from "@/lib/site-config";
import { buildMetadata } from "@/lib/seo";

export const metadata = buildMetadata({
  title: `Privacy Policy | ${siteConfig.name}`,
  description:
    "How Dove handles your voice, transcripts, API keys, and diagnostics on macOS. No accounts, no telemetry, no Dove server.",
  path: "/privacy",
});

const lastUpdated = "July 26, 2026";

function PrivacySection({
  title,
  children,
}: {
  title: string;
  children: React.ReactNode;
}) {
  return (
    <section className="privacy-section">
      <h2 className="text-[15px] font-semibold tracking-[-0.02em] text-ink">{title}</h2>
      <div className="mt-3 space-y-3 text-[15px] leading-relaxed text-ink-muted">{children}</div>
    </section>
  );
}

export default function PrivacyPage() {
  return (
    <div className="bg-canvas">
      <article className="mx-auto max-w-[640px] px-6 pb-20 pt-28 md:px-8 md:pb-24 md:pt-32">
        <header className="text-center">
          <p className="section-label mb-4">Legal</p>
          <h1 className="text-[34px] font-semibold tracking-[-0.03em] text-ink md:text-[40px] md:leading-[1.1]">
            Privacy Policy
          </h1>
          <p className="mt-4 text-[13px] text-ink-muted">Last updated {lastUpdated}</p>
          <p className="pull-quote mx-auto mt-6 max-w-md text-[16px]">
            Dove runs on your Mac. We don&apos;t collect your voice, transcripts, or analytics - and
            there is no Dove server in the middle.
          </p>
        </header>

        <div className="privacy-doc mt-10 md:mt-12">
          <PrivacySection title="Overview">
            <p>
              Dove is a free, open-source macOS menu bar app. There is no account, no subscription,
              and no telemetry. We do not operate a backend that receives your speech or text.
            </p>
          </PrivacySection>

          <PrivacySection title="What stays on your Mac">
            <ul className="privacy-list">
              <li>
                <strong className="font-medium text-ink">Voice</strong> - processed locally with
                Whisper. Audio is not uploaded to Dove or stored after transcription.
              </li>
              <li>
                <strong className="font-medium text-ink">Speech models</strong> - cached under{" "}
                <code className="privacy-path">~/Documents/huggingface</code> after first download.
              </li>
              <li>
                <strong className="font-medium text-ink">API keys</strong> - stored in the macOS
                Keychain only, never in plain-text preferences.
              </li>
              <li>
                <strong className="font-medium text-ink">Settings</strong> - hotkey, provider, and
                preferences stay in local app storage on your Mac.
              </li>
              <li>
                <strong className="font-medium text-ink">Diagnostic logs</strong> - optional local
                logs in{" "}
                <code className="privacy-path">~/Library/Caches/.../Dove/Logs</code>. You choose
                when to export or delete them.
              </li>
            </ul>
          </PrivacySection>

          <PrivacySection title="What leaves your Mac">
            <p>
              If you add an AI provider, <em>transcript text</em> is sent directly from your Mac to
              that provider for polishing - using your API key. Dove does not proxy, log, or store
              that traffic on any server we run.
            </p>
            <p>
              Without an API key, Dove still transcribes locally and can insert the raw transcript.
              Nothing is sent for polishing.
            </p>
            <p className="text-[14px]">
              Third-party terms apply to whichever provider you choose (OpenAI, Anthropic, etc.).
            </p>
          </PrivacySection>

          <PrivacySection title="Permissions">
            <ul className="privacy-list">
              <li>
                <strong className="font-medium text-ink">Microphone</strong> - to capture speech
                while you hold the hotkey.
              </li>
              <li>
                <strong className="font-medium text-ink">Accessibility</strong> - to register the
                global hotkey and type into other apps. Dove does not read your screen beyond the
                focused text field.
              </li>
            </ul>
          </PrivacySection>

          <PrivacySection title="Diagnostics">
            <p>
              If something breaks, you can export a diagnostic report from{" "}
              <span className="font-mono text-[13px] text-ink/80">
                Preferences → Contact → Export Report
              </span>
              . Reports include app version, environment details, and error logs - never transcripts,
              prompts, or API keys.
            </p>
            <p>Nothing is uploaded automatically. You attach the file only if you choose to email it.</p>
          </PrivacySection>

          <PrivacySection title="This website">
            <p>
              This marketing site does not use analytics trackers or advertising pixels. If you
              deploy it yourself, your host may keep standard server access logs.
            </p>
          </PrivacySection>

          <PrivacySection title="Open source">
            <p>
              Dove&apos;s source is public. You can inspect exactly what the app does with your data
              before you run it.
            </p>
            <p>
              <a
                href={siteConfig.githubUrl}
                target="_blank"
                rel="noopener noreferrer"
                className="link-accent font-medium"
              >
                View source on GitHub →
              </a>
            </p>
          </PrivacySection>

          <PrivacySection title="Contact">
            <p>
              Questions about privacy? Email{" "}
              <a href={`mailto:${siteConfig.supportEmail}`} className="link-accent font-medium">
                {siteConfig.supportEmail}
              </a>
              .
            </p>
          </PrivacySection>
        </div>

        <div className="mt-10 flex flex-col items-center gap-4 sm:flex-row sm:justify-between">
          <Link
            href="/"
            className="text-[14px] font-medium text-ink-muted transition-colors hover:text-ink"
          >
            ← Back to home
          </Link>
          <Link href="/#contact" className="link-accent text-[14px] font-medium">
            Get in touch
          </Link>
        </div>
      </article>
    </div>
  );
}
