import { DownloadButton } from "./ui/DownloadButton";
import { Section, SectionHeader } from "./ui/Section";
import { Reveal } from "./motion/Reveal";

type CellValue = boolean | "varies" | "cloud" | "-" | "locked" | "rare" | "freemium";

function Cell({ value, compact }: { value: CellValue; compact?: boolean }) {
  if (value === true) {
    return <span className={`font-semibold text-success ${compact ? "text-[12px]" : ""}`}>✓</span>;
  }
  if (value === "-") {
    return <span className={`text-white/25 ${compact ? "text-[12px]" : ""}`}>-</span>;
  }
  return (
    <span className={`text-white/45 ${compact ? "text-[9px]" : "text-[11px]"}`}>{value}</span>
  );
}

const competitors = [
  { key: "whisper", label: "Whisper", longLabel: "Whisper (CLI)" },
  { key: "dictation", label: "Dictation", longLabel: "Dictation apps" },
  { key: "macos", label: "macOS", longLabel: "macOS Dictation" },
  { key: "ai", label: "AI apps", longLabel: "AI assistants" },
] as const;

type RowKey = "dove" | (typeof competitors)[number]["key"];

const rows: {
  label: string;
  dove: CellValue;
  whisper: CellValue;
  dictation: CellValue;
  macos: CellValue;
  ai: CellValue;
}[] = [
  { label: "Finished macOS app", dove: true, whisper: "-", dictation: true, macos: true, ai: true },
  { label: "Local transcription", dove: true, whisper: true, dictation: "varies", macos: "cloud", ai: "cloud" },
  { label: "AI prompt polishing", dove: true, whisper: "-", dictation: "rare", macos: "-", ai: "locked" },
  { label: "Inserts at cursor", dove: true, whisper: "-", dictation: true, macos: true, ai: "-" },
  { label: "Works in any app", dove: true, whisper: "-", dictation: true, macos: true, ai: "-" },
  { label: "Your AI provider", dove: true, whisper: "-", dictation: "locked", macos: "-", ai: "locked" },
  { label: "No chat UI", dove: true, whisper: true, dictation: "-", macos: true, ai: "-" },
  { label: "No data storage", dove: true, whisper: true, dictation: "varies", macos: "-", ai: "-" },
  { label: "Open source", dove: true, whisper: true, dictation: "-", macos: "-", ai: "-" },
  { label: "Free", dove: true, whisper: true, dictation: "varies", macos: true, ai: "freemium" },
  { label: "Smart word-by-word typing", dove: true, whisper: "-", dictation: "-", macos: "-", ai: "-" },
  { label: "Developer-focused", dove: true, whisper: true, dictation: "-", macos: "-", ai: "-" },
];

function CompareMobileList() {
  return (
    <ul className="divide-y divide-hairline-dark overflow-hidden rounded-xl border border-hairline-dark md:hidden">
      {rows.map((row) => (
        <li key={row.label} className="bg-white/[0.02] px-3.5 py-3">
          <p className="text-[13px] font-medium leading-snug text-white/85">{row.label}</p>

          <div className="mt-2.5 flex items-center gap-2">
            <div className="inline-flex shrink-0 items-center gap-1.5 rounded-lg border border-primary-on-dark/20 bg-primary-on-dark/10 px-2.5 py-1">
              <span className="text-[10px] font-semibold tracking-wide text-primary-on-dark uppercase">
                Dove
              </span>
              <Cell value={row.dove} compact />
            </div>
          </div>

          <div className="mt-2 flex flex-wrap gap-x-3 gap-y-1.5">
            {competitors.map((competitor) => (
              <span
                key={competitor.key}
                className="inline-flex items-center gap-1 text-[10px] text-white/40"
              >
                <span className="text-white/35">{competitor.label}</span>
                <Cell value={row[competitor.key]} compact />
              </span>
            ))}
          </div>
        </li>
      ))}
    </ul>
  );
}

function CompareDesktopTable() {
  return (
    <div className="compare-scroll hidden overflow-x-auto rounded-xl border border-hairline-dark md:block">
      <table className="w-full min-w-[720px] text-left text-[12px]">
        <thead>
          <tr className="border-b border-hairline-dark text-white/50">
            <th scope="col" className="px-3 py-3 font-medium" />
            <th scope="col" className="px-3 py-3 font-semibold text-white">
              Dove
            </th>
            {competitors.map((competitor) => (
              <th key={competitor.key} scope="col" className="px-3 py-3 font-medium">
                {competitor.longLabel}
              </th>
            ))}
          </tr>
        </thead>
        <tbody>
          {rows.map((row) => (
            <tr key={row.label} className="border-b border-hairline-dark/70">
              <th scope="row" className="px-3 py-2 font-normal text-white/75">
                {row.label}
              </th>
              {( ["dove", ...competitors.map((c) => c.key)] as RowKey[] ).map((key) => (
                <td key={key} className="px-3 py-2 text-center">
                  <Cell value={row[key]} />
                </td>
              ))}
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

export function Compare() {
  return (
    <Section id="compare" variant="dark" className="max-md:py-16" containerClassName="max-w-[980px]">
      <Reveal>
        <SectionHeader
          dark
          centered
          label="Compare"
          title="Not another dictation app."
          intro="Every tool below does part of the job. Dove does the whole pipeline - local ears, cloud polish, cursor insertion - in one hotkey."
          className="max-md:mb-8"
          titleClassName="max-md:text-[28px] max-md:leading-[1.12]"
          introClassName="max-md:mt-3 max-md:max-w-[18rem] max-md:text-[15px] max-md:leading-relaxed"
        />
      </Reveal>

      <Reveal>
        <CompareMobileList />
        <CompareDesktopTable />
      </Reveal>

      <Reveal className="mt-8 text-center md:mt-10">
        <p className="mx-auto max-w-2xl font-serif text-[15px] italic leading-relaxed text-white/80 max-md:max-w-[18rem] md:text-[18px]">
          Whisper is the engine. Dictation apps give you raw words. macOS types literally. AI
          assistants want a conversation. Dove is the layer in between - and it disappears when the
          job is done.
        </p>
      </Reveal>

      <Reveal className="mt-6 flex justify-center md:mt-8">
        <DownloadButton variant="ghost-on-dark" />
      </Reveal>
    </Section>
  );
}
