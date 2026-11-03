/**
 * Runs the pipeline without Firebase and prints the story queue.
 *
 *   npm run ingest:fixtures            sample feeds in test/fixtures (works offline)
 *   npm run ingest:live                fetches every enabled source for real
 *   npm run ingest:live -- --draft     also drafts the top story (needs ANTHROPIC_API_KEY)
 */
import { SOURCES } from '../src/config/sources';
import { ingest, buildQueue, hydrateText } from '../src/pipeline';
import { draftCluster, anthropicClient } from '../src/ai/draft';
import { fixtureFetcher, fixtureSources } from '../test/helpers';

async function main() {
  const live = process.argv.includes('--live');
  const wantDraft = process.argv.includes('--draft');
  const sources = live ? SOURCES.filter((s) => s.enabled && s.kind !== 'manual-import') : fixtureSources();

  console.log(`\nFetching ${sources.length} sources (${live ? 'LIVE' : 'sample fixtures'})...\n`);
  const { items, runs } = await ingest(sources, live ? undefined : fixtureFetcher);

  console.log('Source'.padEnd(22), 'Use'.padEnd(10), 'Status'.padEnd(8), 'Items');
  for (const r of runs) {
    const s = sources.find((x) => x.id === r.sourceId)!;
    console.log(r.sourceId.padEnd(22), s.use.padEnd(10), (r.ok ? 'ok' : 'FAILED').padEnd(8), r.ok ? r.kept : r.error);
  }

  const queue = buildQueue(items);
  console.log(`\nTop stories (${queue.length} clusters from ${items.length} items):\n`);
  for (const c of queue.slice(0, 15)) {
    const flag = c.draftable ? 'DRAFTABLE' : 'radar    ';
    console.log(`${c.trendingScore.toFixed(2).padStart(6)}  ${flag}  [${c.category}] ${c.title}`);
    console.log(`        outlets: ${c.outlets.join(', ')}`);
  }

  if (wantDraft) {
    const key = process.env.ANTHROPIC_API_KEY;
    if (!key) throw new Error('Set ANTHROPIC_API_KEY to try drafting');
    const top = queue.find((c) => c.draftable);
    if (!top) return console.log('\nNo draftable story.');
    const hydrated = await hydrateText(items.filter((i) => top.contentItemIds.includes(i.id)));
    const result = await draftCluster(anthropicClient(key), top, hydrated);
    console.log('\nDraft for:', top.title, '\n', JSON.stringify(result, null, 2));
  }
}

main().catch((err) => {
  console.error(err);
  process.exit(1);
});
