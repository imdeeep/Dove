import { Compare } from "@/components/Compare";
import { Contact } from "@/components/Contact";
import { FAQ } from "@/components/FAQ";
import { Features } from "@/components/Features";
import { Hero } from "@/components/Hero/Hero";
import { HowItWorks } from "@/components/HowItWorks";
import { Setup } from "@/components/Setup";
import { WhatWeOffer } from "@/components/WhatWeOffer";
import { WhyFree } from "@/components/WhyFree";
import { buildMetadata } from "@/lib/seo";

export const metadata = buildMetadata({ path: "/" });

export default function Home() {
  return (
    <>
      <Hero />
      <HowItWorks />
      <WhatWeOffer />
      <Features />
      <div className="page-lower">
        <Compare />
        <WhyFree />
        <Setup />
        <FAQ />
        <Contact />
      </div>
    </>
  );
}
