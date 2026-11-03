import type { Category, ExamTag } from './types';

/**
 * Rule-based first pass. The AI draft step refines category and tags later;
 * this pass only needs to be good enough for clustering and the editor queue.
 * Order matters for ties: earlier categories win.
 */
const RULES: [Category, RegExp][] = [
  ['days', /\b(world|international|national)\s+[\w\s]{0,30}\bday\b|\bdiwas\b|दिवस|\bobserved (on|every)\b|\bjayanti\b/i],
  ['awards', /\bawards?\b|\bprize\b|\bpadma\b|\bbharat ratna\b|\bconferred\b|\bhonou?red with\b|\bpuraskar\b|पुरस्कार|सम्मान/i],
  ['books', /\b(book|autobiography|memoir|novel)\b.*\b(released|launched|authored|written)\b|\bauthor(ed)?\b.*\bbook\b|\bliterary\b/i],
  ['sports', /\b(cricket|t20|odi|ipl|test series|hockey|football|olympic|paralympic|asian games|commonwealth games|chess|badminton|tennis|wrestling|athletics|medal|tournament|championship|world cup|khelo india)\b|खेल/i],
  ['defence', /\b(army|navy|air force|iaf|drdo|missile|exercise|defence|defense|warship|submarine|brahmos|agni|tejas|coast guard|military|chief of defence staff|indian navy)\b|रक्षा|सेना/i],
  ['economy', /\b(rbi|repo|inflation|gdp|fiscal|monetary|budget|tax|gst|sebi|bank(s|ing)?|rupee|forex|export|import|trade deficit|ipo|stock|fdi|nabard|msme|credit|loan|economic|economy)\b|अर्थव्यवस्था|बैंक/i],
  ['scitech', /\b(isro|satellite|launch vehicle|space|ai|artificial intelligence|semiconductor|quantum|research|scientists?|vaccine|technology|digital|5g|6g|gaganyaan|chandrayaan|aditya)\b|विज्ञान|अंतरिक्ष/i],
  ['environment', /\b(climate|cop\d*|ramsar|wetland|tiger|wildlife|forest|biodiversity|pollution|emission|renewable|solar|wind energy|net zero|heatwave|cyclone|monsoon|national park|sanctuary)\b|पर्यावरण/i],
  ['schemes', /\b(scheme|yojana|mission|abhiyan|programme|program|pm-[a-z]+|pradhan mantri)\b|योजना|मिशन|अभियान/i],
  ['international', /\b(bilateral|summit|united nations|\bun\b|g20|brics|sco|quad|asean|imf|world bank|wto|treaty|mou with|foreign minister|embassy|visit to|external affairs)\b|विदेश/i],
];

/** Phrases that would otherwise be mis-filed (e.g. "Monsoon session" is Parliament, not weather). */
const NATIONAL_OVERRIDES = /\b(monsoon|winter|budget|special) session\b|\blok sabha\b|\brajya sabha\b|\bparliament\b|\bsupreme court\b|\belection commission\b/i;

export function categorize(text: string, hint?: Category): Category {
  if (NATIONAL_OVERRIDES.test(text.split('\n')[0])) return 'national';
  let best: { cat: Category; hits: number } | null = null;
  for (const [cat, re] of RULES) {
    const global = new RegExp(re.source, re.flags.includes('g') ? re.flags : re.flags + 'g');
    const hits = (text.match(global) ?? []).length;
    if (hits > 0 && (!best || hits > best.hits)) best = { cat, hits };
  }
  return best?.cat ?? hint ?? 'national';
}

/** Which exams usually ask about a category. Refined later by the AI step. */
const BASE: Record<Category, ExamTag[]> = {
  national: ['upsc', 'ssc', 'statepsc'],
  international: ['upsc', 'ssc', 'defence'],
  economy: ['upsc', 'banking', 'ssc'],
  scitech: ['upsc', 'ssc', 'railway'],
  environment: ['upsc', 'statepsc'],
  awards: ['ssc', 'banking', 'railway'],
  sports: ['ssc', 'railway', 'banking'],
  schemes: ['upsc', 'ssc', 'banking', 'statepsc'],
  defence: ['defence', 'upsc', 'ssc'],
  books: ['ssc', 'banking', 'railway'],
  days: ['ssc', 'railway', 'banking'],
};

export function examTagsFor(category: Category, text: string): ExamTag[] {
  const tags = new Set(BASE[category]);
  if (/\b(rbi|sebi|nabard|bank|repo|monetary)\b/i.test(text)) tags.add('banking');
  if (/\b(railway|rail|vande bharat|irctc)\b/i.test(text)) tags.add('railway');
  if (/\b(army|navy|air force|missile|exercise)\b/i.test(text)) tags.add('defence');
  return [...tags];
}
