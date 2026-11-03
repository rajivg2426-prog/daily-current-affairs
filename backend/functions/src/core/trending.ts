import type { StoryCluster } from './types';

/**
 * Trending score for the editor queue and the Daily Brief.
 *
 *   score = outlets carrying it (log-scaled)
 *         + boost for an official content source (PIB/RBI/PRS)
 *         + exam-weight of the category
 *         x freshness decay (half-life 12 h)
 *
 * Scores are relative; only the order matters.
 */
const EXAM_WEIGHT: Record<StoryCluster['category'], number> = {
  schemes: 1.0,
  economy: 1.0,
  national: 0.9,
  international: 0.9,
  environment: 0.85,
  scitech: 0.85,
  defence: 0.8,
  awards: 0.75,
  days: 0.7,
  sports: 0.6,
  books: 0.6,
};

export function trendingScore(c: StoryCluster, now = new Date()): number {
  const coverage = Math.log2(1 + c.discoveryOutlets) * 2;          // 0, 2, 3.2, 4, ...
  const official = c.contentItemIds.length > 0 ? 2 : 0;
  const weight = EXAM_WEIGHT[c.category] ?? 0.7;
  const ageHours = Math.max(0, (now.getTime() - Date.parse(c.lastSeen)) / 3_600_000);
  const decay = Math.pow(0.5, ageHours / 12);
  return Math.round((coverage + official + 3 * weight) * decay * 100) / 100;
}

export function rankClusters(clusters: StoryCluster[], now = new Date()): StoryCluster[] {
  return clusters
    .map((c) => ({ ...c, trendingScore: trendingScore(c, now) }))
    .sort((a, b) => b.trendingScore - a.trendingScore);
}
