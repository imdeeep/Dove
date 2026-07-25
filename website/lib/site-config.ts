export const siteConfig = {
  name: "Dove",
  tagline: "Speak it. Dove writes it.",
  description:
    "Dove turns how you talk into what you meant to type - polished, punctuated, and inserted exactly where your cursor already is.",
  githubUrl: process.env.NEXT_PUBLIC_GITHUB_URL ?? "#",
  downloadUrl: process.env.NEXT_PUBLIC_DOWNLOAD_URL ?? "/download",
  supportEmail: "mandeep7yadav@gmail.com",
  creator: "Mandeep",
  creatorLinkedInUrl:
    process.env.NEXT_PUBLIC_LINKEDIN_URL ?? "https://www.linkedin.com/in/mandeep7yadav",
  defaultHotkey: "⌘⇧X",
  hotkeyKeys: ["⌘", "⇧", "X"] as const,
  version: "v1.0.0",
} as const;

export const hotkeyLabel = siteConfig.hotkeyKeys.join(" ");

/** Dock nav */
export const navLinks = [
  { href: "#how-it-works", label: "How it works" },
  { href: "#features", label: "Features" },
  { href: "#compare", label: "Compare" },
  { href: "#setup", label: "Setup" },
  { href: "#faq", label: "FAQ" },
] as const;

export const footerNavLinks = [
  { href: "#how-it-works", label: "How it works" },
  { href: "#features", label: "Features" },
  { href: "#compare", label: "Compare" },
  { href: "#setup", label: "Setup" },
  { href: "#faq", label: "FAQ" },
] as const;
