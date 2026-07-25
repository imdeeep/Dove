"use client";

import dynamic from "next/dynamic";
import { FeatureTheaterFallback } from "./FeatureTheaterFallback";

const FeatureTheater = dynamic(
  () => import("./FeatureTheater.client").then((mod) => mod.FeatureTheater),
  {
    ssr: false,
    loading: () => <FeatureTheaterFallback />,
  },
);

export function FeatureTheaterLoader() {
  return <FeatureTheater />;
}
