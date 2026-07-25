"use client";

import { useEffect, useRef, useState, type RefObject } from "react";
import {
  FEATURE_THEATER_CRITICAL_CSS,
  POLISHED,
  POLISHED_WORDS,
  RAW_TOKENS,
  phaseAt,
  tokensAt,
  wordsAt,
  type Phase,
} from "./feature-theater-shared";

function useVisible(ref: RefObject<HTMLDivElement | null>) {
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    const node = ref.current;
    if (!node) return;

    const observer = new IntersectionObserver(
      ([entry]) => {
        if (entry?.isIntersecting) {
          setVisible(true);
          observer.disconnect();
        }
      },
      { threshold: 0.2 },
    );

    observer.observe(node);
    return () => observer.disconnect();
  }, [ref]);

  return visible;
}

function usePrefersReducedMotion() {
  const [reduced, setReduced] = useState(false);

  useEffect(() => {
    const media = window.matchMedia("(prefers-reduced-motion: reduce)");
    const update = () => setReduced(media.matches);
    update();
    media.addEventListener("change", update);
    return () => media.removeEventListener("change", update);
  }, []);

  return reduced;
}

function DoveWaveform({
  active,
  compact = false,
}: {
  active: boolean;
  compact?: boolean;
}) {
  const heights = compact ? [6, 12, 8] : [9, 12, 18, 10, 22, 14, 9];

  return (
    <div
      className={compact ? "dove-wave-bars dove-wave-bars-compact" : "dove-wave-bars"}
      aria-hidden
    >
      {heights.map((h, i) => (
        <span
          key={i}
          className={`${compact ? "w-0.5" : "w-[3px]"} ${active ? "dove-wave-bar" : "dove-wave-bar-off"}`}
          style={{
            height: h,
            animationDelay: active ? `${i * 0.08}s` : undefined,
            animationDuration: active ? `${0.95 + (i % 3) * 0.12}s` : undefined,
          }}
        />
      ))}
    </div>
  );
}

function DoneIcon() {
  return (
    <svg width="18" height="18" viewBox="0 0 18 18" fill="none" aria-hidden>
      <circle cx="9" cy="9" r="8" fill="rgba(255,255,255,0.14)" />
      <circle cx="9" cy="9" r="7.25" stroke="rgba(255,255,255,0.55)" strokeWidth="1" />
      <path
        d="M5.4 9.15 7.7 11.4l5-5.2"
        stroke="rgba(255,255,255,0.92)"
        strokeWidth="1.6"
        strokeLinecap="round"
        strokeLinejoin="round"
      />
    </svg>
  );
}

function DoveHUD({ phase, animate }: { phase: Phase; animate: boolean }) {
  const listening = phase === "listen" || phase === "raw";
  const done = phase === "hold";

  const label =
    phase === "scrub"
      ? "Transcribing…"
      : phase === "polish"
        ? "Polishing Prompt…"
        : phase === "type"
          ? "Inserting…"
          : done
            ? "Done"
            : null;

  const waveActive =
    animate &&
    (listening || phase === "scrub" || phase === "polish" || phase === "type");

  return (
    <div className={`dove-hud ${listening ? "dove-hud-listen" : "dove-hud-process"}`}>
      <div className="dove-hud-sheen" aria-hidden />
      <div className="dove-hud-sheen-drift" aria-hidden />

      <div className="relative z-[1] flex items-center gap-3">
        {listening ? (
          <DoveWaveform active={waveActive} />
        ) : done ? (
          <>
            <DoneIcon />
            <span
              className="text-[14px] font-semibold tracking-[-0.01em]"
              style={{ color: "rgba(255,255,255,0.88)" }}
            >
              Done
            </span>
          </>
        ) : (
          <>
            <DoveWaveform active={waveActive} compact />
            <span
              className="text-[14px] font-semibold tracking-[-0.01em]"
              style={{ color: "rgba(255,255,255,0.88)" }}
            >
              {label}
            </span>
          </>
        )}
      </div>
    </div>
  );
}

function PhaseDots({ phase }: { phase: Phase }) {
  const index =
    phase === "listen"
      ? 0
      : phase === "raw"
        ? 1
        : phase === "scrub"
          ? 2
          : phase === "polish"
            ? 3
            : 4;

  return (
    <div className="relative z-[1] flex items-center justify-center gap-1.5" aria-hidden>
      {[0, 1, 2, 3, 4].map((i) => (
        <span
          key={i}
          className={`h-1 rounded-full transition-all duration-300 ${
            i === index
              ? "w-4 bg-primary"
              : i < index || phase === "hold"
                ? "w-1 bg-primary/35"
                : "w-1 bg-ink/12"
          }`}
        />
      ))}
    </div>
  );
}

