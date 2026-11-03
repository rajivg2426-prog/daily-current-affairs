import { describe, expect, it } from 'vitest';
import { canonicalUrl, cleanTitle, toIso, titleTokens, normalize } from '../src/core/normalize';
import { categorize } from '../src/core/categorize';
import { jaccard } from '../src/core/cluster';
import { dueSources, getSource, SOURCES } from '../src/config/sources';
import { ingest, buildQueue } from '../src/pipeline';
import { fixtureFetcher, fixtureSources } from './helpers';

const NOW = new Date('2026-11-03T07:00:00Z');

describe('normalise', () => {
  it('canonicalises urls', () => {
    expect(canonicalUrl('http://www.thehindu.com/a/b/?utm_source=rss&id=2#top')).toBe('https://thehindu.com/a/b?id=2');
  });
  it('strips the outlet suffix from Google News titles', () => {
    expect(cleanTitle('Big story here - The Indian Express')).toBe('Big story here');
  });
  it('parses GDELT and RFC-822 dates', () => {
    expect(toIso('20261103T061500Z')).toBe('2026-11-03T06:15:00.000Z');
    expect(toIso('Tue, 03 Nov 2026 10:30:00 +0530')).toBe('2026-11-03T05:00:00.000Z');
    expect(toIso('not a date')).toBeUndefined();
  });
  it('tokenises titles without stopwords', () => {
    expect(titleTokens('Cabinet approves the National Mission on Critical Minerals')).toEqual(['cabinet', 'approves', 'national', 'mission', 'critical', 'minerals']);
  });
  it('never stores text from discovery sources', () => {
    const item = normalize({ sourceId: 'np-thehindu', title: 'T', url: 'https://x.in/a', summary: 'secret', lang: 'en' }, getSource('np-thehindu'), NOW);
    expect(item?.text).toBeUndefined();
  });
});

describe('categorise', () => {
  it.each([
    ['RBI keeps repo rate unchanged; inflation outlook revised', 'economy'],
    ['Indian Navy commissions new stealth frigate', 'defence'],
    ['ISRO launches earth observation satellite', 'scitech'],
    ['Ramsar tag for two new wetlands', 'environment'],
    ['PM launches new housing yojana for rural families', 'schemes'],
    ['World Wildlife Day observed', 'days'],
    ['Neeraj wins gold at athletics championship', 'sports'],
    ['India clinch T20 series against Australia', 'sports'],
    ['Monsoon session of Parliament to begin next week', 'national'],
  ])('%s -> %s', (title, cat) => {
    expect(categorize(title)).toBe(cat);
  });
  it('falls back to the source hint', () => {
    expect(categorize('Something unclassifiable', 'economy')).toBe('economy');
  });
});

describe('sources', () => {
  it('every source has a licence note', () => {
    for (const s of SOURCES) expect(s.licence.length).toBeGreaterThan(10);
  });
  it('only government/CC sources are marked content', () => {
    const content = SOURCES.filter((s) => s.use === 'content').map((s) => s.name);
    expect(new Set(content)).toEqual(new Set(['PIB', 'RBI', 'PRS Legislative Research', 'Prasar Bharati (PB-SHABD)']));
  });
  it('schedules by poll interval and skips manual imports', () => {
    const due = dueSources({ 'pib-en': new Date(NOW.getTime() - 10 * 60_000).toISOString() }, NOW);
    expect(due.find((s) => s.id === 'pib-en')).toBeUndefined();
    expect(due.find((s) => s.id === 'rbi-press')).toBeDefined();
    expect(due.find((s) => s.id === 'pb-shabd')).toBeUndefined();
  });
});

describe('pipeline on sample feeds', () => {
  it('ingests, clusters and ranks across sources', async () => {
    const { items, runs } = await ingest(fixtureSources(), fixtureFetcher, NOW);
    expect(runs.every((r) => r.ok)).toBe(true);
    expect(items.length).toBeGreaterThan(10);

    const queue = buildQueue(items, NOW);
    const minerals = queue.find((c) => /critical minerals/i.test(c.title))!;
    expect(minerals).toBeDefined();
    expect(minerals.draftable).toBe(true);
    expect(minerals.outlets).toContain('PIB');
    expect(minerals.discoveryOutlets).toBeGreaterThanOrEqual(3);   // The Hindu, Google News, 2 GDELT outlets
    expect(queue[0].id).toBe(minerals.id);                          // most covered + official = top

    const cricket = queue.find((c) => /T20/.test(c.title))!;
    expect(cricket.draftable).toBe(false);                          // no official source: never drafted
  });

  it('keeps going when one source fails', async () => {
    const failing = async (s: any) => {
      if (s.id === 'gdelt-india') throw new Error('timeout');
      return fixtureFetcher(s);
    };
    const { runs } = await ingest(fixtureSources(), failing, NOW);
    expect(runs.find((r) => r.sourceId === 'gdelt-india')?.ok).toBe(false);
    expect(runs.filter((r) => r.ok).length).toBe(fixtureSources().length - 1);
  });

  it('similarity is symmetric and bounded', () => {
    expect(jaccard(['a', 'b'], ['b', 'a'])).toBe(1);
    expect(jaccard(['a'], ['b'])).toBe(0);
  });
});
