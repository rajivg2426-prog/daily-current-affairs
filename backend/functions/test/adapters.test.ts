import { describe, expect, it } from 'vitest';
import { getSource } from '../src/config/sources';
import { parseFeed } from '../src/adapters/rss';
import { parseGdelt, gdeltUrl } from '../src/adapters/gdelt';
import { parseListing, extractArticleText } from '../src/adapters/htmlList';
import { parsePbShabdUpload } from '../src/adapters/pbShabdImport';
import { fixture } from './helpers';

describe('RSS adapter', () => {
  it('keeps text for content sources', () => {
    const items = parseFeed(fixture('pib-en.xml'), getSource('pib-en'));
    expect(items).toHaveLength(3);
    expect(items[0].title).toMatch(/Critical Minerals/);
    expect(items[0].summary).toContain('Ministry of Mines');
    expect(items[0].url).toContain('PRID=1000001');
  });

  it('drops text for discovery sources (newspapers)', () => {
    const items = parseFeed(fixture('thehindu.xml'), getSource('np-thehindu'));
    expect(items).toHaveLength(2);
    for (const it of items) {
      expect(it.summary).toBeUndefined();
      expect(it.body).toBeUndefined();
    }
  });

  it('reads the outlet from Google News <source>', () => {
    const items = parseFeed(fixture('gnews.xml'), getSource('gnews-in'));
    expect(items[0].extra?.outlet).toBe('The Indian Express');
  });

  it('parses Atom feeds', () => {
    const items = parseFeed(fixture('atom.xml'), getSource('pib-en'));
    expect(items).toHaveLength(1);
    expect(items[0].url).toBe('https://example.org/isro-launch');
    expect(items[0].publishedAt).toBe('2026-11-03T04:00:00Z');
  });
});

describe('GDELT adapter', () => {
  it('builds a keyless India query', () => {
    const url = new URL(gdeltUrl(getSource('gdelt-india')));
    expect(url.searchParams.get('mode')).toBe('artlist');
    expect(url.searchParams.get('format')).toBe('json');
    expect(url.searchParams.get('query')).toContain('sourcecountry:IN');
  });

  it('parses articles and keeps the outlet domain', () => {
    const items = parseGdelt(fixture('gdelt.json'), getSource('gdelt-india'));
    expect(items).toHaveLength(3);
    expect(items[0].extra?.outlet).toBe('business-standard.com');
  });

  it('reports a clear error for non-JSON replies', () => {
    expect(() => parseGdelt('Please limit requests', getSource('gdelt-india'))).toThrow(/non-JSON/);
  });
});

describe('PRS listing adapter', () => {
  it('extracts report links, skips nav and "Read More" duplicates', () => {
    const items = parseListing(fixture('prs-mpr.html'), getSource('prs-mpr'));
    expect(items.map((i) => i.title)).toEqual([
      'Monthly Policy Review October 2026',
      'Monthly Policy Review September 2026',
    ]);
    expect(items[0].url).toBe('https://prsindia.org/policy/monthly-policy-review/monthly-policy-review-october-2026');
  });

  it('extracts readable text from a report page', () => {
    const text = extractArticleText('<html><body><nav>menu</nav><article><h1>Title</h1><p>First   para.</p><script>x</script></article></body></html>');
    expect(text).toBe('Title\nFirst para.');
  });
});

describe('PB-SHABD import', () => {
  it('accepts a valid upload', () => {
    const items = parsePbShabdUpload(
      [{ headline: 'Sample headline for import', body: 'B'.repeat(60), storyId: 'S1', language: 'hi' }],
      getSource('pb-shabd'),
    );
    expect(items[0].lang).toBe('hi');
    expect(items[0].url).toContain('S1');
  });

  it('rejects an upload with missing body', () => {
    expect(() => parsePbShabdUpload([{ headline: 'Sample headline' }], getSource('pb-shabd'))).toThrow();
  });
});
