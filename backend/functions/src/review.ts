import type { z } from 'zod';
import { Draft } from './ai/schema';

/**
 * Editor review: the step between an AI "draft" and a "published" article.
 *
 *   draft ──publish──▶ published   (app shows it)
 *     └────reject───▶ rejected     (kept for the audit trail, never shown)
 *
 * These are pure functions so the rules can be tested without Firestore.
 * The Store applies them inside a transaction.
 */

/** Fields an editor may correct while publishing. Everything else is fixed by the pipeline. */
export const EDITABLE_FIELDS = [
  'headline', 'summary', 'keyPoints', 'body', 'whyImportant',
  'category', 'examTags', 'relevance', 'syllabus', 'facts', 'mcqs',
] as const;

export const ReviewEdits = Draft.pick({
  headline: true, summary: true, keyPoints: true, body: true, whyImportant: true,
  category: true, examTags: true, relevance: true, syllabus: true, facts: true, mcqs: true,
}).partial().strict();
export type ReviewEdits = z.infer<typeof ReviewEdits>;

export class ReviewError extends Error {
  constructor(public code: 'not-found' | 'failed-precondition' | 'invalid-argument', message: string) {
    super(message);
  }
}

type Doc = Record<string, unknown>;

/** The draft as an editor would publish it: stored draft fields with the editor's edits on top. */
function draftView(article: Doc, edits: ReviewEdits): Doc {
  return {
    headline: article.headline,
    summary: article.summary,
    keyPoints: article.keyPoints,
    body: article.body,
    whyImportant: article.whyImportant,
    category: article.category,
    examTags: article.examTags,
    relevance: article.relevance,
    syllabus: article.syllabus,
    facts: article.facts ?? article.draftFacts ?? [],
    mcqs: article.practice ?? article.draftMcqs ?? [],
    ...edits,
  };
}

function assertDraft(article: Doc | undefined, id: string): asserts article is Doc {
  if (!article) throw new ReviewError('not-found', `Article ${id} not found`);
  if (article.status !== 'draft') {
    throw new ReviewError('failed-precondition', `Article ${id} is "${String(article.status)}", only drafts can be reviewed`);
  }
}

export interface PublishPlan {
  /** Merged into articles/{id}. */
  article: Doc;
  /** Draft-only fields deleted from articles/{id} on publish. */
  remove: string[];
  /** Written to quizKeys/{id}: answers kept server-side for future server grading. */
  quizKey: Doc;
}

/**
 * Checks a draft is complete in both languages and builds the published version.
 * Throws ReviewError if the draft can't be published as it stands.
 */
export function planPublish(id: string, article: Doc | undefined, rawEdits: unknown, editor: string, now: Date): PublishPlan {
  assertDraft(article, id);

  const editsResult = ReviewEdits.safeParse(rawEdits ?? {});
  if (!editsResult.success) throw new ReviewError('invalid-argument', `Bad edits: ${editsResult.error.issues.map(fmt).join('; ')}`);
  const edits = editsResult.data;

  const checked = Draft.safeParse(draftView(article, edits));
  if (!checked.success) {
    throw new ReviewError('failed-precondition', `Draft is incomplete: ${checked.error.issues.map(fmt).join('; ')}`);
  }
  const d = checked.data;
  const source = article.source as { url?: string } | undefined;
  if (!source?.url) throw new ReviewError('failed-precondition', 'Draft has no source link; every article must credit its source');

  return {
    article: {
      status: 'published',
      headline: d.headline,
      summary: d.summary,
      keyPoints: d.keyPoints,
      body: d.body,
      whyImportant: d.whyImportant,
      category: d.category,
      examTags: d.examTags,
      relevance: d.relevance,
      syllabus: d.syllabus,
      facts: d.facts,
      // v1 grades quizzes on the device, so the app needs the answers here.
      practice: d.mcqs,
      publishDate: now,
      review: {
        decision: 'published',
        by: editor,
        at: now,
        editedFields: Object.keys(edits).sort(),
      },
    },
    remove: ['draftMcqs', 'draftFacts', 'reviewBy'],
    quizKey: {
      articleId: id,
      answers: d.mcqs.map((q, i) => ({ questionId: `${id}-q${i}`, answerIndex: q.answerIndex })),
      createdAt: now,
    },
  };
}

/** Rejects a draft. A reason is required so the team can see why stories were dropped. */
export function planReject(id: string, article: Doc | undefined, reason: unknown, editor: string, now: Date): Doc {
  assertDraft(article, id);
  const text = typeof reason === 'string' ? reason.trim() : '';
  if (text.length < 3) throw new ReviewError('invalid-argument', 'Give a short reason for rejecting the draft');
  return {
    status: 'rejected',
    review: { decision: 'rejected', by: editor, at: now, reason: text.slice(0, 500) },
  };
}

function fmt(issue: { path: PropertyKey[]; message: string }): string {
  return issue.path.length ? `${issue.path.map(String).join('.')}: ${issue.message}` : issue.message;
}
