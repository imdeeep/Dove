export type FaqContentEntry = {
  q: string;
  a: string;
};

export const faqContent: FaqContentEntry[] = [
  {
    q: "What is Dove?",
    a: "Free, open-source macOS menu bar app. Hotkey → speak → polished text at your cursor.",
  },
  {
    q: "Does it cost money?",
    a: "No. Optional API costs go to your AI provider, not Dove.",
  },
  {
    q: "Does my voice leave my Mac?",
    a: "No. Whisper runs locally. Only text goes to your AI provider if you add a key.",
  },
  {
    q: "What if Gatekeeper blocks the app?",
    a: "Right-click → Open → confirm. Standard for non-App Store apps.",
  },
  {
    q: "Default hotkey?",
    a: "Default is ⌘⇧X - change it in Preferences → Hotkey.",
  },
  {
    q: "Works without an API key?",
    a: "Yes. Raw transcript inserts instead of a polished prompt.",
  },
  {
    q: "Why Accessibility permission?",
    a: "Global hotkey and typing into other apps. No screen reading beyond the focused field.",
  },
  {
    q: "Something broken?",
    a: "Export diagnostics from Preferences → Contact, then contact Mandeep.",
  },
];
