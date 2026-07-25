import { FEATURE_THEATER_CRITICAL_CSS } from "./feature-theater-shared";

/** Server-rendered shell - styled even before JS hydrates (Safari-safe) */
export function FeatureTheaterFallback() {
  return (
    <>
      <style dangerouslySetInnerHTML={{ __html: FEATURE_THEATER_CRITICAL_CSS }} />
      <div className="feature-theater" aria-hidden>
        <div className="feature-theater-glow" />
        <div className="dove-hud dove-hud-listen">
          <div className="dove-hud-sheen" />
          <div className="dove-wave-bars">
            {[9, 14, 18, 10, 22, 14, 9].map((h, i) => (
              <span key={i} className="dove-wave-bar" style={{ height: h }} />
            ))}
          </div>
        </div>
        <div className="relative z-[1] flex items-center justify-center gap-1.5">
          <span className="h-1 w-4 rounded-full bg-[#0066cc]" />
          {[0, 1, 2, 3].map((i) => (
            <span key={i} className="h-1 w-1 rounded-full bg-[rgba(0,0,0,0.12)]" />
          ))}
        </div>
        <div className="feature-stage">
          <div className="feature-transcript">
            <p className="text-[11px] font-semibold uppercase tracking-widest text-[#6e6e73]">
              You said
            </p>
            <p className="mt-2.5 font-mono text-[13px] text-[rgba(110,110,115,0.3)]">
              Waiting for speech…
            </p>
          </div>
        </div>
      </div>
    </>
  );
}
