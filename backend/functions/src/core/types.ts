/**
 * Shared types for the ingestion pipeline.
 *
 * Every source is either:
 *  - "content":   we may summarise and build exam material from its text
 *                 (government releases, CC-BY research). Text is stored.
 *  - "discovery": we only learn THAT a story exists (headline, link, outlet,
 *                 time). Text is never stored or shown; it only feeds the
 *                 trending score and the editor's radar.
 */

export type SourceUse = 'content' | 'discovery';

export type SourceKind = 'rss' | 'html-list' | 'gdelt' | 'manual-import';

export type Lang = 'en' | 'hi';

export type Category =
  | 'national'
  | 'international'
  | 'economy'
  | 'scitech'
  | 'environment'
  | 'awards'
  | 'sports'
  | 'schemes'
  | 'defence'
  | 'books'
  | 'days';

export type ExamTag = 'upsc' | 'ssc' | 'banking' | 'railway' | 'defence' | 'statepsc';

export interface SourceDef {
  id: string;                 // stable id, e.g. "pib-en"
  name: string;               // shown to users as the credit, e.g. "PIB"
  use: SourceUse;
  kind: SourceKind;
  url: string;                // feed / listing / API url
  lang: Lang;
  pollMinutes: number;        // how often to fetch
  licence: string;            // human-readable licence summary
  licenceUrl?: string;        // where the licence is published
  attribution: string;        // credit line to show in the app ("" = none required)
  categoryHint?: Category;    // default category when rules find nothing
  /** For html-list sources: CSS selectors to pull item links from the page. */
  selectors?: { item: string; title?: string; link?: string; date?: string };
  enabled: boolean;
  notes?: string;
}

/** One item as fetched from a source, before any processing. */
export interface RawItem {
  sourceId: string;
  title: string;
  url: string;
  publishedAt?: string;       // ISO string if the source gave one
  summary?: string;           // only kept for "content" sources
  body?: string;              // only kept for "content" sources
  lang: Lang;
  extra?: Record<string, unknown>;
}

/** A normalised item, ready to store. */
export interface SourceItem {
  id: string;                 // sha1 of canonical url
  sourceId: string;
  sourceName: string;
  use: SourceUse;
  title: string;
  url: string;
  canonicalUrl: string;
  publishedAt: string;        // ISO, falls back to fetch time
  fetchedAt: string;
  lang: Lang;
  text?: string;              // content sources only
  category: Category;
  examTags: ExamTag[];
  titleTokens: string[];      // for clustering
  attribution: string;
}

/** A group of items about the same story across sources. */
export interface StoryCluster {
  id: string;
  title: string;              // best title (content source preferred)
  itemIds: string[];
  contentItemIds: string[];   // items we are allowed to draft from
  outlets: string[];          // distinct source names
  discoveryOutlets: number;   // how many newspapers/GDELT outlets carry it
  category: Category;
  examTags: ExamTag[];
  firstSeen: string;
  lastSeen: string;
  trendingScore: number;
  draftable: boolean;         // true only if at least one content item exists
}
