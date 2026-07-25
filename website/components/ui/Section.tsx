import { cn } from "@/lib/utils";

type SectionVariant = "light" | "parchment" | "warm" | "dark" | "primary";

interface SectionProps {
  id: string;
  variant?: SectionVariant;
  className?: string;
  children: React.ReactNode;
  containerClassName?: string;
}

const variantStyles: Record<SectionVariant, string> = {
  light: "bg-canvas text-ink",
  parchment: "bg-canvas-subtle text-ink",
  warm: "bg-canvas text-ink",
  dark: "bg-surface-tile-dark text-white",
  primary: "bg-primary text-white",
};

export function Section({
  id,
  variant = "light",
  className,
  containerClassName,
  children,
}: SectionProps) {
  return (
    <section id={id} className={cn("py-20 md:py-32", variantStyles[variant], className)}>
      <div className={cn("mx-auto w-full max-w-[980px] px-6 md:px-8", containerClassName)}>
        {children}
      </div>
    </section>
  );
}

interface SectionHeaderProps {
  label?: string;
  title: string;
  intro?: string;
  dark?: boolean;
  className?: string;
  centered?: boolean;
}

export function SectionHeader({
  label,
  title,
  intro,
  dark,
  className,
  centered,
}: SectionHeaderProps) {
  return (
    <header className={cn("mb-14 md:mb-16", centered && "text-center", className)}>
      {label && (
        <p className={cn("section-label mb-4", dark && "text-primary-on-dark")}>{label}</p>
      )}
      <h2
        className={cn(
          "text-[34px] font-semibold tracking-[-0.03em] md:text-[44px] md:leading-[1.1]",
          dark ? "text-white" : "text-ink",
        )}
      >
        {title}
      </h2>
      {intro && (
        <p
          className={cn(
            "mt-5 max-w-2xl text-[17px] leading-relaxed md:text-[19px]",
            centered && "mx-auto",
            dark ? "text-white/65" : "text-ink-muted",
          )}
        >
          {intro}
        </p>
      )}
    </header>
  );
}
