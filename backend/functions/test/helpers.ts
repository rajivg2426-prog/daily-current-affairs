import { readFileSync } from 'node:fs';
import { join } from 'node:path';
import { getSource } from '../src/config/sources';
import { parseFeed } from '../src/adapters/rss';
import { parseGdelt } from '../src/adapters/gdelt';
import { parseListing } from '../src/adapters/htmlList';
import type { RawItem, SourceDef } from '../src/core/types';

export const fixture = (name: string) => readFileSync(join(__dirname, 'fixtures', name), 'utf8');

/** Maps each source id to a local sample file, so the pipeline runs offline. */
export const FIXTURE_FOR: Record<string, string> = {
  'pib-en': 'pib-en.xml',
  'rbi-press': 'rbi.xml',
  'np-thehindu': 'thehindu.xml',
  'gnews-in': 'gnews.xml',
  'gdelt-india': 'gdelt.json',
  'prs-mpr': 'prs-mpr.html',
};

export async function fixtureFetcher(s: SourceDef): Promise<RawItem[]> {
  const file = FIXTURE_FOR[s.id];
  if (!file) return [];
  const body = fixture(file);
  if (s.kind === 'gdelt') return parseGdelt(body, s);
  if (s.kind === 'html-list') return parseListing(body, s);
  return parseFeed(body, s);
}

export const fixtureSources = () => Object.keys(FIXTURE_FOR).map(getSource);
