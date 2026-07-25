export const RAW_TOKENS = [
  { text: "um", kind: "filler" as const },
  { text: " so i want to ", kind: "keep" as const },
  { text: "like", kind: "filler" as const },
  { text: " add a dark mode toggle ", kind: "keep" as const },
  { text: "you know", kind: "filler" as const },
  { text: " and it should remember what the user picked", kind: "keep" as const },
];

export const POLISHED =
  "Add a dark mode toggle. It should remember and save the user's choice.";

export const POLISHED_WORDS = POLISHED.split(" ");

export type Phase = "listen" | "raw" | "scrub" | "polish" | "type" | "hold";

export const TIMING = {
  raw: 1100,
  scrub: 3200,
  polish: 5200,
  type: 6800,
  wordMs: 95,
  holdExtra: 1200,
  restartExtra: 3200,
};

export const TYPE_DURATION = POLISHED_WORDS.length * TIMING.wordMs;
export const CYCLE_MS = TIMING.type + TYPE_DURATION + TIMING.holdExtra + TIMING.restartExtra;

export function phaseAt(elapsed: number): Phase {
  const t = elapsed % CYCLE_MS;
  if (t < TIMING.raw) return "listen";
  if (t < TIMING.scrub) return "raw";
  if (t < TIMING.polish) return "scrub";
  if (t < TIMING.type) return "polish";
  if (t < TIMING.type + TYPE_DURATION) return "type";
  if (t < TIMING.type + TYPE_DURATION + TIMING.holdExtra) return "hold";
  return "listen";
}

export function tokensAt(elapsed: number, phase: Phase): number {
  if (phase === "listen") return 0;
  if (phase !== "raw") return RAW_TOKENS.length;
  const intoRaw = (elapsed % CYCLE_MS) - TIMING.raw;
  return Math.min(RAW_TOKENS.length, Math.floor(intoRaw / 120) + 1);
}

export function wordsAt(elapsed: number, phase: Phase): number {
  if (phase === "hold") return POLISHED_WORDS.length;
  if (phase !== "type") return 0;
  const intoType = (elapsed % CYCLE_MS) - TIMING.type;
  return Math.min(POLISHED_WORDS.length, Math.floor(intoType / TIMING.wordMs) + 1);
}

/** Inlined so Safari always gets layout even if a CSS chunk fails to load on refresh */
export const FEATURE_THEATER_CRITICAL_CSS = `
.feature-theater{position:relative;display:flex;flex-direction:column;align-items:center;gap:.875rem}
.feature-theater-glow{position:absolute;top:8%;left:50%;z-index:0;width:min(480px,90%);height:200px;transform:translateX(-50%);pointer-events:none;background:radial-gradient(ellipse at center,rgba(0,0,0,.06),transparent 70%)}
.dove-hud{position:relative;z-index:1;display:flex;align-items:center;justify-content:center;height:48px;overflow:hidden;border-radius:9999px;border:.5px solid rgba(255,255,255,.08);background:linear-gradient(180deg,#1f1f1f 0%,#1a1a1a 50%,#141414 100%);box-shadow:0 12px 40px rgba(0,0,0,.28),inset 0 1px 0 rgba(255,255,255,.04)}
.dove-hud-listen{width:280px}
.dove-hud-process{width:max-content;min-width:210px;padding:0 1.5rem}
.dove-hud-sheen{pointer-events:none;position:absolute;inset:0;background:linear-gradient(180deg,rgba(255,255,255,.04) 0%,transparent 55%)}
.feature-stage{position:relative;z-index:1;width:100%;max-width:640px;border-radius:24px;border:1px solid rgba(0,0,0,.08);background:#fff;padding:1.2rem 1.4rem 1.3rem;box-shadow:0 8px 40px rgba(0,0,0,.06),0 1px 2px rgba(0,0,0,.04)}
.feature-transcript{position:relative;min-height:6.25rem}
.feature-rails{display:grid;gap:2rem;margin:3rem auto 0;max-width:820px;list-style:none;padding:0}
@media(min-width:640px){.feature-rails{grid-template-columns:repeat(3,1fr);gap:0;margin-top:3.5rem}.feature-rail{padding:0 1.5rem;border-left:1px solid rgba(0,0,0,.08)}.feature-rail:first-child{border-left:none;padding-left:0}.feature-rail:last-child{padding-right:0}}
.dove-wave-bars{display:flex;align-items:center;justify-content:center;gap:4px;height:20px}
.dove-wave-bar{display:inline-block;width:3px;height:14px;border-radius:9999px;background:linear-gradient(180deg,rgba(255,255,255,.85),rgba(255,255,255,.45));transform:scaleY(.7)}
@media(max-width:639px){.dove-hud-listen{width:min(280px,calc(100vw - 3rem))}.dove-hud-process{max-width:calc(100vw - 3rem)}}
`;
