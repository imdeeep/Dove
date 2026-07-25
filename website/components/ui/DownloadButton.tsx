import { siteConfig } from "@/lib/site-config";
import { AppleMark, Button } from "./Button";

export function DownloadButton({
  variant = "primary",
  className,
  label = "Download for Mac",
}: {
  variant?: "primary" | "secondary" | "ghost" | "ghost-on-dark" | "dock";
  className?: string;
  label?: string;
}) {
  return (
    <Button href={siteConfig.downloadUrl} variant={variant} className={className}>
      <AppleMark />
      {label}
    </Button>
  );
}
