import { siteConfig } from "@/lib/site-config";
import { cn } from "@/lib/utils";

export function CreatorLink({ className }: { className?: string }) {
  return (
    <a
      href={siteConfig.creatorLinkedInUrl}
      target="_blank"
      rel="me noopener noreferrer"
      className={cn("font-medium text-ink transition-colors hover:text-primary", className)}
    >
      {siteConfig.creator}
    </a>
  );
}
