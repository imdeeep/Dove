import type { Metadata } from "next";
import { faqContent } from "@/lib/faq-content";
import { siteConfig } from "@/lib/site-config";

export const siteUrl = process.env.NEXT_PUBLIC_SITE_URL ?? "https://dove.duckdns.org";

export const defaultTitle = `${siteConfig.name} - ${siteConfig.tagline}`;

export const defaultDescription =
  "Free, open-source macOS menu bar app. Hold a hotkey, speak naturally, and Dove transcribes locally with Whisper, polishes with your AI, and types it where your cursor is.";

export const seoKeywords = [
  "macOS dictation",
  "Whisper macOS",
  "voice to text Mac",
  "AI dictation",
  "local speech recognition",
  "open source dictation",
  "menu bar app",
  "developer dictation",
  "Dove app",
  "speech to text macOS",
] as const;

type BuildMetadataOptions = {
  title?: string;
  description?: string;
  path?: string;
  noIndex?: boolean;
};

function absoluteUrl(path = "/"): string {
  const normalized = path.startsWith("/") ? path : `/${path}`;
  return new URL(normalized, siteUrl).toString();
}

export function buildMetadata({
  title,
  description = defaultDescription,
  path = "/",
  noIndex = false,
}: BuildMetadataOptions = {}): Metadata {
  const canonical = absoluteUrl(path);
  const pageTitle = title ?? defaultTitle;
  const ogImage = absoluteUrl("/opengraph-image.png");

  return {
    metadataBase: new URL(siteUrl),
    title: title ? { absolute: pageTitle } : pageTitle,
    description,
    keywords: [...seoKeywords],
    applicationName: siteConfig.name,
    category: "technology",
    authors: [{ name: siteConfig.creator, url: siteConfig.creatorLinkedInUrl }],
    creator: siteConfig.creator,
    publisher: siteConfig.creator,
    alternates: {
      canonical,
    },
    robots: noIndex
      ? { index: false, follow: false }
      : {
          index: true,
          follow: true,
          googleBot: {
            index: true,
            follow: true,
            "max-image-preview": "large",
            "max-snippet": -1,
            "max-video-preview": -1,
          },
        },
    openGraph: {
      title: pageTitle,
      description,
      url: canonical,
      siteName: siteConfig.name,
      locale: "en_US",
      type: "website",
      images: [
        {
          url: ogImage,
          width: 1200,
          height: 630,
          alt: `${siteConfig.name} - ${siteConfig.tagline}`,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: pageTitle,
      description,
      images: [ogImage],
    },
    icons: {
      icon: [{ url: "/icon.png", sizes: "512x512", type: "image/png" }],
      apple: [{ url: "/apple-icon.png", sizes: "180x180", type: "image/png" }],
      shortcut: ["/favicon.ico"],
    },
  };
}

export function softwareApplicationJsonLd() {
  const version = siteConfig.version.replace(/^v/, "");

  return {
    "@context": "https://schema.org",
    "@type": "SoftwareApplication",
    name: siteConfig.name,
    description: defaultDescription,
    applicationCategory: "DeveloperApplication",
    operatingSystem: "macOS 14+",
    softwareVersion: version,
    offers: {
      "@type": "Offer",
      price: "0",
      priceCurrency: "USD",
    },
    downloadUrl: absoluteUrl("/download"),
    url: siteUrl,
    image: absoluteUrl("/dove-icon.png"),
    author: {
      "@type": "Person",
      name: siteConfig.creator,
      url: siteConfig.creatorLinkedInUrl,
    },
    sameAs: [siteConfig.githubUrl, siteConfig.creatorLinkedInUrl],
  };
}

export function webSiteJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: siteConfig.name,
    url: siteUrl,
    description: defaultDescription,
    publisher: {
      "@type": "Person",
      name: siteConfig.creator,
      url: siteConfig.creatorLinkedInUrl,
    },
  };
}

export function faqPageJsonLd() {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqContent.map((item) => ({
      "@type": "Question",
      name: item.q,
      acceptedAnswer: {
        "@type": "Answer",
        text: item.a,
      },
    })),
  };
}

export function jsonLdGraph() {
  return {
    "@context": "https://schema.org",
    "@graph": [softwareApplicationJsonLd(), webSiteJsonLd(), faqPageJsonLd()],
  };
}
