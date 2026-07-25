interface BeforeAfterCardProps {
  before: string;
  after: string;
  beforeLabel?: string;
  afterLabel?: string;
}

export function BeforeAfterCard({
  before,
  after,
  beforeLabel = "What you said",
  afterLabel = "What gets typed",
}: BeforeAfterCardProps) {
  return (
    <div className="grid gap-4 md:grid-cols-2">
      <div className="rounded-2xl border border-hairline-light bg-canvas-subtle/80 p-5 shadow-soft">
        <p className="mb-2 text-[11px] font-semibold tracking-[0.12em] text-ink-muted uppercase">
          {beforeLabel}
        </p>
        <p className="font-mono text-[13px] leading-relaxed text-ink-muted">{before}</p>
      </div>
      <div className="rounded-2xl border border-primary/20 bg-canvas-elevated p-5 shadow-card">
        <p className="mb-2 text-[11px] font-semibold tracking-[0.12em] text-primary uppercase">
          {afterLabel}
        </p>
        <p className="text-[16px] leading-relaxed text-ink">{after}</p>
      </div>
    </div>
  );
}
