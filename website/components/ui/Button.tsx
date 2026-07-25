import Link from "next/link";
import { cn } from "@/lib/utils";

type ButtonVariant = "primary" | "secondary" | "ghost" | "ghost-on-dark" | "dock";

interface ButtonProps {
  href?: string;
  variant?: ButtonVariant;
  className?: string;
  children: React.ReactNode;
  onClick?: () => void;
  type?: "button" | "submit";
}

const variants: Record<ButtonVariant, string> = {
  primary:
    "bg-primary text-white shadow-soft hover:bg-primary-focus active:scale-[0.97] focus-visible:outline-primary-focus",
  secondary:
    "border border-primary/30 text-primary bg-canvas-elevated shadow-soft hover:bg-primary/5 active:scale-[0.97]",
  ghost:
    "border border-hairline-light text-ink bg-canvas-elevated/80 shadow-soft hover:bg-canvas-elevated active:scale-[0.97]",
  "ghost-on-dark":
    "border border-white/20 text-white bg-white/5 hover:bg-white/10 active:scale-[0.97]",
  dock:
    "bg-primary text-white shadow-soft hover:bg-primary-focus active:scale-[0.96] text-[13px] font-medium min-h-9 px-4 py-2",
};

export function Button({
  href,
  variant = "primary",
  className,
  children,
  onClick,
  type = "button",
}: ButtonProps) {
  const classes = cn(
    "inline-flex min-h-11 items-center justify-center gap-2 rounded-pill px-[22px] py-[11px] text-[17px] font-medium tracking-tight transition-all duration-200 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2",
    variants[variant],
    className,
  );

  if (href) {
    const isExternal = href.startsWith("http") || href.startsWith("mailto:");
    if (isExternal) {
      return (
        <a
          href={href}
          className={classes}
          target={href.startsWith("http") ? "_blank" : undefined}
          rel={href.startsWith("http") ? "noopener noreferrer" : undefined}
        >
          {children}
        </a>
      );
    }
    return (
      <Link href={href} className={classes}>
        {children}
      </Link>
    );
  }

  return (
    <button type={type} className={classes} onClick={onClick}>
      {children}
    </button>
  );
}

export function AppleMark({ className }: { className?: string }) {
  return (
    <svg
      className={cn("h-3.5 w-3.5", className)}
      viewBox="0 0 16 16"
      fill="currentColor"
      aria-hidden
    >
      <path d="M12.1 8.4c0-1.9 1.5-2.8 1.6-2.9-.9-1.3-2.3-1.4-2.8-1.5-1.2-.1-2.3.7-2.9.7-.6 0-1.5-.7-2.5-.7-1.3 0-2.5.7-3.1 1.9-1.4 2.3-.3 5.8 1 7.7.6.9 1.4 2 2.4 1.9 1 0 1.3-.6 2.5-.6s1.5.6 2.5.6c1 0 1.7-1 2.4-1.9.7-1.1 1-2.1 1-2.2 0 0-1.9-.7-1.9-2.9zM10.4 2.9c.5-.6.9-1.5.8-2.4-.8 0-1.7.5-2.3 1.2-.5.6-1 1.5-.9 2.3.9.1 1.8-.5 2.4-1.1z" />
    </svg>
  );
}
