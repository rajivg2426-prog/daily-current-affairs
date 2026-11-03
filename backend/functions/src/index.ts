import { initializeApp } from 'firebase-admin/app';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import { Store } from './store';
import { runIngest, runDrafts, importPbShabd } from './jobs';
import { anthropicClient } from './ai/draft';
import { ReviewError } from './review';

initializeApp();
setGlobalOptions({ region: 'asia-south1', maxInstances: 2 });

const ANTHROPIC_API_KEY = defineSecret('ANTHROPIC_API_KEY');

/** Every 30 minutes: fetch the sources that are due and rebuild the story queue. */
export const ingestSources = onSchedule(
  { schedule: 'every 30 minutes', timeZone: 'Asia/Kolkata', timeoutSeconds: 300, memory: '512MiB' },
  async () => {
    await runIngest(new Store());
  },
);

/** At :15 and :45: draft the top stories (status "draft", editor must approve). */
export const draftStories = onSchedule(
  { schedule: '15,45 * * * *', timeZone: 'Asia/Kolkata', timeoutSeconds: 540, memory: '512MiB', secrets: [ANTHROPIC_API_KEY] },
  async () => {
    await runDrafts(new Store(), anthropicClient(ANTHROPIC_API_KEY.value()));
  },
);

function requireEditor(auth: { uid: string; token: Record<string, unknown> } | undefined): string {
  const role = auth?.token?.role;
  if (!auth || (role !== 'super' && role !== 'editor')) throw new HttpsError('permission-denied', 'Editors only');
  return auth.uid;
}

function asHttpsError(err: unknown): HttpsError {
  if (err instanceof ReviewError) return new HttpsError(err.code, err.message);
  return new HttpsError('internal', String((err as Error)?.message ?? err));
}

function articleId(data: unknown): string {
  const id = (data as { id?: unknown } | null)?.id;
  if (typeof id !== 'string' || !/^[A-Za-z0-9_-]{1,64}$/.test(id)) throw new HttpsError('invalid-argument', 'Pass the article id as { id }');
  return id;
}

/** Admin panel: "Fetch now" button. */
export const ingestNow = onCall({ timeoutSeconds: 300 }, async (req) => {
  requireEditor(req.auth);
  return runIngest(new Store(), new Date(), true);
});

/** Admin panel: upload stories downloaded from PB-SHABD (JSON array). */
export const importPbShabdStories = onCall({ timeoutSeconds: 120 }, async (req) => {
  requireEditor(req.auth);
  try {
    return await importPbShabd(new Store(), req.data);
  } catch (err) {
    throw new HttpsError('invalid-argument', String((err as Error).message ?? err));
  }
});

/**
 * Admin panel: approve a draft. Input { id, edits? } where edits may correct any
 * of headline, summary, keyPoints, body, whyImportant, category, examTags,
 * relevance, syllabus, facts, mcqs. The app shows it from then on.
 */
export const publishArticle = onCall(async (req) => {
  const editor = requireEditor(req.auth);
  const id = articleId(req.data);
  try {
    return await new Store().publishArticle(id, (req.data as { edits?: unknown }).edits, editor);
  } catch (err) {
    throw asHttpsError(err);
  }
});

/** Admin panel: drop a draft. Input { id, reason }. */
export const rejectArticle = onCall(async (req) => {
  const editor = requireEditor(req.auth);
  const id = articleId(req.data);
  try {
    return await new Store().rejectArticle(id, (req.data as { reason?: unknown }).reason, editor);
  } catch (err) {
    throw asHttpsError(err);
  }
});
