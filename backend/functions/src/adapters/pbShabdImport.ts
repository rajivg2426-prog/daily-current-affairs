import { z } from 'zod';
import type { RawItem, SourceDef } from '../core/types';

/**
 * PB-SHABD has no public API. After registration, editors download stories
 * from shabd.prasarbharati.org and upload them through the admin panel as a
 * JSON array (or CSV converted to JSON by the admin UI). This validates the
 * upload and turns it into RawItems. We never log in or scrape the portal.
 */
export const PbShabdStory = z.object({
  headline: z.string().min(5),
  body: z.string().min(40),
  url: z.string().url().optional(),
  storyId: z.string().optional(),
  date: z.string().optional(),
  language: z.enum(['en', 'hi']).default('en'),
  category: z.string().optional(),
});

export const PbShabdUpload = z.array(PbShabdStory).min(1).max(500);

export function parsePbShabdUpload(payload: unknown, source: SourceDef): RawItem[] {
  const stories = PbShabdUpload.parse(payload);
  return stories.map((s) => ({
    sourceId: source.id,
    title: s.headline,
    // No public story URL exists, so we mint a stable internal one.
    url: s.url ?? `https://shabd.prasarbharati.org/story/${encodeURIComponent(s.storyId ?? s.headline.slice(0, 80))}`,
    publishedAt: s.date,
    body: s.body,
    lang: s.language,
    extra: { category: s.category },
  }));
}
