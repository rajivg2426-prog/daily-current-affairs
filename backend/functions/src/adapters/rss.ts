import { XMLParser } from 'fast-xml-parser';
import type { RawItem, SourceDef } from '../core/types';

const parser = new XMLParser({
  ignoreAttributes: false,
  attributeNamePrefix: '@_',
  textNodeName: '#text',
  cdataPropName: '#cdata',
  trimValues: true,
  processEntities: true,
});

/** Parses RSS 2.0, RSS 1.0 (RDF) and Atom into RawItems. */
export function parseFeed(xml: string, source: SourceDef): RawItem[] {
  const doc = parser.parse(xml);
  const channelItems =
    doc?.rss?.channel?.item ??
    doc?.['rdf:RDF']?.item ??
    doc?.feed?.entry ??
    [];
  const list: any[] = Array.isArray(channelItems) ? channelItems : [channelItems];

  const out: RawItem[] = [];
  for (const it of list) {
    const title = text(it.title);
    const url = link(it);
    if (!title || !url) continue;
    const item: RawItem = {
      sourceId: source.id,
      title,
      url,
      publishedAt: text(it.pubDate) || text(it['dc:date']) || text(it.published) || text(it.updated) || undefined,
      lang: source.lang,
    };
    // Only keep text for sources we're allowed to summarise.
    if (source.use === 'content') {
      item.summary = text(it.description) || text(it.summary) || undefined;
      item.body = text(it['content:encoded']) || text(it.content) || undefined;
    } else {
      const outlet = text(it.source);
      if (outlet) item.extra = { outlet };
    }
    out.push(item);
  }
  return out;
}

function text(v: unknown): string {
  if (v == null) return '';
  if (typeof v === 'string' || typeof v === 'number') return String(v).trim();
  if (Array.isArray(v)) return text(v[0]);
  if (typeof v === 'object') {
    const o = v as Record<string, unknown>;
    return text(o['#cdata'] ?? o['#text'] ?? '');
  }
  return '';
}

function link(it: any): string {
  const l = it.link;
  if (typeof l === 'string') return l.trim();
  if (Array.isArray(l)) {
    const alt = l.find((x) => x?.['@_rel'] === 'alternate') ?? l[0];
    return (alt?.['@_href'] ?? text(alt)).trim();
  }
  if (l && typeof l === 'object') return (l['@_href'] ?? text(l)).trim();
  const guid = it.guid;
  const g = text(guid);
  return /^https?:\/\//.test(g) ? g : '';
}
