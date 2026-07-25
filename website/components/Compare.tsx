import { DownloadButton } from "./ui/DownloadButton";
import { Section, SectionHeader } from "./ui/Section";
import { Reveal } from "./motion/Reveal";

type CellValue = boolean | "varies" | "cloud" | "-" | "locked" | "rare" | "freemium";

function Cell({ value }: { value: CellValue }) {
  if (value === true) return <span className="font-semibold text-success">✓</span>;
  if (value === "-") return <span className="text-white/25">-</span>;
  return <span className="text-[11px] text-white/45">{value}</span>;
}

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

export function Compare() {
  return (
    <Section id="compare" variant="dark" containerClassName="max-w-[980px]">
      <Reveal>
        <SectionHeader
          dark
          centered
          label="Compare"
          title="Not another dictation app."
          intro="Every tool below does part of the job. Dove does the whole pipeline - local ears, cloud polish, cursor insertion - in one hotkey."
        />
      </Reveal>

      <Reveal>
        <p className="mb-2 text-center text-[11px] text-white/40 md:hidden">Swipe to compare</p>
        <div className="compare-scroll-wrap max-md:pb-1">
          <div className="compare-scroll overflow-x-auto rounded-xl border border-hairline-dark">
          <table className="w-full min-w-[720px] text-left text-[12px]">
            <thead>
              <tr className="border-b border-hairline-dark text-white/50">
                <th scope="col" className="px-3 py-3 font-medium" />
                <th scope="col" className="px-3 py-3 font-semibold text-white">
                  Dove
                </th>
                <th scope="col" className="px-3 py-3 font-medium">
                  Whisper (CLI)
                </th>
                <th scope="col" className="px-3 py-3 font-medium">
                  Dictation apps
                </th>
                <th scope="col" className="px-3 py-3 font-medium">
                  macOS Dictation
                </th>
                <th scope="col" className="px-3 py-3 font-medium">
                  AI assistants
                </th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.label} className="border-b border-hairline-dark/70">
                  <th scope="row" className="px-3 py-2 font-normal text-white/75">
                    {row.label}
                  </th>
                  <td className="px-3 py-2 text-center">
                    <Cell value={row.dove} />
                  </td>
                  <td className="px-3 py-2 text-center">
                    <Cell value={row.whisper} />
                  </td>
                  <td className="px-3 py-2 text-center">
                    <Cell value={row.dictation} />
                  </td>
                  <td className="px-3 py-2 text-center">
                    <Cell value={row.macos} />
                  </td>
                  <td className="px-3 py-2 text-center">
                    <Cell value={row.ai} />
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        </div>
      </Reveal>

      <Reveal className="mt-10 text-center">
        <p className="mx-auto max-w-2xl font-serif text-[16px] italic leading-relaxed text-white/80 md:text-[18px]">
          Whisper is the engine. Dictation apps give you raw words. macOS types literally. AI
          assistants want a conversation. Dove is the layer in between - and it disappears when the
          job is done.
        </p>
      </Reveal>

      <Reveal className="mt-8 flex justify-center">
        <DownloadButton variant="ghost-on-dark" />
      </Reveal>
    </Section>
  );
}
