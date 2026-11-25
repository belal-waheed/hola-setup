import { useState } from 'react';
import { Archive, Download, FileCode2, ShieldCheck } from 'lucide-react';
import manifestData from './generated/manifest.json';
import { BundleCard, formatBytes, type BundleEntry } from './components/BundleCard';

interface DirectFileEntry {
  fileName: string;
  href: string;
  sizeBytes: number;
  sha256: string;
}

interface ManifestData {
  generatedAt: string;
  allBundle: DirectFileEntry;
  directFiles: DirectFileEntry[];
  bundles: BundleEntry[];
}

const manifest = manifestData as ManifestData;

export function App() {
  const [copiedId, setCopiedId] = useState<string | null>(null);
  const [announcement, setAnnouncement] = useState<string>('');

  async function handleCopyHash(bundle: BundleEntry) {
    try {
      await navigator.clipboard.writeText(bundle.sha256);
      setCopiedId(bundle.id);
      setAnnouncement(`Copied SHA-256 checksum for ${bundle.title}.`);
    } catch {
      setAnnouncement(`Clipboard unavailable. SHA-256 for ${bundle.title} is ${bundle.sha256}.`);
    }
  }

  return (
    <>
      <a href="#main-content" className="skip-link visually-hidden">
        Skip to downloads
      </a>

      <header className="border-b border-[var(--border-strong)] bg-[var(--surface-card)]">
        <div className="max-w-6xl mx-auto px-6 py-8 flex flex-col gap-6 md:flex-row md:items-center md:justify-between">
          <div className="flex flex-col gap-2 max-w-2xl">
            <div className="inline-flex items-center gap-2 text-xs font-mono uppercase tracking-wider text-[var(--text-muted)]">
              <ShieldCheck className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>Sanitized Workstation Archive</span>
            </div>
            <h1 className="text-3xl font-bold tracking-tight text-[var(--text-primary)]">
              Hola Workstation Downloads
            </h1>
            <p className="text-base text-[var(--text-muted)]">
              One-click downloads for Antigravity setup, GlazeWM &amp; Zebar, VS Code, Obelisk theme,
              PowerShell 7, and AutoHotkey binaries. All API secrets and tokens are stripped.
            </p>
          </div>

          <div className="flex flex-col gap-2 shrink-0">
            <a
              href={manifest.allBundle.href}
              download={manifest.allBundle.fileName}
              className="inline-flex items-center justify-center gap-2 min-h-[48px] px-6 py-3 rounded-lg font-semibold text-sm bg-[var(--accent)] text-[var(--accent-text)] no-underline transition-opacity hover:opacity-90 active:scale-[0.98]"
            >
              <Archive className="w-4 h-4 shrink-0" aria-hidden="true" />
              <span>Download All ({formatBytes(manifest.allBundle.sizeBytes)})</span>
            </a>
            <span className="text-xs font-mono text-[var(--text-muted)] text-center">
              SHA-256: {manifest.allBundle.sha256.slice(0, 16)}...
            </span>
          </div>
        </div>
      </header>

      <main id="main-content" tabIndex={-1} className="max-w-6xl mx-auto px-6 py-10 flex flex-col gap-12">
        <section aria-labelledby="direct-files-heading" className="flex flex-col gap-4">
          <h2 id="direct-files-heading" className="text-lg font-semibold tracking-tight text-[var(--text-primary)]">
            Direct AutoHotkey Downloads
          </h2>
          <div className="flex flex-wrap gap-3">
            {manifest.directFiles.map((file) => (
              <a
                key={file.fileName}
                href={file.href}
                download={file.fileName}
                className="inline-flex items-center gap-2 min-h-[44px] px-4 py-2 rounded-lg text-sm font-mono bg-[var(--surface-card)] border border-[var(--border-strong)] text-[var(--text-primary)] no-underline transition-opacity hover:opacity-85 active:scale-[0.98]"
              >
                <FileCode2 className="w-4 h-4 shrink-0" aria-hidden="true" />
                <span>{file.fileName}</span>
                <span className="text-xs text-[var(--text-muted)]">({formatBytes(file.sizeBytes)})</span>
                <Download className="w-4 h-4 shrink-0" aria-hidden="true" />
              </a>
            ))}
          </div>
        </section>

        <section aria-labelledby="bundles-heading" className="flex flex-col gap-6">
          <h2 id="bundles-heading" className="text-lg font-semibold tracking-tight text-[var(--text-primary)]">
            Component Bundles
          </h2>
          <div className="bundle-grid">
            {manifest.bundles.map((bundle) => (
              <BundleCard
                key={bundle.id}
                bundle={bundle}
                isCopied={copiedId === bundle.id}
                onCopyHash={handleCopyHash}
              />
            ))}
          </div>
        </section>
      </main>

      <footer className="border-t border-[var(--border-strong)] mt-8">
        <div className="max-w-6xl mx-auto px-6 py-6 flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between text-xs font-mono text-[var(--text-muted)]">
          <span>Source: belal-waheed/system-config &amp; obelisk</span>
          <span>Bundle build: {manifest.generatedAt.slice(0, 10)}</span>
        </div>
      </footer>

      <div className="visually-hidden" aria-live="polite" aria-atomic="true">
        {announcement}
      </div>
    </>
  );
}
