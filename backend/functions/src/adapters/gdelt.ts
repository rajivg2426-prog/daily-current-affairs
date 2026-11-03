import type { RawItem, SourceDef } from '../core/types';

/**
 * GDELT DOC 2.0 API, article-list mode. Free and keyless.
 * We keep only headline, link, outlet domain and time (discovery use).
 */
export const GDELT_QUERY =
  '(government OR ministry OR minister OR scheme OR "supreme court" OR rbi OR isro OR army OR navy OR parliament) ' +
  'sourcecountry:IN sourcelang:english';

export function gdeltUrl(source: SourceDef, timespan = '1h', max = 250): string {
  const u = new URL(source.url);
  u.searchParams.set('query', GDELT_QUERY);
  u.searchParams.set('mode', 'artlist');
  u.searchParams.set('format', 'json');
  u.searchParams.set('maxrecords', String(max));
  u.searchParams.set('timespan', timespan);
  u.searchParams.set('sort', 'datedesc');
  return u.toString();
}

interface GdeltArticle {
  url: string;
  title: string;
  seendate?: string;
  domain?: string;
  language?: string;
  sourcecountry?: string;
}

export function parseGdelt(json: string, source: SourceDef): RawItem[] {
  let data: { articles?: GdeltArticle[] };
  try {
    data = JSON.parse(json);
  } catch {
    // GDELT answers rate-limit and query errors as plain text.
    throw new Error(`GDELT returned non-JSON: ${json.slice(0, 120)}`);
  }
  return (data.articles ?? [])
    .filter((a) => a.url && a.title)
    .map((a) => ({
      sourceId: source.id,
      title: a.title,
      url: a.url,
      publishedAt: a.seendate,
      lang: source.lang,
      extra: { outlet: a.domain },
    }));
}