export function FeatureTheater() {
  const reduced = usePrefersReducedMotion();
  const ref = useRef<HTMLDivElement>(null);
  const visible = useVisible(ref);
  const startRef = useRef(0);
  const [snapshot, setSnapshot] = useState({
    phase: "listen" as Phase,
    tokens: 0,
    words: 0,
  });

  useEffect(() => {
    if (!visible || reduced) return;

    startRef.current = performance.now();
    const id = window.setInterval(() => {
      const elapsed = performance.now() - startRef.current;
      const phase = phaseAt(elapsed);
      const tokens = tokensAt(elapsed, phase);
      const words = wordsAt(elapsed, phase);

      setSnapshot((prev) =>
        prev.phase === phase && prev.tokens === tokens && prev.words === words
          ? prev
          : { phase, tokens, words },
      );
    }, 100);

    return () => window.clearInterval(id);
  }, [visible, reduced]);

  const phase = reduced ? "hold" : snapshot.phase;
  const wordCount = reduced ? POLISHED_WORDS.length : snapshot.words;
  const tokenVisible = reduced ? RAW_TOKENS.length : snapshot.tokens;

  const showTranscript = phase !== "listen";
  const showRawLayer = phase === "raw" || phase === "scrub";
  const showResult = phase === "polish" || phase === "type" || phase === "hold";
  const isTyping = phase === "type" || phase === "hold";

  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: FEATURE_THEATER_CRITICAL_CSS }} />
      <div ref={ref} className="feature-theater">
        <div className="feature-theater-glow" aria-hidden />

        <DoveHUD phase={phase} animate={!reduced} />
        <PhaseDots phase={phase} />

        <div className="feature-stage">
          <div className="feature-transcript">
            {!showTranscript && (
              <div className="flex h-full flex-col justify-center">
                <p className="text-[11px] font-semibold uppercase tracking-widest text-ink-muted/60">
                  You said
                </p>
                <p className="mt-2.5 font-mono text-[13px] text-ink-muted/30 md:text-[14px]">
                  Waiting for speech…
                </p>
              </div>
            )}

            {showRawLayer && (
              <div>
                <p className="text-[11px] font-semibold uppercase tracking-widest text-ink-muted/70">
                  You said
                </p>
                <p className="mt-2.5 font-mono text-[13px] leading-[1.6] text-ink-muted md:text-[14px]">
                  {RAW_TOKENS.map((token, i) => {
                    const visibleToken = i < tokenVisible || phase === "scrub" || reduced;
                    const struck = phase === "scrub" && token.kind === "filler";
                    return (
                      <span
                        key={`${token.text}-${i}`}
                        className={`transition-opacity duration-300 ${
                          !visibleToken
                            ? "opacity-0"
                            : struck
                              ? "text-ink-muted/40 line-through decoration-ink-muted/45"
                              : "opacity-100"
                        }`}
                      >
                        {token.text}
                      </span>
                    );
                  })}
                </p>
              </div>
            )}

            {showResult && (
              <div>
                <div className="flex items-center justify-between gap-3">
                  <p className="text-[11px] font-semibold uppercase tracking-widest text-primary">
                    {isTyping ? "At your cursor" : "Dove writes"}
                  </p>
                  {isTyping && <span className="text-[11px] text-ink-muted">any app</span>}
                </div>

                <p className="mt-2.5 text-[15px] leading-[1.55] tracking-[-0.01em] text-ink md:text-[16px]">
                  {phase === "polish" ? (
                    POLISHED
                  ) : (
                    <>
                      {POLISHED_WORDS.slice(0, wordCount).map((word, i) => (
                        <span key={i}>
                          {i > 0 ? " " : ""}
                          {word}
                        </span>
                      ))}
                      {wordCount > 0 && !reduced && (
                        <span className="feature-cursor-blink ml-0.5 inline-block h-[1em] w-0.5 translate-y-px bg-primary align-middle" />
                      )}
                    </>
                  )}
                </p>
              </div>
            )}
          </div>
        </div>
      </div>
    </>
  );
}
