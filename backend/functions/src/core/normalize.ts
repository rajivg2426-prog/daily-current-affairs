import { createHash } from 'node:crypto';
import type { RawItem, SourceDef, SourceItem } from './types';
import { categorize, examTagsFor } from './categorize';

const TRACKING_PARAMS = /^(utm_|fbclid|gclid|ref$|ref_|cmp$|ns_|s_cid)/i;

/** Canonical URL: https, no fragment, no tracking params, no trailing slash. */
export function canonicalUrl(raw: string): string {
  try {
    const u = new URL(raw.trim());
    u.hash = '';
    u.protocol = 'https:';
    u.hostname = u.hostname.replace(/^www\./, '');
    for (const key of [...u.searchParams.keys()]) {
      if (TRACKING_PARAMS.test(key)) u.searchParams.delete(key);
    }
    if (u.pathname.length > 1 && u.pathname.endsWith('/')) u.pathname = u.pathname.replace(/\/+$/, '');
    return u.toString();
  } catch {
    return raw.trim();
  }
}

export function sha1(s: string): string {
  return createHash('sha1').update(s).digest('hex');
}

/** Strip tags and entities, collapse whitespace. */
export function cleanText(html: string | undefined): string {
  if (!html) return '';
  return html
    .replace(/<script[\s\S]*?<\/script>/gi, ' ')
    .replace(/<style[\s\S]*?<\/style>/gi, ' ')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<\/p>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .replace(/&nbsp;/g, ' ')
    .replace(/&amp;/g, '&')
    .replace(/&quot;/g, '"')
    .replace(/&#39;|&apos;/g, "'")
    .replace(/&lt;/g, '<')
    .replace(/&gt;/g, '>')
    .replace(/&#(\d+);/g, (_, n) => String.fromCharCode(Number(n)))
    .replace(/[ \t]+/g, ' ')
    .replace(/\s*\n\s*/g, '\n')
    .trim();
}

/** Google News titles end with " - Outlet"; drop it. */
export function cleanTitle(title: string): string {
  return cleanText(title).replace(/\s+[-–|]\s+[^-–|]{2,40}$/, '').trim();
}

const STOP = new Set(
  ('a an the of to in on for and or by with at from as is are was were be been its it this that ' +
    'says said new over after amid into up out about will may can has have had not more than ' +
    'india indian govt government minister ministry')
    .split(' '),
);

/** Lower-cased content words used to match the same story across outlets. */
export function titleTokens(title: string): string[] {
  const words = title
    .toLowerCase()
    .replace(/[^\p{L}\p{N}\s-]/gu, ' ')
    .split(/[\s-]+/)
    .filter((w) => w.length > 2 && !STOP.has(w));
  return [...new Set(words)];
}

/** Parse common feed date formats into ISO; undefined if unparseable. */
export function toIso(date: string | undefined): string | undefined {
  if (!date) return undefined;
  const gdelt = /^(\d{4})(\d{2})(\d{2})T?(\d{2})(\d{2})(\d{2})Z?$/.exec(date.trim());
  if (gdelt) {
    const [, y, mo, d, h, mi, s] = gdelt;
    return new Date(Date.UTC(+y, +mo - 1, +d, +h, +mi, +s)).toISOString();
  }
  const t = Date.parse(date);
  return Number.isNaN(t) ? undefined : new Date(t).toISOString();
}

export function normalize(raw: RawItem, source: SourceDef, now = new Date()): SourceItem | null {
  const title = source.use === 'discovery' ? cleanTitle(raw.title) : cleanText(raw.title);
  if (!title || !raw.url) return null;
  const canon = canonicalUrl(raw.url);
  const text = source.use === 'content' ? cleanText([raw.summary, raw.body].filter(Boolean).join('\n\n')) : undefined;
  const category = categorize(`${title}\n${text ?? ''}`, source.categoryHint);
  return {
    id: sha1(canon),
    sourceId: source.id,
    sourceName: source.name,
    use: source.use,
    title,
    url: raw.url.trim(),
    canonicalUrl: canon,
    publishedAt: toIso(raw.publishedAt) ?? now.toISOString(),
    fetchedAt: now.toISOString(),
    lang: raw.lang,
    ...(text ? { text: text.slice(0, 20_000) } : {}),
    category,
    examTags: examTagsFor(category, `${title}\n${text ?? ''}`),
    titleTokens: titleTokens(title),
    attribution: source.attribution,
  };
}
