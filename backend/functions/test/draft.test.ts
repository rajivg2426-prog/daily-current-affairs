import { describe, expect, it, vi } from 'vitest';
import { draftCluster, extractJson, buildUserPrompt, type LlmClient } from '../src/ai/draft';
import { ingest, buildQueue } from '../src/pipeline';
import { fixtureFetcher, fixtureSources } from './helpers';

const NOW = new Date('2026-11-03T07:00:00Z');

const bi = (en: string) => ({ en, hi: `हिंदी ${en}` });
const validDraft = {
  headline: bi('Cabinet approves critical minerals mission'),
  summary: bi('Short summary.'),
  keyPoints: { en: ['Point one'], hi: ['बिंदु एक'] },
  body: bi('Body text.'),
  whyImportant: bi('GS-III; likely Prelims question on the implementing ministry.'),
  category: 'schemes',
  examTags: ['upsc', 'ssc'],
  relevance: 'prelims',
  syllabus: 'GS-III Economy',
  facts: [bi('Implemented by the Ministry of Mines.')],
  mcqs: [
    {
      question: bi('Which ministry implements the mission?'),
      options: { en: ['Mines', 'Coal', 'Steel', 'Power'], hi: ['खान', 'कोयला', 'इस्पात', 'बिजली'] },
      answerIndex: 0,
      explanation: bi('The release names the Ministry of Mines.'),
      difficulty: 2,
    },
  ],
};

async function queue() {
  const { items } = await ingest(fixtureSources(), fixtureFetcher, NOW);
  return { items, clusters: buildQueue(items, NOW) };
}

const llm = (reply: string): LlmClient & { complete: ReturnType<typeof vi.fn> } => ({ complete: vi.fn(async () => reply) });

describe('AI drafting', () => {
  it('accepts a valid bilingual draft', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /critical minerals/i.test(x.title))!;
    const result = await draftCluster(llm('```json\n' + JSON.stringify(validDraft) + '\n```'), c, items);
    expect(result.ok).toBe(true);
  });

  it('sends only official text to the model, never newspaper text', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /critical minerals/i.test(x.title))!;
    const client = llm(JSON.stringify(validDraft));
    await draftCluster(client, c, items);
    const prompt: string = client.complete.mock.calls[0][1];
    expect(prompt).toContain('Ministry of Mines');
    expect(prompt).not.toContain('must never be stored');
    expect(prompt).toContain('name="PIB"');
  });

  it('rejects MCQs without four distinct options', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /critical minerals/i.test(x.title))!;
    const bad = structuredClone(validDraft);
    bad.mcqs[0].options.en = ['Mines', 'Mines', 'Steel', 'Power'];
    const result = await draftCluster(llm(JSON.stringify(bad)), c, items);
    expect(result.ok).toBe(false);
  });

  it('passes through the model saying the sources are too thin', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /critical minerals/i.test(x.title))!;
    const result = await draftCluster(llm('{"insufficient": true, "reason": "Only a headline"}'), c, items);
    expect(result).toEqual({ ok: false, reason: 'Only a headline' });
  });

  it('never calls the model for discovery-only stories', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /T20/.test(x.title))!;
    const client = llm('{}');
    const result = await draftCluster(client, c, items);
    expect(result.ok).toBe(false);
    expect(client.complete).not.toHaveBeenCalled();
  });

  it('extracts JSON from prose or fences', () => {
    expect(extractJson('Here you go: {"a":1} thanks')).toEqual({ a: 1 });
    expect(extractJson('nothing')).toBeNull();
  });

  it('builds a prompt with source tags', async () => {
    const { items, clusters } = await queue();
    const c = clusters.find((x) => /critical minerals/i.test(x.title))!;
    const p = buildUserPrompt(c, items.filter((i) => c.contentItemIds.includes(i.id)));
    expect(p).toMatch(/<source index="1" name="PIB"/);
  });
});
