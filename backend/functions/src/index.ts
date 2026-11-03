import { initializeApp } from 'firebase-admin/app';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';
import { defineSecret } from 'firebase-functions/params';
import { Store } from './store';
import { runIngest, runDrafts, importPbShabd } from './jobs';
import { anthropicClient } from './ai/draft';

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

function requireEditor(auth: { token: Record<string, unknown> } | undefined) {
  const role = auth?.token?.role;
  if (role !== 'super' && role !== 'editor') throw new HttpsError('permission-denied', 'Editors only');
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
