import { logger } from 'firebase-functions';
import { SOURCES, dueSources, getSource } from './config/sources';
import { ingest, buildQueue, hydrateText } from './pipeline';
import { draftCluster, type LlmClient } from './ai/draft';
import { parsePbShabdUpload } from './adapters/pbShabdImport';
import { normalize } from './core/normalize';
import type { SourceItem } from './core/types';
import type { Store } from './store';

/** Fetch due sources, store new items, re-cluster the last 36 hours. */
export async function runIngest(store: Store, now = new Date(), force = false) {
  const last = await store.lastRuns();
  const sources = force ? SOURCES.filter((s) => s.enabled && s.kind !== 'manual-import') : dueSources(last, now);
  if (sources.length === 0) {
    logger.info('ingest: nothing due');
    return { sources: 0, created: 0, clusters: 0 };
  }
  const { items, runs } = await ingest(sources, undefined, now);
  const created = await store.saveItems(items);
  await store.recordRuns(runs, now);
  for (const r of runs.filter((x) => !x.ok)) logger.warn('ingest: source failed', r);

  const clusters = buildQueue(await store.recentItems(36), now).slice(0, 300);
  await store.saveClusters(clusters);
  logger.info('ingest: done', { sources: sources.length, fetched: items.length, created, clusters: clusters.length });
  return { sources: sources.length, created, clusters: clusters.length };
}

/** Draft the top stories that have official text behind them. Every draft waits for an editor. */
export async function runDrafts(store: Store, llm: LlmClient, limit = 8, minScore = 2.5) {
  const queue = await store.clustersToDraft(limit, minScore);
  let drafted = 0;
  for (const cluster of queue) {
    const items = await hydrateText(await store.itemsByIds(cluster.contentItemIds));
    try {
      const result = await draftCluster(llm, cluster, items);
      if (result.ok) {
        await store.saveDraft(cluster, result.draft, items.filter((i) => i.use === 'content'));
        drafted++;
      } else {
        await store.markDraftFailed(cluster.id, result.reason);
        logger.info('draft: skipped', { cluster: cluster.id, reason: result.reason });
      }
    } catch (err) {
      logger.error('draft: error', { cluster: cluster.id, err: String(err) });
    }
  }
  return { considered: queue.length, drafted };
}

/** Admin upload of PB-SHABD stories (JSON array). */
export async function importPbShabd(store: Store, payload: unknown, now = new Date()) {
  const source = getSource('pb-shabd');
  const raws = parsePbShabdUpload(payload, source);
  const items = raws.map((r) => normalize(r, source, now)).filter((x): x is SourceItem => x !== null);
  const created = await store.saveItems(items);
  return { received: raws.length, created };
}
