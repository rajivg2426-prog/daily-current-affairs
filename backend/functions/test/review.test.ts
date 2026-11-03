import { describe, expect, it } from 'vitest';
import { planPublish, planReject, ReviewError } from '../src/review';

const NOW = new Date('2026-11-03T09:00:00Z');
const bi = (en: string) => ({ en, hi: `हिंदी ${en}` });

/** An articles/{id} doc as Store.saveDraft writes it. */
const draftDoc = () => ({
  status: 'draft',
  aiGenerated: true,
  clusterId: 'c1',
  headline: bi('Cabinet approves critical minerals mission'),
  summary: bi('Short summary.'),
  keyPoints: { en: ['Point one'], hi: ['बिंदु एक'] },
  body: bi('Body text.'),
  whyImportant: bi('GS-III.'),
  category: 'schemes',
  examTags: ['upsc'],
  relevance: 'prelims',
  syllabus: 'GS-III Economy',
  draftFacts: [bi('Implemented by the Ministry of Mines.')],
  draftMcqs: [
    {
      question: bi('Which ministry implements the mission?'),
      options: { en: ['Mines', 'Coal', 'Steel', 'Power'], hi: ['खान', 'कोयला', 'इस्पात', 'बिजली'] },
      answerIndex: 0,
      explanation: bi('The release names the Ministry of Mines.'),
      difficulty: 2,
    },
  ],
  source: { name: 'PIB', url: 'https://pib.gov.in/x', attribution: 'Source: PIB' },
  publishDate: null,
});

const code = (fn: () => unknown) => {
  try {
    fn();
  } catch (e) {
    if (e instanceof ReviewError) return e.code;
    throw e;
  }
  return 'ok';
};

describe('editor review', () => {
  it('publishes a complete draft in the shape the app reads', () => {
    const plan = planPublish('a1', draftDoc(), undefined, 'uid-1', NOW);
    expect(plan.article.status).toBe('published');
    expect(plan.article.publishDate).toEqual(NOW);
    expect(plan.article.practice).toHaveLength(1);
    expect(plan.article.facts).toEqual([bi('Implemented by the Ministry of Mines.')]);
    expect(plan.remove).toEqual(expect.arrayContaining(['draftMcqs', 'draftFacts']));
    expect(plan.quizKey.answers).toEqual([{ questionId: 'a1-q0', answerIndex: 0 }]);
    expect((plan.article.review as { by: string }).by).toBe('uid-1');
  });

  it('applies editor corrections and records which fields changed', () => {
    const plan = planPublish('a1', draftDoc(), { headline: bi('Better headline'), category: 'economy' }, 'uid-1', NOW);
    expect(plan.article.headline).toEqual(bi('Better headline'));
    expect(plan.article.category).toBe('economy');
    expect((plan.article.review as { editedFields: string[] }).editedFields).toEqual(['category', 'headline']);
  });

  it('refuses edits to pipeline-owned fields', () => {
    expect(code(() => planPublish('a1', draftDoc(), { status: 'published' }, 'u', NOW))).toBe('invalid-argument');
    expect(code(() => planPublish('a1', draftDoc(), { source: { url: 'x' } }, 'u', NOW))).toBe('invalid-argument');
  });

  it('refuses a draft missing Hindi or questions', () => {
    const noHindi = { ...draftDoc(), summary: { en: 'Only English', hi: '' } };
    expect(code(() => planPublish('a1', noHindi, undefined, 'u', NOW))).toBe('failed-precondition');
    const noMcqs = { ...draftDoc(), draftMcqs: [] };
    expect(code(() => planPublish('a1', noMcqs, undefined, 'u', NOW))).toBe('failed-precondition');
  });

  it('refuses a draft with no source link', () => {
    const noSource = { ...draftDoc(), source: { name: 'PIB', url: '' } };
    expect(code(() => planPublish('a1', noSource, undefined, 'u', NOW))).toBe('failed-precondition');
  });

  it('only reviews drafts', () => {
    expect(code(() => planPublish('a1', undefined, undefined, 'u', NOW))).toBe('not-found');
    expect(code(() => planPublish('a1', { ...draftDoc(), status: 'published' }, undefined, 'u', NOW))).toBe('failed-precondition');
    expect(code(() => planReject('a1', { ...draftDoc(), status: 'rejected' }, 'dup', 'u', NOW))).toBe('failed-precondition');
  });

  it('rejects with a reason', () => {
    expect(planReject('a1', draftDoc(), '  Duplicate of yesterday  ', 'u', NOW)).toMatchObject({
      status: 'rejected',
      review: { decision: 'rejected', by: 'u', reason: 'Duplicate of yesterday' },
    });
    expect(code(() => planReject('a1', draftDoc(), '', 'u', NOW))).toBe('invalid-argument');
  });
});
