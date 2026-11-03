import * as cheerio from 'cheerio';
import type { RawItem, SourceDef } from '../core/types';

/**
 * Reads a listing page (for sites with no RSS, like PRS) and returns one
 * RawItem per linked report. Only titles and links are taken here; the
 * report text is fetched later, one page at a time, when a draft is made.
 */
export function parseListing(html: string, source: SourceDef): RawItem[] {
  if (!source.selectors) throw new Error(`Source ${source.id} has no selectors`);
  const $ = cheerio.load(html);
  const base = new URL(source.url);
  const seen = new Set<string>();
  const out: RawItem[] = [];

  $(source.selectors.item).each((_, el) => {
    const node = $(el);
    const anchor = source.selectors!.link ? node.find(source.selectors!.link).first() : node.is('a') ? node : node.find('a').first();
    const href = anchor.attr('href');
    if (!href) return;
    const url = new URL(href, base).toString();
    if (seen.has(url) || url === source.url) return;
    const title = (source.selectors!.title ? node.find(source.selectors!.title).first().text() : anchor.text()).replace(/\s+/g, ' ').trim();
    if (!title || /^(read more|download|more)$/i.test(title)) return;
    seen.add(url);
    const dateText = source.selectors!.date ? node.find(source.selectors!.date).first().text().trim() : undefined;
    out.push({ sourceId: source.id, title, url, publishedAt: dateText || undefined, lang: source.lang });
  });
  return out;
}

/** Pulls the readable text of a single report page (used at draft time). */
export function extractArticleText(html: string): string {
  const $ = cheerio.load(html);
  $('script, style, nav, header, footer, form, noscript, aside').remove();
  const main = $('article').first().length ? $('article').first() : $('main').first().length ? $('main').first() : $('body');
  return main
    .find('h1, h2, h3, p, li')
    .map((_, el) => $(el).text().replace(/\s+/g, ' ').trim())
    .get()
    .filter((t) => t.length > 0)
    .join('\n');
}
