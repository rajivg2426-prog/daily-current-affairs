import type { RawItem, SourceDef, SourceItem, StoryCluster } from './core/types';
import { normalize } from './core/normalize';
import { clusterItems } from './core/cluster';
import { rankClusters } from './core/trending';
import { fetchSource } from './adapters';
import { fetchText } from './core/http';
import { extractArticleText } from './adapters/htmlList';

export interface SourceRun {
  sourceId: string;
  ok: boolean;
  fetched: number;
  kept: number;
  error?: string;
}

export type Fetcher = (s: SourceDef) => Promise<RawItem[]>;

/** Fetch every given source in parallel; one failing source never stops the rest. */
export async function ingest(
  sources: SourceDef[],
  fetcher: Fetcher = fetchSource,
  now = new Date(),
): Promise<{ items: SourceItem[]; runs: SourceRun[] }> {
  const results = await Promise.allSettled(sources.map((s) => fetcher(s)));
  const items: SourceItem[] = [];
  const runs: SourceRun[] = [];
  results.forEach((r, i) => {
    const source = sources[i];
    if (r.status === 'rejected') {
      runs.push({ sourceId: source.id, ok: false, fetched: 0, kept: 0, error: String(r.reason?.message ?? r.reason) });
      return;
    }
    const normalised = r.value.map((raw) => normalize(raw, source, now)).filter((x): x is SourceItem => x !== null);
    items.push(...normalised);
    runs.push({ sourceId: source.id, ok: true, fetched: r.value.length, kept: normalised.length });
  });
  return { items: dedupeById(items), runs };
}

export function dedupeById(items: SourceItem[]): SourceItem[] {
  const map = new Map<string, SourceItem>();
  for (const it of items) if (!map.has(it.id)) map.set(it.id, it);
  return [...map.values()];
}

/** Cluster recent items and rank them for the editor queue. */
export function buildQueue(recent: SourceItem[], now = new Date()): StoryCluster[] {
  return rankClusters(clusterItems(recent), now);
}

/**
 * Content items from listing pages (PRS) arrive with a title and link only.
 * Before drafting, fetch the page and pull its readable text.
 */
export async function hydrateText(items: SourceItem[], fetch = fetchText): Promise<SourceItem[]> {
  return Promise.all(
    items.map(async (it) => {
      if (it.use !== 'content' || (it.text && it.text.length > 200)) return it;
      try {
        const html = await fetch(it.url, { accept: 'text/html' });
        const text = extractArticleText(html).slice(0, 20_000);
        return text ? { ...it, text } : it;
      } catch {
        return it;
      }
    }),
  );
}
