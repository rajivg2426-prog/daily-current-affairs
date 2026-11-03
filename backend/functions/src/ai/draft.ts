import Anthropic from '@anthropic-ai/sdk';
import { DraftOrInsufficient, type Draft } from './schema';
import type { SourceItem, StoryCluster } from '../core/types';

/**
 * Turns a story cluster into a bilingual exam-ready draft.
 *
 * Hard rule: the model sees ONLY text from content sources (PIB, RBI, PRS,
 * PB-SHABD). Discovery items contribute nothing but the fact that other
 * outlets are covering the story. Every draft is saved with status "draft"
 * and needs an editor's approval before it is published.
 */

export const SYSTEM_PROMPT = `You write study material for Indian competitive-exam aspirants (UPSC, SSC, Banking, Railway, Defence, State PSC).

You are given one or more official source documents about a single news story. Write an original, accurate study note in English and Hindi.

Rules:
- Use ONLY facts stated in the source documents. Never add numbers, names, dates or claims that are not in them. If the sources do not contain enough to write a useful note, return {"insufficient": true, "reason": "..."}.
- Write in your own words. Do not copy sentences from the sources.
- "whyImportant" explains which exam and syllabus area this maps to and what is likely to be asked.
- MCQs: exactly 4 distinct options each, one correct answer, answerable from the sources alone, with a one-to-two sentence explanation.
- Hindi must be natural standard Hindi (Devanagari), using official Hindi names of schemes and bodies where the sources give them.
- Output a single JSON object and nothing else.

JSON shape:
{
  "headline": {"en": "...", "hi": "..."},
  "summary": {"en": "<= 60 words", "hi": "..."},
  "keyPoints": {"en": ["3-5 points"], "hi": ["..."]},
  "body": {"en": "150-300 words", "hi": "..."},
  "whyImportant": {"en": "...", "hi": "..."},
  "category": "national|international|economy|scitech|environment|awards|sports|schemes|defence|books|days",
  "examTags": ["upsc","ssc","banking","railway","defence","statepsc"],
  "relevance": "prelims|mains|both",
  "syllabus": "e.g. GS-III Economy",
  "facts": [{"en": "one-line fact", "hi": "..."}],
  "mcqs": [{"question": {"en": "...", "hi": "..."}, "options": {"en": ["A","B","C","D"], "hi": ["..."]}, "answerIndex": 0, "explanation": {"en": "...", "hi": "..."}, "difficulty": 1}]
}`;

export interface LlmClient {
  complete(system: string, user: string): Promise<string>;
}

export function anthropicClient(apiKey: string, model = process.env.DRAFT_MODEL ?? 'claude-haiku-5-5'): LlmClient {
  const client = new Anthropic({ apiKey });
  return {
    async complete(system, user) {
      const msg = await client.messages.create({
        model,
        max_tokens: 4000,
        // The system prompt is identical on every call, so cache it.
        system: [{ type: 'text', text: system, cache_control: { type: 'ephemeral' } }],
        messages: [{ role: 'user', content: user }],
      });
      return msg.content
        .filter((b): b is Anthropic.TextBlock => b.type === 'text')
        .map((b) => b.text)
        .join('');
    },
  };
}

export function buildUserPrompt(cluster: StoryCluster, contentItems: SourceItem[]): string {
  const docs = contentItems
    .map((it, i) => `<source index="${i + 1}" name="${it.sourceName}" url="${it.url}" date="${it.publishedAt}">\n${it.title}\n\n${(it.text ?? '').slice(0, 12_000)}\n</source>`)
    .join('\n\n');
  return `Story: ${cluster.title}\nOther outlets covering it: ${cluster.discoveryOutlets}\n\n${docs}`;
}

export type DraftResult =
  | { ok: true; draft: Draft }
  | { ok: false; reason: string };

export async function draftCluster(llm: LlmClient, cluster: StoryCluster, items: SourceItem[]): Promise<DraftResult> {
  const content = items.filter((i) => i.use === 'content' && cluster.contentItemIds.includes(i.id) && (i.text?.length ?? 0) > 0);
  if (content.length === 0) return { ok: false, reason: 'No content-source text to draft from' };

  const raw = await llm.complete(SYSTEM_PROMPT, buildUserPrompt(cluster, content));
  const parsed = DraftOrInsufficient.safeParse(extractJson(raw));
  if (!parsed.success) return { ok: false, reason: `Draft failed validation: ${parsed.error.issues.slice(0, 3).map((i) => i.message).join('; ')}` };
  if ('insufficient' in parsed.data && parsed.data.insufficient === true) return { ok: false, reason: parsed.data.reason };
  return { ok: true, draft: parsed.data as Draft };
}

/** Accepts bare JSON or JSON inside a ```json fence. */
export function extractJson(text: string): unknown {
  const fenced = /```(?:json)?\s*([\s\S]*?)```/.exec(text);
  const candidate = (fenced ? fenced[1] : text).trim();
  const start = candidate.indexOf('{');
  const end = candidate.lastIndexOf('}');
  if (start < 0 || end < start) return null;
  try {
    return JSON.parse(candidate.slice(start, end + 1));
  } catch {
    return null;
  }
}
