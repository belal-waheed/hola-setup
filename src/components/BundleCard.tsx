import { Check, Copy, Download, FolderInput } from 'lucide-react';

export interface BundleEntry {
  id: string;
  title: string;
  category: string;
  targetPath: string;
  summary: string;
  fileName: string;
  href: string;
  sizeBytes: number;
  sha256: string;
  files: string[];
}

interface BundleCardProps {
  bundle: BundleEntry;
  isCopied: boolean;
  onCopyHash: (bundle: BundleEntry) => void;
}

export function formatBytes(bytes: number): string {
  if (bytes < 1024) return `${bytes} B`;
  const kb = bytes / 1024;
  if (kb < 1024) return `${kb.toFixed(1)} KB`;
  return `${(kb / 1024).toFixed(2)} MB`;
}

export function BundleCard({ bundle, isCopied, onCopyHash }: BundleCardProps) {
  return (
    <article className="bundle-card">
      <header className="flex flex-col gap-2">
        <div className="flex items-center justify-between gap-2">
          <span className="text-xs font-mono uppercase tracking-wider text-[var(--text-muted)]">
            {bundle.category}
          </span>
          <span className="text-xs font-mono text-[var(--text-muted)]">
            {formatBytes(bundle.sizeBytes)}
          </span>
        </div>
        <h3 className="text-xl font-semibold tracking-tight text-[var(--text-primary)]">
          {bundle.title}
        </h3>
      </header>

      <div className="flex flex-col gap-4 min-w-0">
        <p className="text-sm text-[var(--text-muted)]">{bundle.summary}</p>

        <div className="flex items-start gap-2 rounded-lg p-3 bg-[var(--surface-subtle)] border border-[var(--border-strong)] min-w-0">
          <FolderInput className="w-4 h-4 mt-0.5 shrink-0 text-[var(--text-primary)]" aria-hidden="true" />
          <code className="text-xs font-mono break-all text-[var(--text-primary)]">
            {bundle.targetPath}
          </code>
        </div>

        <ul className="flex flex-col gap-1 text-xs font-mono text-[var(--text-muted)] list-disc ps-4">
          {bundle.files.map((file) => (
            <li key={file} className="break-all">
              {file}
            </li>
          ))}
        </ul>
      </div>

      <footer className="flex flex-wrap items-center gap-2 pt-2">
        <a
          href={bundle.href}
          download={bundle.fileName}
          className="inline-flex flex-1 items-center justify-center gap-2 min-h-[44px] px-4 py-2 rounded-lg font-medium text-sm bg-[var(--accent)] text-[var(--accent-text)] no-underline transition-opacity hover:opacity-90 active:scale-[0.98]"
        >
          <Download className="w-4 h-4 shrink-0" aria-hidden="true" />
          <span>Download {bundle.fileName}</span>
        </a>

        <button
          type="button"
          onClick={() => onCopyHash(bundle)}
          aria-label={`Copy SHA-256 checksum for ${bundle.title}`}
          className="inline-flex items-center justify-center gap-1.5 min-h-[44px] px-3 py-2 rounded-lg text-xs font-mono border border-[var(--border-strong)] bg-[var(--surface-subtle)] text-[var(--text-primary)] cursor-pointer transition-opacity hover:opacity-85 active:scale-[0.98]"
        >
          {isCopied ? (
            <>
              <Check className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>Copied</span>
            </>
          ) : (
            <>
              <Copy className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>SHA-256</span>
            </>
          )}
        </button>
      </footer>
    </article>
  );
}
