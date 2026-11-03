import type { SourceItem, StoryCluster } from './types';
import { sha1 } from './normalize';

/**
 * Groups items about the same story. Two items join when their title tokens
 * overlap enough (Jaccard similarity) and they were published within the
 * window. Greedy single pass, newest first: fast and good enough for a few
 * thousand items a day.
 */
export interface ClusterOptions {
  threshold?: number;     // 0..1 similarity needed to join
  windowHours?: number;   // items further apart in time never join
}

export function jaccard(a: string[], b: string[]): number {
  if (a.length === 0 || b.length === 0) return 0;
  const sa = new Set(a);
  let inter = 0;
  for (const t of new Set(b)) if (sa.has(t)) inter++;
  return inter / (sa.size + new Set(b).size - inter);
}

export function clusterItems(items: SourceItem[], opts: ClusterOptions = {}): StoryCluster[] {
  const threshold = opts.threshold ?? 0.34;
  const windowMs = (opts.windowHours ?? 36) * 3_600_000;
  const sorted = [...items].sort((x, y) => y.publishedAt.localeCompare(x.publishedAt));

  type Work = { items: SourceItem[]; tokens: Set<string> };
  const groups: Work[] = [];

  for (const item of sorted) {
    const t = Date.parse(item.publishedAt);
    let best: { g: Work; score: number } | null = null;
    for (const g of groups) {
      const newest = Date.parse(g.items[0].publishedAt);
      if (Math.abs(newest - t) > windowMs) continue;
      const score = jaccard([...g.tokens], item.titleTokens);
      if (score >= threshold && (!best || score > best.score)) best = { g, score };
    }
    if (best) {
      best.g.items.push(item);
      // Keep the token set focused: only add tokens from content items,
      // so one long newspaper headline can't drag unrelated stories in.
      if (item.use === 'content') item.titleTokens.forEach((tok) => best!.g.tokens.add(tok));
    } else {
      groups.push({ items: [item], tokens: new Set(item.titleTokens) });
    }
  }

  return groups.map(({ items: gi }) => toCluster(gi));
}

function toCluster(items: SourceItem[]): StoryCluster {
  const content = items.filter((i) => i.use === 'content');
  const discovery = items.filter((i) => i.use === 'discovery');
  const lead = content[0] ?? items[0];
  const outlets = [...new Set(items.map((i) => i.sourceName))];
  const discoveryOutlets = new Set(discovery.map((i) => i.sourceName === 'GDELT' ? `gdelt:${hostOf(i.url)}` : i.sourceName)).size;
  const times = items.map((i) => i.publishedAt).sort();
  const tagSet = new Set(items.flatMap((i) => i.examTags));
  return {
    id: sha1(items.map((i) => i.id).sort().join('|')).slice(0, 20),
    title: lead.title,
    itemIds: items.map((i) => i.id),
    contentItemIds: content.map((i) => i.id),
    outlets,
    discoveryOutlets,
    category: mode(items.map((i) => i.category)) ?? lead.category,
    examTags: [...tagSet],
    firstSeen: times[0],
    lastSeen: times[times.length - 1],
    trendingScore: 0,
    draftable: content.length > 0,
  };
}

function hostOf(url: string): string {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return url;
  }
}

function mode<T>(xs: T[]): T | undefined {
  const counts = new Map<T, number>();
  for (const x of xs) counts.set(x, (counts.get(x) ?? 0) + 1);
  let best: T | undefined;
  let n = 0;
  for (const [k, v] of counts) if (v > n) { best = k; n = v; }
  return best;
}
