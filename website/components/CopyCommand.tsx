"use client";

import { useState } from "react";

/** A block of shell commands with a copy button. */
export function CopyCommand({ lines }: { lines: string[] }) {
  const [copied, setCopied] = useState(false);
  async function copy() {
    try {
      await navigator.clipboard.writeText(lines.join("\n"));
      setCopied(true);
      setTimeout(() => setCopied(false), 1800);
    } catch {}
  }
  return (
    <div className="relative rounded-2xl border border-ink/15 bg-ink/[0.07] backdrop-blur">
      <pre className="overflow-x-auto p-5 pr-28 font-mono text-[0.9rem] leading-7">
        <code>{lines.join("\n")}</code>
      </pre>
      <button
        type="button"
        onClick={copy}
        className="absolute right-3 top-3 rounded-full border border-ink/20 px-4 py-1.5 text-sm font-medium transition-colors hover:bg-ink/10"
      >
        {copied ? "Copied" : "Copy"}
      </button>
      <span className="sr-only" role="status">{copied ? "Copied to clipboard" : ""}</span>
    </div>
  );
}
