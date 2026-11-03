import type { RawItem, SourceDef } from '../core/types';
import { fetchText } from '../core/http';
import { parseFeed } from './rss';
import { parseListing } from './htmlList';
import { gdeltUrl, parseGdelt } from './gdelt';

/** Fetches and parses one source. Manual-import sources are skipped here. */
export async function fetchSource(source: SourceDef): Promise<RawItem[]> {
  switch (source.kind) {
    case 'rss':
      return parseFeed(await fetchText(source.url, { accept: 'application/rss+xml, application/xml, text/xml' }), source);
    case 'html-list':
      return parseListing(await fetchText(source.url, { accept: 'text/html' }), source);
    case 'gdelt':
      return parseGdelt(await fetchText(gdeltUrl(source), { accept: 'application/json' }), source);
    case 'manual-import':
      return [];
  }
}
