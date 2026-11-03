import type { SourceDef } from '../core/types';

/**
 * Source registry. Every free source the app uses lives here, with its
 * licence, so the rules travel with the code.
 *
 * Before launch: open each url once in a browser and confirm the feed still
 * answers, and re-read each licence page. Record the date you checked in
 * LICENCE_CHECK.md.
 */
export const SOURCES: SourceDef[] = [
  // ───────────── CONTENT SOURCES (we may summarise and build questions) ─────────────
  {
    id: 'pib-en',
    name: 'PIB',
    use: 'content',
    kind: 'rss',
    url: 'https://www.pib.gov.in/RssMain.aspx?ModId=6&Lang=1&Regid=3',
    lang: 'en',
    pollMinutes: 30,
    licence: 'Material may be reproduced free of charge, no prior approval needed.',
    licenceUrl: 'https://pib.gov.in/Content/102_2_Copyright-Policy.aspx',
    attribution: 'Source: Press Information Bureau (PIB)',
    categoryHint: 'national',
    enabled: true,
    notes: 'English releases, all ministries. Confirm Lang/Regid values in the browser.',
  },
  {
    id: 'pib-hi',
    name: 'PIB',
    use: 'content',
    kind: 'rss',
    url: 'https://www.pib.gov.in/RssMain.aspx?ModId=6&Lang=2&Regid=3',
    lang: 'hi',
    pollMinutes: 30,
    licence: 'Material may be reproduced free of charge, no prior approval needed.',
    licenceUrl: 'https://pib.gov.in/Content/102_2_Copyright-Policy.aspx',
    attribution: 'स्रोत: पत्र सूचना कार्यालय (PIB)',
    categoryHint: 'national',
    enabled: true,
    notes: 'Hindi releases. Used to check our Hindi translations against official terms.',
  },
  {
    id: 'rbi-press',
    name: 'RBI',
    use: 'content',
    kind: 'rss',
    url: 'https://rbi.org.in/pressreleases_rss.xml',
    lang: 'en',
    pollMinutes: 60,
    licence: 'Official public releases. Summarise in our own words and link back.',
    attribution: 'Source: Reserve Bank of India',
    categoryHint: 'economy',
    enabled: true,
  },
  {
    id: 'rbi-notifications',
    name: 'RBI',
    use: 'content',
    kind: 'rss',
    url: 'https://rbi.org.in/notifications_rss.xml',
    lang: 'en',
    pollMinutes: 120,
    licence: 'Official public notifications. Summarise in our own words and link back.',
    attribution: 'Source: Reserve Bank of India',
    categoryHint: 'economy',
    enabled: true,
  },
  {
    id: 'prs-mpr',
    name: 'PRS Legislative Research',
    use: 'content',
    kind: 'html-list',
    url: 'https://prsindia.org/policy/monthly-policy-review',
    lang: 'en',
    pollMinutes: 720,
    licence: 'Creative Commons Attribution 4.0 (CC BY 4.0). Credit PRS.',
    licenceUrl: 'https://prsindia.org/aboutus/disclaimer',
    attribution: 'Source: PRS Legislative Research (CC BY 4.0)',
    categoryHint: 'national',
    selectors: { item: 'a[href*="/policy/monthly-policy-review/"]' },
    enabled: true,
    notes: 'No RSS. Reads the listing page twice a day. Check the selector if PRS redesigns.',
  },
  {
    id: 'prs-bills',
    name: 'PRS Legislative Research',
    use: 'content',
    kind: 'html-list',
    url: 'https://prsindia.org/billtrack',
    lang: 'en',
    pollMinutes: 360,
    licence: 'Creative Commons Attribution 4.0 (CC BY 4.0). Credit PRS.',
    licenceUrl: 'https://prsindia.org/aboutus/disclaimer',
    attribution: 'Source: PRS Legislative Research (CC BY 4.0)',
    categoryHint: 'national',
    selectors: { item: 'a[href*="/billtrack/"]' },
    enabled: true,
    notes: 'Bill tracker. Check the url and selector in a browser before launch.',
  },
  {
    id: 'pb-shabd',
    name: 'Prasar Bharati (PB-SHABD)',
    use: 'content',
    kind: 'manual-import',
    url: 'https://shabd.prasarbharati.org',
    lang: 'en',
    pollMinutes: 0,
    licence: 'Free for registered media organisations; logo-free, no credit required.',
    licenceUrl: 'https://shabd.prasarbharati.org/faqs',
    attribution: '',
    categoryHint: 'national',
    enabled: false,
    notes:
      'Needs registration as a media organisation (papers within 10 days). No public API: ' +
      'editors download stories from the portal and upload them through the admin import. ' +
      'Turn on once registration is approved.',
  },

  // ───────────── DISCOVERY SOURCES (headline + link only, never stored text) ─────────────
  {
    id: 'gdelt-india',
    name: 'GDELT',
    use: 'discovery',
    kind: 'gdelt',
    url: 'https://api.gdeltproject.org/api/v2/doc/doc',
    lang: 'en',
    pollMinutes: 30,
    licence: 'Free open data. We store headline, link, outlet and time only.',
    attribution: '',
    enabled: true,
  },
  {
    id: 'gnews-in',
    name: 'Google News',
    use: 'discovery',
    kind: 'rss',
    url: 'https://news.google.com/rss?hl=en-IN&gl=IN&ceid=IN:en',
    lang: 'en',
    pollMinutes: 30,
    licence: 'Headlines and links only, used internally for trending.',
    attribution: '',
    enabled: true,
  },
  ...newspaper('thehindu', 'The Hindu', 'https://www.thehindu.com/news/national/feeder/default.rss'),
  ...newspaper('indianexpress', 'The Indian Express', 'https://indianexpress.com/section/india/feed/'),
  ...newspaper('hindustantimes', 'Hindustan Times', 'https://www.hindustantimes.com/feeds/rss/india-news/rssfeed.xml'),
  ...newspaper('toi', 'The Times of India', 'https://timesofindia.indiatimes.com/rssfeedstopstories.cms'),
  ...newspaper('livemint', 'Mint', 'https://www.livemint.com/rss/news'),
  ...newspaper('newsonair', 'News On AIR', 'https://www.newsonair.gov.in/feed/'),
];

function newspaper(id: string, name: string, url: string): SourceDef[] {
  return [
    {
      id: `np-${id}`,
      name,
      use: 'discovery',
      kind: 'rss',
      url,
      lang: 'en',
      pollMinutes: 30,
      licence: 'Newspaper RSS: personal/non-commercial use. Headline + link only, never shown as our content.',
      attribution: '',
      enabled: true,
      notes: 'Feed url from the publisher; confirm it still answers before launch.',
    },
  ];
}

export function getSource(id: string): SourceDef {
  const s = SOURCES.find((x) => x.id === id);
  if (!s) throw new Error(`Unknown source: ${id}`);
  return s;
}

/** Sources whose poll interval has elapsed since their last run. */
export function dueSources(lastRun: Record<string, string | undefined>, now = new Date()): SourceDef[] {
  return SOURCES.filter((s) => {
    if (!s.enabled || s.kind === 'manual-import' || s.pollMinutes <= 0) return false;
    const last = lastRun[s.id];
    if (!last) return true;
    return now.getTime() - new Date(last).getTime() >= s.pollMinutes * 60_000 - 60_000;
  });
}
