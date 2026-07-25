import { siteConfig } from "@/lib/site-config";
import { cn } from "@/lib/utils";

type HotkeySize = "xs" | "sm" | "md";
type HotkeyTone = "default" | "dark" | "inline";

const sizes: Record<
  HotkeySize,
  { cap: string; letter: string; gap: string; pad: string }
> = {
  xs: {
    cap: "h-5 w-5 rounded-[5px]",
    letter: "text-[10px]",
    gap: "gap-[3px]",
    pad: "p-[3px]",
  },
  sm: {
    cap: "h-[18px] w-[18px] rounded-[4px]",
    letter: "text-[10px]",
    gap: "gap-[3px]",
    pad: "p-[2px]",
  },
  md: {
    cap: "h-6 w-6 rounded-[6px]",
    letter: "text-[12px]",
    gap: "gap-1",
    pad: "p-1",
  },
};

const capThemes: Record<HotkeyTone, string> = {
  default:
    "border-black/[0.08] bg-white text-ink shadow-[0_1px_0_rgba(0,0,0,0.05)]",
  dark: "border-white/14 bg-white/10 text-white/90",
  inline:
    "border-black/[0.05] bg-black/[0.03] text-ink-muted shadow-none",
};

function CommandGlyph({ size }: { size: HotkeySize }) {
  const s = sizes[size];
  return (
    <span
      className={cn(
        s.letter,
        "select-none font-[system-ui,-apple-system,BlinkMacSystemFont,sans-serif] leading-none",
      )}
      aria-hidden
    >
      ⌘
    </span>
  );
}

function ShiftGlyph({ size }: { size: HotkeySize }) {
  const s = sizes[size];
  return (
    <span
      className={cn(
        s.letter,
        "select-none font-[system-ui,-apple-system,BlinkMacSystemFont,sans-serif] leading-none",
      )}
      aria-hidden
    >
      ⇧
    </span>
  );
}

function KeyCap({
  children,
  size,
  tone,
}: {
  children: React.ReactNode;
  size: HotkeySize;
  tone: HotkeyTone;
}) {
  const s = sizes[size];

  return (
    <span
      className={cn(
        "inline-flex shrink-0 items-center justify-center border",
        s.cap,
        capThemes[tone],
      )}
    >
      {children}
    </span>
  );
}

function KeyGlyph({
  keyLabel,
  size,
  tone,
}: {
  keyLabel: string;
  size: HotkeySize;
  tone: HotkeyTone;
}) {
  const s = sizes[size];

  if (keyLabel === "⌘") {
    return (
      <KeyCap size={size} tone={tone}>
        <CommandGlyph size={size} />
      </KeyCap>
    );
  }

  if (keyLabel === "⇧") {
    return (
      <KeyCap size={size} tone={tone}>
        <ShiftGlyph size={size} />
      </KeyCap>
    );
  }

  return (
    <KeyCap size={size} tone={tone}>
      <span className={cn(s.letter, "font-medium leading-none")}>{keyLabel}</span>
    </KeyCap>
  );
}

/** Segmented ⌘ ⇧ X */
export function HotkeyKeys({
  className,
  tone = "default",
  size = "md",
  dark = false,
}: {
  className?: string;
  tone?: HotkeyTone;
  size?: HotkeySize;
  /** @deprecated use tone="dark" */
  dark?: boolean;
}) {
  const s = sizes[size];
  const resolvedTone = tone === "default" && dark ? "dark" : tone;

  return (
    <span
      className={cn("inline-flex items-center align-middle", s.gap, className)}
      role="img"
      aria-label={`Keyboard shortcut ${siteConfig.defaultHotkey}`}
    >
      {siteConfig.hotkeyKeys.map((key) => (
        <KeyGlyph key={key} keyLabel={key} size={size} tone={resolvedTone} />
      ))}
    </span>
  );
}

export function HotkeyPill({
  className,
  tone = "default",
  size = "md",
  bare = false,
  /** @deprecated use tone="dark" */
  dark = false,
}: {
  className?: string;
  tone?: HotkeyTone;
  size?: HotkeySize;
  bare?: boolean;
  dark?: boolean;
}) {
  const resolvedTone = dark && tone === "default" ? "dark" : tone;

  if (bare || resolvedTone === "inline") {
    return <HotkeyKeys className={className} tone={resolvedTone} size={size} />;
  }

  const s = sizes[size];

  return (
    <kbd
      className={cn(
        "inline-flex items-center justify-center align-middle",
        s.pad,
        s.gap,
        "rounded-[9px] border",
        resolvedTone === "dark"
          ? "border-white/10 bg-white/[0.05]"
          : "border-black/[0.06] bg-canvas-elevated/95 shadow-[0_1px_2px_rgba(0,0,0,0.04)]",
        className,
      )}
    >
      <HotkeyKeys tone={resolvedTone} size={size} />
    </kbd>
  );
}
